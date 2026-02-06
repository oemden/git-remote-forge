#!/bin/bash

# gitremote (git-remote-forge)
# A tool to create and setup git projects locally and push it remotely via ssh ( on gitlab.com for Now )
# Creates three default branches:
#   - main: primary branch
#   - production: for production releases
#   - develop: active development branch

version="0.10.1"

# Prerequisites:
# - Git configured locally (user.name and user.email)
# - SSH key setup and configured for GitLab access
# - GitLab namespace (username or group name)

# Call the script from anywhere
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(pwd)"

# Constants
GITLAB_BASE_URL="git@gitlab.com:"

# Default values
DIRECTORY_NAME=""
LOCAL_TARGET=""
TECHNOLOGIES=""
AUTO_DETECT_TECH=false
DIRECTORY_PATH=""
IS_EXISTING_REPO=false
FORCE_MODE=false
DEFER_GIT_INIT_AFTER_APPROVAL=true  # Defer git init until after user confirmation (set to false if .git already exists)
TARGET=""
PROVIDER="gitlab"
CHECKOUT_BRANCH="develop"
SELF_HOSTED_URL=""
REMOTE_NAME="origin"
NEW_REMOTE_NAME=""
OVERRIDE_REMOTE=false
# Flag: Replace remote URL when -R flag is used
# When true, allows replacing existing remote URL with new one (with user confirmation)
REPLACE_REMOTE=false
# Flag: Create .gitignore file when -i flag is used
# When true, creates .gitignore with default patterns and repository marker file
CREATE_GITIGNORE=false
# Flag: Override existing .git directory when -O flag is used
# When true, removes existing .git and reinitializes repository (destructive operation)
OVERRIDE_GIT=false
# Flag: Remote exists check is pending (deferred until after provider setup)
# When true, need to verify remote URL matches after setup_provider sets REMOTE_URL
REMOTE_EXISTS_CHECK_PENDING=false
 # Flag: Remote deletion mode for online repositories (-k / -K, GitLab only for now)
# When set to "safe" or "force", script performs remote delete-only flow instead of creation/push
DELETE_ONLINE_REPO_MODE=""
# Last GitLab API call status and body (used by minimal helpers for -k / -K)
GITLAB_API_LAST_STATUS=""
GITLAB_API_LAST_BODY=""
GITLAB_LAST_PROJECT_ID=""
GITLAB_LAST_PROJECT_PATH_ENCODED=""
HARD_DELETE_FORCE_MODE=false
GET_PROJECT_ID_ONLY=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "git-remote-forge - Repository Setup Script v${version}"
    echo "-----------------------------"
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d    Local Directory/Project name (required for new repo)"
    echo "  -n    Namespace - for Gitlab /username - for GitHub (target on provider)"
    echo "  -r    Set custom remote name (default: origin)"
    echo "  -R    Replace remote URL (prompts for confirmation if URL differs)"
    echo "  -i    Create basic .gitignore file (default: .*env, !.env.example, .repo_initiated_by_gitremoteforge)"
    # TODO: Future features (commented out for now)
    # echo "  -S    Self-hosted URL (optional, for self-hosted providers)"
    echo "  -t    Auto-detect technologies (existing directory mode)"
    echo "  -T    Technologies (user-provided, comma-separated, optional)"
    echo "  -b    Branch to checkout after creation (default: develop)"
    echo "  -p    Path to local directory (optional, for existing directory mode)"
    echo "  -P    Provider (gitlab|github|bitbucket|gitea, default: gitlab)"
    echo "  -f    Force mode (skip dry-run and confirmation)"
    echo "  -F    Force remote delete confirmations for -k / -K (non-interactive hard delete)"
    echo "  -O    Override existing .git directory (removes and reinitializes) - DESTRUCTIVE - Requires double confirmations even with -f flag"
    echo "  -W    Resolve and print GitLab project id from current git remote"
    echo "  -h    Display this help message"
    echo
    echo "Modes:"
    echo "  New Repository (inside current directory):       gitremote -d myproject -n myuser -T 'python,js'"
    echo "  Existing Directory (using current directory):    gitremote -n myuser -t (auto-detect) or -T 'tech'"
    echo "  Existing Directory (specific directory):         gitremote -p /path/to/dir -n myuser -t"
    echo
    echo "Default branches created: main, production, develop"
    echo "Default checkout: develop (unless -b specified)"
    echo "-----------------------------"
    exit 1
}

# Parse command line arguments
# Handles all command-line flags and sets corresponding variables
parse_arguments() {
    # Current flags: d, n, t, T, B, S, p, r, R, i, O, f, h, P, k, K, W, F
    while getopts "d:n:t:T:b:S:p:r:R:iOfFhkKWP:" opt; do
        case ${opt} in
            d )
                # Directory/Project name (creates new directory)
                DIRECTORY_NAME=$OPTARG
                ;;
            n )
                # Namespace/username (target on provider, e.g., GitLab username)
                TARGET=$OPTARG
                ;;
            t )
                # Auto-detect technologies from existing files
                AUTO_DETECT_TECH=true
                ;;
            T )
                # User-provided technologies (comma-separated)
                TECHNOLOGIES=$OPTARG
                ;;
            R )
                # Replace remote URL (force replace mode)
                # Example: -R origin (replaces origin URL, prompts if URL differs)
                REMOTE_NAME=$OPTARG
                REPLACE_REMOTE=true
                ;;
            b )
                # Branch to checkout after creation (default: develop)
                CHECKOUT_BRANCH=$OPTARG
                ;;
            S )
                # Self-hosted URL (for self-hosted GitLab instances)
                SELF_HOSTED_URL=$OPTARG
                ;;
            p )
                # Path to existing directory (absolute or relative)
                DIRECTORY_PATH=$OPTARG
                ;;
            r )
                # Set custom remote name (default: origin)
                # Example: -r gitlab (uses "gitlab" instead of "origin")
                REMOTE_NAME=$OPTARG
                ;;
            i )
                # -i flag: Create basic .gitignore file
                # Sets flag to create .gitignore with default patterns:
                #   - .*env (all environment files)
                #   - !.env.example (exception: keep .env.example)
                #   - .repo_initiated_by_gitremoteforge (repository marker)
                CREATE_GITIGNORE=true
                ;;
            O )
                # -O flag: Override existing .git directory
                # Sets flag to remove and reinitialize .git when conflicts are detected
                # WARNING: This is a destructive operation that removes all branches and remotes
                # ALWAYS requires two-step confirmation (even with -f flag) for safety
                OVERRIDE_GIT=true
                ;;
            P )
                # -P flag: Provider selection (gitlab|github|bitbucket|gitea)
                # Sets the git provider to use for remote repository setup
                # Default: gitlab (set at script initialization)
                # Validates provider value and exits with error if invalid
                local provider_value=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]')
                case "$provider_value" in
                    gitlab|github|bitbucket|gitea)
                        PROVIDER="$provider_value"
                        ;;
                    *)
                        echo "Error: Invalid provider '$OPTARG'. Supported providers: gitlab, github, bitbucket, gitea"
                        usage
                        exit 1
                        ;;
                esac
                ;;
            k )
                # -k flag: Delete online repository in safe mode (requires confirmation)
                # GitLab-only in current version; performs remote delete-only operation
                if [ "$DELETE_ONLINE_REPO_MODE" = "force" ]; then
                    echo "Error: Options -k and -K cannot be used together"
                    usage
                fi
                DELETE_ONLINE_REPO_MODE="safe"
                ;;
            K )
                # -K flag: Force delete online repository (destructive, two-step confirmation)
                # GitLab-only in current version; performs remote delete-only operation
                if [ "$DELETE_ONLINE_REPO_MODE" = "safe" ]; then
                    echo "Error: Options -k and -K cannot be used together"
                    usage
                fi
                DELETE_ONLINE_REPO_MODE="force"
                ;;
            W )
                # -W flag: Debug helper - resolve and print GitLab project id and path only
                # Does not create, delete, or modify anything on the remote.
                GET_PROJECT_ID_ONLY=true
                ;;
            : )
                # Missing argument for option
                echo "Error: Option -$OPTARG requires an argument"
                usage
                ;;
            f )
                # Force mode: skip preview and confirmation
                FORCE_MODE=true
                ;;
            F )
                # -F flag: Force remote delete confirmations for -k / -K (non-interactive)
                HARD_DELETE_FORCE_MODE=true
                ;;
            h )
                # Display help message
                usage
                ;;
            \? )
                # Invalid option
                usage
                ;;
        esac
    done
}

# Function to normalize paths (remove ./., resolve . to absolute, etc.)
# This ensures clean path display and correct directory resolution
# Input: path string (relative, absolute, or "." for current directory)
# Output: normalized absolute path
normalize_path() {
    local path="$1"
    
    # Handle empty or just "." - default to current working directory
    if [ -z "$path" ] || [ "$path" = "." ] || [ "$path" = "./" ]; then
        echo "$BASE_DIR"
        return
    fi
    
    # Remove leading ./ if present (e.g., "./folder" -> "folder")
    path="${path#./}"
    
    # If absolute path, use as-is (but clean up redundant components)
    if [[ "$path" = /* ]]; then
        # Use realpath if available for proper resolution, otherwise manual cleanup
        # Note: macOS realpath doesn't support -m flag, so we check if path exists first
        if command -v realpath >/dev/null 2>&1; then
            # Check if path exists - if not, use manual resolution (macOS realpath doesn't support -m)
            if [ -e "$path" ] || [ -e "$(dirname "$path")" ]; then
                # Path or parent exists, use realpath normally
                local result=$(realpath "$path" 2>/dev/null)
                if [ -n "$result" ]; then
                    echo "$result"
                else
                    # realpath failed, use manual normalization
                    echo "$path" | sed 's|/\./|/|g' | sed 's|/\.$||' | sed 's|//|/|g'
                fi
            else
                # Path doesn't exist yet (new directory), use manual normalization
                # macOS realpath requires path to exist, so we manually resolve
                echo "$path" | sed 's|/\./|/|g' | sed 's|/\.$||' | sed 's|//|/|g'
            fi
        else
            # Manual normalization: remove redundant slashes and ./
            echo "$path" | sed 's|/\./|/|g' | sed 's|/\.$||' | sed 's|//|/|g'
        fi
    else
        # Relative path: resolve relative to BASE_DIR (current working directory)
        local resolved="${BASE_DIR}/${path}"
        # Remove redundant slashes and ./
        resolved=$(echo "$resolved" | sed 's|/\./|/|g' | sed 's|/\.$||' | sed 's|//|/|g')
        
        # Use realpath if available for proper resolution
        # Note: macOS realpath doesn't support -m flag, so we check if path exists first
        if command -v realpath >/dev/null 2>&1; then
            # Check if path exists - if not, use manual resolution (macOS realpath doesn't support -m)
            if [ -e "$resolved" ] || [ -e "$(dirname "$resolved")" ]; then
                # Path or parent exists, use realpath normally
                local result=$(realpath "$resolved" 2>/dev/null)
                if [ -n "$result" ]; then
                    echo "$result"
                else
                    echo "$resolved"
                fi
            else
                # Path doesn't exist yet (new directory), use manual resolution
                echo "$resolved"
            fi
        else
            echo "$resolved"
        fi
    fi
}

# Helper: Map file extension to technology (bash 3.x compatible)
get_tech_from_extension() {
    local ext="$1"
    case "$ext" in
        .py) echo "Python" ;;
        .js) echo "JavaScript" ;;
        .ts) echo "TypeScript" ;;
        .html) echo "HTML" ;;
        .css) echo "CSS" ;;
        .java) echo "Java" ;;
        .cpp) echo "C++" ;;
        .c) echo "C" ;;
        .go) echo "Go" ;;
        .rb) echo "Ruby" ;;
        .php) echo "PHP" ;;
        .rs) echo "Rust" ;;
        .swift) echo "Swift" ;;
        .kt) echo "Kotlin" ;;
        .scala) echo "Scala" ;;
        .sh) echo "Shell" ;;
        .yml|.yaml) echo "YAML" ;;
        .json) echo "JSON" ;;
        .xml) echo "XML" ;;
        .md) echo "Markdown" ;;
        .sql) echo "SQL" ;;
        .dockerfile) echo "Docker" ;;
        .tf) echo "Terraform" ;;
        .gradle) echo "Gradle" ;;
        .maven) echo "Maven" ;;
    esac
}

# TODO: Function - Init existing directory with file detection
# Currently unused; will be called during existing repo initialization
detect_technologies() {
    local dir="$1"
    local full_path=$(realpath "$dir")
    local tech_list=""
    local extensions=()
    
    # Look for special files
    if [ -f "$full_path/Dockerfile" ]; then
        extensions+=("Docker")
    fi
    if [ -f "$full_path/package.json" ]; then
        extensions+=("Node.js")
    fi
    if [ -f "$full_path/requirements.txt" ]; then
        extensions+=("Python")
    fi
    if [ -f "$full_path/pom.xml" ]; then
        extensions+=("Java/Maven")
    fi
    if [ -f "$full_path/build.gradle" ]; then
        extensions+=("Java/Gradle")
    fi
    
    # Find all file extensions in the directory
    find "$full_path" -type f -print0 | while IFS= read -r -d '' file
    do
        ext="${file##*.}"
        if [[ -n "$ext" && "$ext" != "$file" ]]; then
            ext=".$(echo "$ext" | tr '[:upper:]' '[:lower:]')"  # Convert to lowercase (bash 3.x compatible)
            tech=$(get_tech_from_extension "$ext")
            if [[ -n "$tech" ]]; then
                extensions+=("$tech")
            fi
        fi
    done
    
    # Remove duplicates and create comma-separated list
    tech_list=$(echo "${extensions[@]}" | tr ' ' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')
    
    echo "$tech_list"
}

# Function to get GitLab namespace
get_gitlab_namespace() {
    read -p "Enter your GitLab namespace: " gitlab_namespace
    while [[ -z "$gitlab_namespace" ]]; do
        echo "GitLab namespace cannot be empty!"
        read -p "Enter your GitLab namespace: " gitlab_namespace
    done
    echo "$gitlab_namespace"
}

# Function to get technologies interactively
get_technologies() {
    read -p "Enter the main technologies used (comma-separated) [optional]: " technologies
    echo "$technologies"
}

# Function to get git user information
get_git_user_info() {
    local name=$(git config --get user.name)
    local email=$(git config --get user.email)
    
    if [[ -z "$name" ]] || [[ -z "$email" ]]; then
        echo "Error: Git user information not found. Please configure git first:"
        echo "git config --global user.name \"Your Name\""
        echo "git config --global user.email \"your.email@example.com\""
        exit 1
    fi
    
    echo "$name <$email>"
}

# Provider Adapter: GitLab Setup
handle_gitlab_setup() {
    local target=$1
    local gitlab_domain=${2:-"gitlab.com"}  # Default gitlab.com, accept custom domain
    
    # Validate target
    if [[ -z "$target" ]]; then
        read -p "Enter your GitLab namespace: " target
        while [[ -z "$target" ]]; do
            echo "GitLab namespace cannot be empty!"
            read -p "Enter your GitLab namespace: " target
        done
    fi
    
    # Export StandardConfig variables
    PROVIDER_NAME="gitlab"
    TARGET="$target"
    GITLAB_DOMAIN="$gitlab_domain"
    REMOTE_URL="git@${GITLAB_DOMAIN}:${TARGET}/${REPO_NAME}.git"
    REMOTE_PROTOCOL="ssh"
    API_ENDPOINT="https://${GITLAB_DOMAIN}/api/v4"
    
    AUTH_VALID=true
    TARGET_EXISTS=true
    REPO_EXISTS=false
}

handle_github_setup() {
    local target=$1
    local github_domain=${2:-"github.com"}  # or whatever default
    
    echo
    # TODO: implement handle_github_setup
}

handle_bitbucket_setup() {
    local target=$1
    local bitbucket_domain=${2:-"bitbucket.org"}  # or whatever default
    
    echo
    # TODO: implement handle_bitbucket_setup
}

handle_gitea_setup() {
    local target=$1
    local gitea_domain=${2:-"gitea.io"}  # or whatever default
    
    echo
    # TODO: implement handle_gitea_setup
}

# Minimal GitLab API helper for remote repository management (-k / -K)
# Uses API_ENDPOINT from handle_gitlab_setup and expects a valid access token
# in either GITREMOTE_FORGE_GITLAB_TOKEN or GITLAB_ACCESS_TOKEN.
# This helper intentionally keeps token handling simple; robust detection/UX
# will be implemented in a future version.
gitlab_api_request() {
    local method="$1"
    local endpoint="$2"
    local url="${API_ENDPOINT}${endpoint}"

    # Prefer project-specific token variable, fall back to generic GitLab token if set.
    local token="${GITREMOTE_FORGE_GITLAB_TOKEN:-$GITLAB_ACCESS_TOKEN}"

    # Reset last-call state
    GITLAB_API_LAST_STATUS=""
    GITLAB_API_LAST_BODY=""

    # Perform request and capture both body and HTTP status code.
    # curl is expected to be available in the environment.
    local response http_code body
    response=$(curl -sS -X "$method" -H "PRIVATE-TOKEN: ${token}" "$url" -w " HTTP_STATUS:%{http_code}" 2>/dev/null || echo " HTTP_STATUS:000")
    http_code="${response##*HTTP_STATUS:}"
    body="${response% HTTP_STATUS:*}"

    GITLAB_API_LAST_STATUS="$http_code"
    GITLAB_API_LAST_BODY="$body"

    # Consider any 2xx status as success; caller can inspect status/body if needed.
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        return 0
    fi

    return 1
}

find_project_id_gitlab() {
    cd "$BASE_DIR" 2>/dev/null || true
    local origin_url
    origin_url=$(git remote get-url "$REMOTE_NAME" 2>/dev/null || git remote get-url origin 2>/dev/null)

    local namespace repo_name path_part tmp
    case "$origin_url" in
        git@*:* )
            path_part="${origin_url#*:}"
            ;;
        http://*|https://*|ssh://* )
            tmp="${origin_url#*://}"
            path_part="${tmp#*/}"
            ;;
        * )
            return 1
            ;;
    esac

    path_part="${path_part%.git}"
    repo_name="${path_part##*/}"
    namespace="${path_part%/*}"

    local project_path_encoded="${namespace}%2F${repo_name}"

    local project_id
    project_id=$(curl -s --header "PRIVATE-TOKEN: ${GITREMOTE_FORGE_GITLAB_TOKEN}" "https://gitlab.com/api/v4/projects/${project_path_encoded}" | jq -r '.id')

    GITLAB_LAST_PROJECT_ID="$project_id"
    echo "$project_id"
    return 0
}

# Function to create .gitignore file and repository marker
# Called when -i flag is used to automatically set up standard gitignore patterns
# Parameters:
#   $1: target_path - Directory where .gitignore should be created
create_gitignore() {
    local target_path="$1"
    
    cd "$target_path"
    
    # Step 1: Create repository marker file
    # This file tracks that the repository was initialized by git-remote-forge
    # Contains version information for tracking purposes
    if [ ! -f ".repo_initiated_by_gitremoteforge" ]; then
        echo "gitremoteforge version = ${version}" > .repo_initiated_by_gitremoteforge
        echo -e "${GREEN}✓ Created repository marker file${NC}"
    fi
    
    # Step 2: Create .gitignore file (only if it doesn't exist)
    if [ ! -f ".gitignore" ]; then
        # .gitignore doesn't exist - create new file with default patterns
        # Default patterns include:
        #   - Repository marker (to ignore the marker file itself)
        #   - All .env files (.*env matches .env, .env.local, .env.production, etc.)
        #   - Exception for .env.example (keep it as a template)
        cat > .gitignore << EOL
# Repository marker
.repo_initiated_by_gitremoteforge

# Environment files
.*env
!.env.example
EOL
        echo -e "${GREEN}✓ Created .gitignore file${NC}"
        return 0  # Success - created new file
    else
        # .gitignore already exists - inform user and keep existing file
        # We don't override existing .gitignore to avoid unintended consequences
        echo -e "${YELLOW}⚠ .gitignore already exists${NC}"
        echo -e "${BLUE}Keeping existing .gitignore file (no override)${NC}"
        return 1  # Indicate file already exists
    fi
}

# Function to preview operations
preview_operations() {
    local dir_name="$1"
    local contributor="$2"
    local technologies="$3"
    local checkout_branch="$4"

    echo -e "\n${BLUE}Preview of Operations:${NC}"
    echo -e "${YELLOW}====================${NC}"
    
    # Directory creation
    echo -e "\n${GREEN}1. Local Repository Setup:${NC}"
    echo -e "   • Create directory: ${BLUE}$dir_name${NC}"
    # Show override warning if -O flag is used
    # This alerts user that existing .git will be removed (destructive operation)
    if [ "$OVERRIDE_GIT" = true ]; then
        echo -e "   • ${YELLOW}⚠ Override existing .git directory (will remove and reinitialize)${NC}"
    else
        echo -e "   • Initialize git repository"
    fi
    echo -e "   • Create and commit README.md with:"
    echo -e "     - Project name: ${BLUE}$dir_name${NC}"
    echo -e "     - Contributor: ${BLUE}$contributor${NC}"
    [[ ! -z "$technologies" ]] && echo -e "     - Technologies: ${BLUE}$technologies${NC}"
    # Show .gitignore creation in preview if -i flag is used
    # This helps user understand what will be created before confirmation
    if [ "$CREATE_GITIGNORE" = true ]; then
        echo -e "   • Create .gitignore file with default patterns"
        echo -e "   • Create .repo_initiated_by_gitremoteforge marker file"
    fi

    # Remote operations
    echo -e "\n${GREEN}2. Remote Repository Setup:${NC}"
    # TODO: Future feature - Multi-remote support
    # if [ -n "$NEW_REMOTE_NAME" ]; then
    #     echo -e "   • Add new remote '${NEW_REMOTE_NAME}':"
    # else
    echo -e "   • Configure remote '${REMOTE_NAME}':"
    # fi
    echo -e "     ${BLUE}${REMOTE_URL}${NC}"

    # Branch operations
    echo -e "\n${GREEN}3. Branch Operations:${NC}"
    echo -e "   • Initial branch: ${BLUE}main${NC}"
    echo -e "   • Create branch: ${BLUE}production${NC}"
    echo -e "   • Create branch: ${BLUE}develop${NC}"
    [[ ! -z "$checkout_branch" ]] && echo -e "   • Checkout to: ${BLUE}$checkout_branch${NC}"

    # Push operations
    echo -e "\n${GREEN}4. Push Operations:${NC}"
    echo -e "   • Push branch: ${BLUE}main${NC}"
    echo -e "   • Push branch: ${BLUE}production${NC}"
    echo -e "   • Push branch: ${BLUE}develop${NC}"

    if [ -z "$TECHNOLOGIES" ]; then
        echo -e "\n${GREEN}5. Post-Setup Operations:${NC}"
        echo -e "   • Detect technologies in repository"
        echo -e "   • Update README.md if technologies found"
        echo -e "   • Push updates to all branches"
    fi

    # Ask for confirmation
    if [ "$FORCE_MODE" = false ]; then
        echo -e "\n${YELLOW}Do you want to proceed with these operations? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Operation cancelled by user${NC}"
            exit 0
        fi
    fi
}

# Function to create local repository structure (README, initial commit)
create_local_repo() {
    local target_path="$1"
    local contributor="$2"
    local technologies="$3"
    
    cd "$target_path"
    
    # Create README.md with dynamic content
    cat > README.md << EOL
# $DIRECTORY_NAME

## Project Overview
This repository contains the source code for $DIRECTORY_NAME.

## Main Contributor
$contributor
EOL

    if [ ! -z "$technologies" ]; then
        cat >> README.md << EOL

## Technologies
$technologies
EOL
    fi

    # Create .gitignore and repository marker if -i flag is set
    # This is done before the initial commit so they can be included in the first commit
    if [ "$CREATE_GITIGNORE" = true ]; then
        create_gitignore "$target_path"
    fi

    # Initial commit on main branch
    # Add README.md first (always created)
    git add README.md
    # If .gitignore was created, add it and the marker file to the commit
    # Use 2>/dev/null || true to handle case where files might not exist (defensive coding)
    if [ "$CREATE_GITIGNORE" = true ]; then
        git add .gitignore .repo_initiated_by_gitremoteforge 2>/dev/null || true
    fi
    git commit -m "Initial commit: Add README.md"
}

# Function to push to remote (provider-agnostic)
# Adds remote if it doesn't exist, then pushes all branches
# Uses REMOTE_NAME (from -r flag or default "origin")
push_to_remote() {
    local checkout_branch="$1"
    local push_success=true
    
    local remote_url="$REMOTE_URL"
    local target_remote="$REMOTE_NAME"
    
    # TODO: Future feature - Multi-remote support
    # Handle -R flag: Add new remote (keep existing)
    # This would allow adding a secondary remote for a different provider
    # if [ -n "$NEW_REMOTE_NAME" ]; then
    #     target_remote="$NEW_REMOTE_NAME"
    #     if ! git remote | grep -q "^${NEW_REMOTE_NAME}$"; then
    #         git remote add "$NEW_REMOTE_NAME" "$remote_url"
    #         echo -e "${GREEN}✓ Added new remote: ${BLUE}${NEW_REMOTE_NAME}${NC}"
    #     else
    #         git remote set-url "$NEW_REMOTE_NAME" "$remote_url"
    #         echo -e "${BLUE}Updated remote: ${YELLOW}${NEW_REMOTE_NAME}${NC}"
    #     fi
    # # Handle -O flag: Override existing remote
    # elif [ "$OVERRIDE_REMOTE" = true ]; then
    #     if git remote | grep -q "^${target_remote}$"; then
    #         git remote set-url "$target_remote" "$remote_url"
    #         echo -e "${BLUE}Overrode remote: ${YELLOW}${target_remote}${NC}"
    #     else
    #         git remote add "$target_remote" "$remote_url"
    #         echo -e "${GREEN}✓ Added remote: ${BLUE}${target_remote}${NC}"
    #     fi
    
    # Check for duplicate URLs before adding remote
    # This prevents adding multiple remotes with the same URL
    local remote_with_same_url=$(check_remote_url_exists "$remote_url" "$LOCAL_TARGET")
    if [ -n "$remote_with_same_url" ] && [ "$remote_with_same_url" != "$target_remote" ]; then
        # URL already exists with a different remote name
        if [ "$REPLACE_REMOTE" = true ]; then
            # -R flag: Rename existing remote to new name (same URL)
            echo -e "${BLUE}Renaming remote '${remote_with_same_url}' to '${target_remote}' (same URL)${NC}"
            git remote rename "$remote_with_same_url" "$target_remote"
            echo -e "${GREEN}✓ Remote renamed successfully${NC}"
        else
            # -r flag: Prevent duplicate, show error
            echo -e "${RED}✗ Cannot add remote '${target_remote}': URL '${remote_url}' already exists as remote '${remote_with_same_url}'${NC}"
            echo -e "${YELLOW}Use -R flag to replace remote name with same URL${NC}"
            exit 1
        fi
    fi
    
    # Check if remote name exists
    if ! git remote | grep -q "^${target_remote}$"; then
        # Remote name doesn't exist - check if other remotes exist to notify user
        local other_remotes=$(git remote | grep -v "^${target_remote}$" | tr '\n' ',' | sed 's/,$//')
        if [ -n "$other_remotes" ]; then
            echo -e "${YELLOW}⚠ Other remotes exist: ${other_remotes}${NC}"
        fi
        # Add new remote
        git remote add "$target_remote" "$remote_url"
        echo -e "${GREEN}✓ Added remote: ${BLUE}${target_remote}${NC} with URL ${BLUE}${remote_url}${NC}"
    else
        # Remote name exists - check if URL matches
        local existing_url=$(get_remote_url "$target_remote" "$LOCAL_TARGET")
        if [ -n "$existing_url" ] && [ "$existing_url" = "$remote_url" ]; then
            # URLs match - use existing remote
            echo -e "${GREEN}✓ Remote '${target_remote}' already exists with matching URL, using existing${NC}"
        else
            # Remote exists but URL differs - this should have been handled in manage_git() or after setup_provider()
            # But add safety check here too
            echo -e "${YELLOW}⚠ Remote '${target_remote}' already exists with different URL${NC}"
            echo -e "${BLUE}Existing: ${existing_url}${NC}"
            echo -e "${BLUE}Requested: ${remote_url}${NC}"
            echo -e "${YELLOW}Using existing remote${NC}"
        fi
    fi
    
    # If existing repo with branches, push as-is
    if [ "$IS_EXISTING_REPO" = true ]; then
        echo -e "${BLUE}Pushing existing branches to remote '${target_remote}'...${NC}"
        if ! git push --all --set-upstream "$target_remote"; then
            echo -e "${RED}✗ Push to remote failed${NC}"
            push_success=false
        else
            echo -e "${GREEN}✓ Pushed successfully${NC}"
        fi
    else
        # New repo: create and push standard branches
        echo -e "${BLUE}Creating and pushing standard branches to '${target_remote}'...${NC}"
        
        if ! git push --set-upstream "$target_remote" main; then
            echo -e "${RED}✗ Failed to push main branch - aborting${NC}"
            return 1
        fi
        
        git checkout -b production
        if ! git push --set-upstream "$target_remote" production; then
            echo -e "${RED}✗ Failed to push production branch - aborting${NC}"
            return 1
        fi
        
        git checkout -b develop
        if ! git push --set-upstream "$target_remote" develop; then
            echo -e "${RED}✗ Failed to push develop branch - aborting${NC}"
            return 1
        fi
    fi
    
    # Checkout requested branch or default
    if [ ! -z "$checkout_branch" ]; then
        git checkout "$checkout_branch" 2>/dev/null || echo -e "${YELLOW}Branch $checkout_branch not found${NC}"
    else
        git checkout develop 2>/dev/null || echo -e "${YELLOW}develop branch not found${NC}"
    fi
    
    # Return status
    [ "$push_success" = true ]
}

# Function to setup git providers (Gitlab, GitHub, Bitbucket, Gitea)
setup_provider() {
    local provider=$1
    local target=$2
    local self_hosted_url=$3
    
    case "$provider" in
        gitlab)
            handle_gitlab_setup "$target" "$self_hosted_url"
            ;;
        github)
            # TODO: implement handle_github_setup
            echo "Error: GitHub support coming soon"
            exit 1
            ;;
        bitbucket)
            # TODO: implement handle_bitbucket_setup
            echo "Error: Bitbucket support coming soon"
            exit 1
            ;;
        gitea)
            # TODO: handle_gitea_setup "$target" "$self_hosted_url"
            echo "Error: Bitbucket support coming soon"
            exit 1
            ;;
        *)
            echo "Error: Unknown provider: $provider"
            exit 1
            ;;
    esac
}

delete_online_repo_safe() {
    case "$PROVIDER" in
        gitlab)
            delete_online_repo_safe_gitlab
            ;;
        *)
            echo "Error: -k is currently implemented for GitLab provider only."
            return 1
            ;;
    esac
}

# Delete remote GitLab repository in safe mode (-k).
# Requires namespace TARGET and repository name REPO_NAME to be set.
# Performs a single confirmation by asking the user to type the repository name.
# Also records original and scheduled-deletion URLs in .repo_initiated_by_gitremoteforge.
delete_online_repo_safe_gitlab() {
    echo -e "${BLUE}Provider:${NC} GitLab"
    echo -e "${BLUE}Project path:${NC} ${TARGET}/${REPO_NAME}"
    echo -e "${YELLOW}This operation will delete the remote GitLab project only.${NC}"
    echo -e "${YELLOW}Local files and any local .git repository are not modified by this command.${NC}"
    echo
    if [ "$HARD_DELETE_FORCE_MODE" = true ]; then
        echo -e "${YELLOW}Force remote delete (-F) enabled: skipping repository-name confirmation for -k.${NC}"
    else
        echo -n "To confirm deletion, type the repository name exactly ('${REPO_NAME}'): "
        read -r confirmation

        if [ "$confirmation" != "$REPO_NAME" ]; then
            echo -e "${GREEN}Names did not match. Remote deletion aborted. No changes made.${NC}"
            return 0
        fi
    fi

    # Capture original remote URL from the current git repository (if available).
    local original_remote_url=""
    local current_dir="$BASE_DIR"
    if [ -d "$current_dir/.git" ]; then
        cd "$current_dir" 2>/dev/null || true
        original_remote_url=$(git remote get-url "$REMOTE_NAME" 2>/dev/null || git remote get-url origin 2>/dev/null || echo "")
    fi

    echo -e "${BLUE}Resolving GitLab project ID from remote...${NC}"
    if ! find_project_id_gitlab >/dev/null 2>&1; then
        echo -e "${RED}Failed to resolve GitLab project id from current git remote.${NC}"
        return 1
    fi

    echo -e "${BLUE}Deleting remote GitLab project by id:${NC} ${YELLOW}${GITLAB_LAST_PROJECT_ID}${NC}"
    if ! gitlab_api_request "DELETE" "/projects/${GITLAB_LAST_PROJECT_ID}"; then
        echo -e "${RED}GitLab project delete request failed.${NC}"
        if [ -n "$GITLAB_API_LAST_STATUS" ]; then
            echo -e "${YELLOW}GitLab API status:${NC} ${GITLAB_API_LAST_STATUS}"
        fi
        if [ -n "$GITLAB_API_LAST_BODY" ]; then
            echo -e "${YELLOW}GitLab API response body:${NC}"
            printf "%s\n" "$GITLAB_API_LAST_BODY"
        fi
        return 1
    fi

    echo -e "${GREEN}✓ Remote GitLab project '${TARGET}/${REPO_NAME}' deletion requested successfully.${NC}"

    # Derive scheduled-for-deletion project name/URLs from project id (best-effort).
    local scheduled_name scheduled_ssh_url scheduled_https_url
    if [ -n "$GITLAB_LAST_PROJECT_ID" ]; then
        scheduled_name="${REPO_NAME}-deletion_scheduled-${GITLAB_LAST_PROJECT_ID}"
        # GITLAB_DOMAIN is set by handle_gitlab_setup during provider setup.
        local domain="${GITLAB_DOMAIN:-gitlab.com}"
        scheduled_ssh_url="git@${domain}:${TARGET}/${scheduled_name}.git"
        scheduled_https_url="https://${domain}/${TARGET}/${scheduled_name}"
    fi

    if [ -n "$scheduled_https_url" ] || [ -n "$scheduled_ssh_url" ]; then
        echo -e "${BLUE}Scheduled-deletion project name (GitLab):${NC} ${TARGET}/${scheduled_name}"
        [ -n "$scheduled_ssh_url" ] && echo -e "${BLUE}Scheduled-deletion SSH URL:${NC} ${scheduled_ssh_url}"
        [ -n "$scheduled_https_url" ] && echo -e "${BLUE}Scheduled-deletion HTTPS URL:${NC} ${scheduled_https_url}"
    fi

    # Append tracking information to .repo_initiated_by_gitremoteforge in the local repo (if accessible).
    if [ -d "$current_dir" ]; then
        cd "$current_dir" 2>/dev/null || true
        if [ ! -f ".repo_initiated_by_gitremoteforge" ]; then
            echo "gitremoteforge version = ${version}" > .repo_initiated_by_gitremoteforge 2>/dev/null || true
        fi
        if [ -w ".repo_initiated_by_gitremoteforge" ]; then
            # Do not duplicate the deletion scheduled block if it already exists.
            if ! grep -q "################### DELETION SCHEDULED START #####################" ".repo_initiated_by_gitremoteforge" 2>/dev/null; then
                # Compute provider/domain and dates for tracking block.
                local domain="${GITLAB_DOMAIN:-gitlab.com}"
                local today=""
                local reminder_date=""
                if command -v date >/dev/null 2>&1; then
                    today=$(date '+%Y-%m-%d' 2>/dev/null || echo "")
                    reminder_date=$(date -v+1m '+%Y-%m-%d' 2>/dev/null || date -d '+30 days' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')
                fi
                {
                    echo "################### DELETION SCHEDULED START #####################"
                    echo "# Deletion Scheduled on remote GitLab on ${today}"
                    echo "# ------ remote origin ssh url"
                    echo "remote_origin_original_ssh_url = git@${domain}:${TARGET}/${REPO_NAME}.git"
                    if [ -n "$scheduled_ssh_url" ]; then
                        echo "remote_origin_deletion_scheduled_ssh_url = ${scheduled_ssh_url}"
                    fi
                    echo "# ------ remote origin https url"
                    echo "remote_origin_original_https_url = https://${domain}/${TARGET}/${REPO_NAME}"
                    if [ -n "$scheduled_https_url" ]; then
                        echo "remote_origin_deletion_scheduled_https_url = ${scheduled_https_url}"
                    fi
                    if [ -n "$reminder_date" ]; then
                        echo "# ------ Scheduled deletion date"
                        echo "scheduled_deletion_reminder_at = ${reminder_date}"
                    fi
                    echo "#################### DELETION SCHEDULED END ######################"
                } >> .repo_initiated_by_gitremoteforge 2>/dev/null || true
            fi
        fi
    fi

    return 0
}

# Delete remote GitLab repository in force mode (-K).
# Uses a two-step destructive confirmation flow similar in spirit to confirm_destructive_git_removal,
# then delegates to delete_online_repo_safe_gitlab and finally attempts an immediate delete
# on the scheduled-deletion project when supported by the GitLab instance.
delete_online_repo_force() {
    case "$PROVIDER" in
        gitlab)
            delete_online_repo_force_gitlab
            ;;
        *)
            echo "Error: -K is currently implemented for GitLab provider only."
            return 1
            ;;
    esac
}

delete_online_repo_force_gitlab() {
    if [ "$HARD_DELETE_FORCE_MODE" = true ]; then
        echo -e "${YELLOW}Force remote delete (-F) enabled: skipping interactive confirmations for -K.${NC}"
    else
        # Step 1: High-level destructive warning
        echo
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}  ⚠⚠⚠  REMOTE PROJECT DELETION WARNING  ⚠⚠⚠${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${RED}You are about to delete the remote GitLab project:${NC}"
        echo -e "  ${YELLOW}${TARGET}/${REPO_NAME}${NC}"
        echo
        echo -e "${YELLOW}What will be removed on GitLab:${NC}"
        echo -e "  • Remote repository and its git history"
        echo -e "  • All branches, tags, and remote references"
        echo -e "  • Any other data tied to the GitLab project (issues, merge requests, etc.)"
        echo
        echo -e "${YELLOW}Local files and local .git repository are NOT modified by this command.${NC}"
        echo
        echo -e "${YELLOW}Type 'yes' to continue, or anything else to abort:${NC}"
        read -r first_response

        case "$first_response" in
            [Yy][Ee][Ss])
                ;;
            *)
                echo -e "${GREEN}Operation cancelled. Remote project was not deleted.${NC}"
                return 0
                ;;
        esac

        # Step 2: Final phrase confirmation
        echo
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}  ⚠⚠⚠  FINAL WARNING - REMOTE DELETE  ⚠⚠⚠${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${RED}This is your last chance to cancel before the remote project is deleted.${NC}"
        echo
        echo -e "${YELLOW}To proceed, type the exact phrase:${NC}"
        echo -e "${YELLOW}  YES DELETE REMOTE REPO${NC}"
        echo -e "${YELLOW}Any other input will abort the operation.${NC}"
        read -r second_response

        # Normalize response: uppercase and trim whitespace
        local normalized_response
        normalized_response=$(echo "$second_response" | tr '[:lower:]' '[:upper:]')
        normalized_response="${normalized_response#"${normalized_response%%[![:space:]]*}"}"
        normalized_response="${normalized_response%"${normalized_response##*[![:space:]]}"}"

        if [ "$normalized_response" != "YES DELETE REMOTE REPO" ]; then
            echo -e "${GREEN}Final phrase did not match. Remote deletion aborted for safety.${NC}"
            return 0
        fi
    fi

    # Delegate to safe GitLab deletion (single confirmation + URL tracking).
    if ! delete_online_repo_safe_gitlab; then
        # Safe delete already printed error details.
        return 1
    fi

    # Attempt immediate permanent deletion using the scheduled-for-deletion project path.
    if [ -z "$GITLAB_LAST_PROJECT_ID" ]; then
        echo -e "${YELLOW}Skipping immediate deletion: project id not available for permanent removal call.${NC}"
        return 0
    fi

    local scheduled_name="${REPO_NAME}-deletion_scheduled-${GITLAB_LAST_PROJECT_ID}"
    local scheduled_full_path="${TARGET}/${scheduled_name}"

    echo -e "${BLUE}Requesting immediate permanent removal of scheduled-deletion project '${scheduled_full_path}' (if allowed by GitLab instance settings)...${NC}"
    echo -e "${BLUE}GitLab API endpoint:${NC} https://gitlab.com/api/v4/projects/${GITLAB_LAST_PROJECT_ID}?permanently_remove=true&full_path=${scheduled_full_path}"
    if gitlab_api_request "DELETE" "/projects/${GITLAB_LAST_PROJECT_ID}?permanently_remove=true&full_path=${scheduled_full_path}"; then
        # Double-check that the project is really gone by querying the same URL.
        # A 404 response means the project no longer exists online.
        gitlab_api_request "GET" "/projects/${GITLAB_LAST_PROJECT_ID}?permanently_remove=true&full_path=${scheduled_full_path}" || true
        if [ "$GITLAB_API_LAST_STATUS" = "404" ]; then
            echo -e "${GREEN}✓ Project '${REPO_NAME}' has been permanently deleted from GitLab.${NC}"
        else
            echo -e "${YELLOW}Project '${REPO_NAME}' might still be present according to a follow-up check (status: ${GITLAB_API_LAST_STATUS}).${NC}"
        fi

        # If a local repository marker exists, replace any existing deletion scheduled block
        # with a simpler "Deletion completed" block for future reference.
        local current_dir="$BASE_DIR"
        if [ -d "$current_dir" ]; then
            cd "$current_dir" 2>/dev/null || true
            if [ -f ".repo_initiated_by_gitremoteforge" ] && [ -w ".repo_initiated_by_gitremoteforge" ]; then
                local tmp_marker=".repo_initiated_by_gitremoteforge.tmp.$$"
                awk '
                    BEGIN {inside=0}
                    /################### DELETION SCHEDULED START #####################/ {inside=1; next}
                    /#################### DELETION SCHEDULED END ######################/ {inside=0; next}
                    inside==0 {print}
                ' .repo_initiated_by_gitremoteforge > "$tmp_marker" 2>/dev/null || rm -f "$tmp_marker"
                if [ -s "$tmp_marker" ]; then
                    mv "$tmp_marker" .repo_initiated_by_gitremoteforge 2>/dev/null || rm -f "$tmp_marker"
                else
                    rm -f "$tmp_marker"
                fi

                # Append the completion block with original remote URLs and deletion timestamp.
                local domain="${GITLAB_DOMAIN:-gitlab.com}"
                local deleted_at=""
                if command -v date >/dev/null 2>&1; then
                    deleted_at=$(date '+%Y-%m-%d %H:%M' 2>/dev/null || echo "")
                fi
                {
                    echo "################### DELETION SCHEDULED START #####################"
                    echo "# Deletion completed on remote GitLab on ${deleted_at}"
                    echo "# ------ remote origin ssh url reminder"
                    echo "remote_origin_original_ssh_url = git@${domain}:${TARGET}/${REPO_NAME}.git"
                    echo "# ------ remote origin https url"
                    echo "remote_origin_original_https_url = https://${domain}/${TARGET}/${REPO_NAME}"
                    echo "# ------ Scheduled deletion date"
                    echo "remote_origin_repo_deleted_at = ${deleted_at}"
                    echo "#################### DELETION SCHEDULED END ######################"
                } >> .repo_initiated_by_gitremoteforge 2>/dev/null || true
            fi
        fi

        return 0
    fi

    echo -e "${YELLOW}Immediate deletion request was not accepted by the GitLab instance.${NC}"
    if [ "$GITLAB_API_LAST_STATUS" = "400" ]; then
        echo -e "${YELLOW}The instance likely has immediate deletion disabled or restricted.${NC}"
        echo -e "${YELLOW}The project should remain in the scheduled-for-deletion state.${NC}"
    elif [ -n "$GITLAB_API_LAST_STATUS" ]; then
        echo -e "${YELLOW}GitLab API status:${NC} ${GITLAB_API_LAST_STATUS}"
    fi
    if [ -n "$GITLAB_API_LAST_BODY" ]; then
        echo -e "${YELLOW}GitLab API response body:${NC}"
        printf "%s\n" "$GITLAB_API_LAST_BODY"
    fi

    return 0
}

# Phase 2: Existing Repository Detection Functions

# Detect if directory contains .git
detect_existing_repo() {
    local path="$1"
    if [ -d "$path/.git" ]; then
        return 0  # Repo exists
    else
        return 1  # New repo
    fi
}

# Check if repo has any branches
has_branches() {
    local path="$1"
    cd "$path"
    local branch_count=$(git branch | wc -l)
    if [ "$branch_count" -gt 0 ]; then
        return 0  # Has branches
    else
        return 1  # No branches
    fi
}

# Get local branches
get_local_branches() {
    local path="$1"
    cd "$path"
    git branch | sed 's/^\* //' | sed 's/^ //'
}

# Detect if repo uses master or main
detect_master_vs_main() {
    local path="$1"
    cd "$path"
    
    if git rev-parse --verify main >/dev/null 2>&1; then
        echo "main"
    elif git rev-parse --verify master >/dev/null 2>&1; then
        echo "master"
    else
        echo "none"
    fi
}

# Check if remote exists (focus on origin, warn if multiple remotes)
validate_remote_exists() {
    local path="$1"
    cd "$path"
    
    local remote_count=$(git remote | wc -l)
    
    if [ "$remote_count" -gt 1 ]; then
        echo -e "${YELLOW}⚠ Multiple remotes detected:${NC}"
        git remote -v
        echo -e "${YELLOW}Note: git-remote-forge currently focuses on 'origin' only.${NC}"
        echo -e "${YELLOW}TODO: Multi-remote support (backlog)${NC}"
        return 0  # Multiple remotes exist
    elif [ "$remote_count" -eq 1 ]; then
        return 0  # Single remote (origin) exists
    else
        return 1  # No remotes
    fi
}

# Check if a remote URL already exists in any remote
# Returns remote name if URL exists, empty string if not
# Usage: remote_name=$(check_remote_url_exists "$url" "$path")
check_remote_url_exists() {
    local url="$1"
    local path="$2"
    cd "$path"
    
    # Get remote name that has this URL (fetch URLs)
    local remote_with_url=$(git remote -v | grep -E '\s+\(fetch\)$' | awk -v url="$url" '$2 == url {print $1; exit}')
    
    if [ -n "$remote_with_url" ]; then
        echo "$remote_with_url"
        return 0  # URL exists
    else
        return 1  # URL doesn't exist
    fi
}

# Get the URL of an existing remote
# Returns URL if remote exists, empty string if not
# Usage: url=$(get_remote_url "$remote_name" "$path")
get_remote_url() {
    local remote_name="$1"
    local path="$2"
    cd "$path"
    git remote get-url "$remote_name" 2>/dev/null
}

# Infer GitLab namespace (TARGET) and repository name (REPO_NAME) from the
# current git remote URL when possible.
# - Uses REMOTE_NAME if configured, otherwise falls back to 'origin'.
# - Respects explicitly provided TARGET / REPO_NAME values and only fills in
#   missing or placeholder values (e.g. REPO_NAME=".").
infer_gitlab_project_from_remote() {
    local old_pwd="$PWD"
    cd "$BASE_DIR" 2>/dev/null || cd "$old_pwd"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        cd "$old_pwd"
        return 1
    fi

    local remote_to_use="$REMOTE_NAME"
    local origin_url

    origin_url=$(git remote get-url "$remote_to_use" 2>/dev/null)
    if [ -z "$origin_url" ]; then
        origin_url=$(git remote get-url origin 2>/dev/null || echo "")
    fi

    if [ -z "$origin_url" ]; then
        cd "$old_pwd"
        return 1
    fi

    local path_part tmp
    case "$origin_url" in
        git@*:* )
            # SSH form: git@gitlab.com:namespace/repo.git
            path_part="${origin_url#*:}"
            ;;
        http://*|https://*|ssh://* )
            # HTTP(S) or ssh:// form: protocol://host/namespace/repo.git
            tmp="${origin_url#*://}"
            path_part="${tmp#*/}"
            ;;
        * )
            cd "$old_pwd"
            return 1
            ;;
    esac

    # Strip trailing .git if present
    path_part="${path_part%.git}"

    local repo_name namespace
    repo_name="${path_part##*/}"
    namespace="${path_part%/*}"

    cd "$old_pwd"

    if [ -z "$repo_name" ] || [ -z "$namespace" ]; then
        return 1
    fi

    if [ -z "$TARGET" ]; then
        TARGET="$namespace"
    fi
    if [ -z "$REPO_NAME" ] || [ "$REPO_NAME" = "." ]; then
        REPO_NAME="$repo_name"
    fi

    return 0
}

# Prompt user when remote name exists but URL differs
# Returns: "replace", "keep", or "abort"
# Usage: choice=$(prompt_replace_remote "$remote_name" "$new_url" "$existing_url")
prompt_replace_remote() {
    local remote_name="$1"
    local new_url="$2"
    local existing_url="$3"
    
    echo -e "\n${YELLOW}Remote '${remote_name}' already exists with different URL:${NC}"
    echo -e "  Existing: ${BLUE}${existing_url}${NC}"
    echo -e "  New:      ${BLUE}${new_url}${NC}"
    echo
    echo -e "${YELLOW}Choose action:${NC}"
    echo "  replace - Replace URL with new one"
    echo "  keep    - Keep existing URL (abort operation)"
    echo "  abort   - Abort operation"
    echo
    read -p "Your choice [replace/keep/abort]: " choice
    
    case "$choice" in
        replace|r)
            echo "replace"
            ;;
        keep|k)
            echo "keep"
            ;;
        abort|a|"")
            echo "abort"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            prompt_replace_remote "$remote_name" "$new_url" "$existing_url"
            ;;
    esac
}

# Prompt user for branch strategy (Y/N/A)
prompt_branch_strategy() {
    local local_branches="$1"
    local existing_primary="$2"
    
    echo -e "\n${YELLOW}Existing Repository Detected${NC}"
    echo -e "Local branches: ${BLUE}$local_branches${NC}"
    echo -e "Primary branch: ${BLUE}$existing_primary${NC}"
    echo
    echo -e "${YELLOW}Branch Strategy:${NC}"
    echo "  Y - Keep existing branches only (no modifications)"
    echo "  N - Abort (review repository manually)"
    echo "  A - Keep existing + add missing standard branches (main/production/develop)"
    echo
    
    read -p "Choose strategy [Y/N/A]: " choice
    
    case "$choice" in
        Y|y)
            echo "keep_existing"
            ;;
        N|n)
            echo "abort"
            ;;
        A|a)
            echo "add_missing"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            prompt_branch_strategy "$local_branches" "$existing_primary"
            ;;
    esac
}

# Manage local directory (check existence, create if needed)
# Handles three scenarios:
# 1. -d provided: Create new directory with that name in current location
# 2. -p provided: Use existing directory at specified path (or create if doesn't exist)
# 3. Neither provided: Default to current directory (.)
local_directory() {
    local dir_name="$1"
    local target_path
    local path_to_normalize
    
    # Priority: -p flag takes precedence over -d flag
    # If DIRECTORY_PATH (-p) is provided, use it as the target path
    if [ -n "$DIRECTORY_PATH" ]; then
        path_to_normalize="$DIRECTORY_PATH"
    else
        # Use DIRECTORY_NAME (-d) to construct path
        if [ -n "$dir_name" ]; then
            # Support both absolute and relative paths for -d
            if [[ "$dir_name" = /* ]]; then
                path_to_normalize="$dir_name"
            else
                # Relative path: append to current working directory
                path_to_normalize="${BASE_DIR}/${dir_name}"
            fi
        else
            # No -d and no -p: default to current directory
            # This enables: gitremote -n my_name (uses current directory)
            path_to_normalize="."
        fi
    fi
    
    # Normalize the path to ensure clean absolute path (removes ./, resolves .)
    target_path=$(normalize_path "$path_to_normalize")
    
    # Extract display components for user-friendly output
    local display_name=$(basename "$target_path")
    local parent_path=$(dirname "$target_path")
    
    echo -e "${BLUE}Directory: ${YELLOW}$display_name${NC}"
    echo -e "${BLUE}Parent: ${YELLOW}$parent_path${NC}"
    
    # Create directory if it doesn't exist, otherwise use existing
    if [ -d "$target_path" ]; then
        echo -e "${BLUE}Status: Using existing Directory${NC}"
    else
        mkdir -p "$target_path"
        echo -e "${BLUE}Status: Created${NC}"
    fi
    
    # Store normalized path for use in rest of script
    LOCAL_TARGET="$target_path"
}

# Function to handle two-step confirmation for destructive .git removal
# This function strongly discourages the user and requires explicit confirmation
# Parameters:
#   $1: context_message - Additional context about what will be lost (e.g., "Multiple remotes detected")
# Returns:
#   0 (success) - User confirmed both steps, proceed with .git removal
#   1 (failure) - User chose "keep", abort operation
#   Exits with 0 - User chose "abort" or invalid input, operation cancelled
# Usage:
#   if ! confirm_destructive_git_removal "$context_msg"; then
#       exit 0  # User chose "keep"
#   fi
#   # User confirmed, proceed with removal
confirm_destructive_git_removal() {
    local context_message="$1"
    
    # Step 1: First warning and confirmation
    echo
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ⚠⚠⚠  DESTRUCTIVE OPERATION WARNING  ⚠⚠⚠${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${RED}This operation will PERMANENTLY DELETE the .git directory!${NC}"
    echo -e "${RED}This is a NO-RETURN operation - you CANNOT undo this action!${NC}"
    echo
    echo -e "${YELLOW}What will be LOST FOREVER:${NC}"
    echo -e "  • All git history and commits"
    echo -e "  • All branches (main, develop, production, etc.)"
    echo -e "  • All remotes and remote configurations"
    echo -e "  • All tags and references"
    echo -e "  • All stashed changes"
    echo
    if [ -n "$context_message" ]; then
        echo -e "${YELLOW}Context: ${context_message}${NC}"
        echo
    fi
    echo -e "${RED}Are you ABSOLUTELY SURE you want to proceed?${NC}"
    echo -e "${YELLOW}Type 'yes' to continue, or anything else to see options:${NC}"
    read -r first_response
    
    # If user doesn't type "yes", show options
    if [[ ! "$first_response" =~ ^[Yy][Ee][Ss]$ ]]; then
        echo
        echo -e "${YELLOW}Options:${NC}"
        echo -e "  ${GREEN}reset${NC}     - Remove .git and reinitialize (destructive)"
        echo -e "  ${BLUE}keep${NC}      - Keep existing .git directory (safe)"
        echo -e "  ${RED}abort${NC}     - Abort operation and exit"
        echo -e "  ${YELLOW}think${NC}    - Let me think about it (same as abort)"
        echo
        echo -e "${YELLOW}Your choice [reset/keep/abort/think]:${NC}"
        read -r choice
        case "$choice" in
            reset)
                # User explicitly chose reset, proceed to second confirmation
                ;;
            keep)
                echo -e "${GREEN}Keeping existing .git directory${NC}"
                return 1  # Return non-zero to indicate "keep"
                ;;
            abort|think|"")
                echo -e "${YELLOW}Operation cancelled. No changes made.${NC}"
                exit 0
                ;;
            *)
                echo -e "${YELLOW}Invalid choice. Operation cancelled for safety.${NC}"
                exit 0
                ;;
        esac
    fi
    
    # Step 2: Second confirmation (even stronger warning)
    echo
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ⚠⚠⚠  FINAL WARNING - NO RETURN  ⚠⚠⚠${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${RED}You are about to PERMANENTLY DELETE all git history!${NC}"
    echo -e "${RED}This CANNOT be undone. There is NO way to recover this data!${NC}"
    echo
    echo -e "${YELLOW}Are you REALLY, REALLY SURE?${NC}"
    echo -e "${RED}Type 'YES I AM SURE' (exactly, with spaces) to proceed, or anything else to abort:${NC}"
    read -r second_response
    
    # Require exact match for final confirmation (case-insensitive but must match words exactly)
    # Normalize the response: convert to uppercase and trim leading/trailing whitespace
    # Use bash parameter expansion to trim whitespace (more portable than xargs)
    local normalized_response=$(echo "$second_response" | tr '[:lower:]' '[:upper:]')
    normalized_response="${normalized_response#"${normalized_response%%[![:space:]]*}"}"  # Trim leading
    normalized_response="${normalized_response%"${normalized_response##*[![:space:]]}"}"  # Trim trailing
    
    if [ "$normalized_response" = "YES I AM SURE" ]; then
        echo
        echo -e "${RED}Final confirmation received. Proceeding with destructive operation...${NC}"
        return 0  # Return zero to indicate "reset" confirmed
    else
        echo
        echo -e "${GREEN}Operation cancelled. Your .git directory is safe.${NC}"
        echo -e "${YELLOW}No changes were made.${NC}"
        exit 0
    fi
}

# Manage git repository (detect or initialize)
# Handles git repository detection and remote conflict resolution
# Scenarios:
# 1. No .git: Initialize new repository
# 2. .git exists, no remotes: Continue (will add remote)
# 3. .git exists, remote exists: Check for conflicts based on flags
manage_git() {
    local target="$1"
    
    cd "$target"
    
    # Check if .git exists
    if [ -d ".git" ]; then
        echo -e "${BLUE}Existing Git repository detected${NC}"
        
        # PRIORITY: If -O flag is set, check conditions and prompt for confirmation FIRST
        # This must happen IMMEDIATELY, before any other operations, previews, or standard confirmations
        # Even before checking remotes in detail - user must confirm destruction first
        if [ "$OVERRIDE_GIT" = true ]; then
            # Check what will be lost (remotes and branches)
            local remote_count=$(git remote | wc -l)
            local existing_remote=$(git remote | head -n1 2>/dev/null || echo "")
            local branches=$(get_local_branches "." 2>/dev/null || echo "")
            
            # Determine what will be lost and build context message
            local context_msg=""
            local needs_confirmation=false
            
            if [ "$remote_count" -gt 1 ]; then
                # Multiple remotes - show them and branches
                echo -e "${YELLOW}⚠ Multiple remotes detected:${NC}"
                git remote -v
                echo
                if [ -n "$branches" ]; then
                    echo -e "${YELLOW}⚠ Existing branches that will be lost:${NC}"
                    echo "$branches"
                    echo
                fi
                context_msg="Multiple remotes detected. All remotes and branches will be lost."
                needs_confirmation=true
            elif [ "$remote_count" -eq 1 ] && [ "$existing_remote" = "$REMOTE_NAME" ]; then
                # Single remote with matching name - show remote and branches
                echo -e "${YELLOW}⚠ Remote '${REMOTE_NAME}' already configured:${NC}"
                git remote -v
                echo
                if [ -n "$branches" ]; then
                    echo -e "${YELLOW}⚠ Existing branches that will be lost:${NC}"
                    echo "$branches"
                    echo
                fi
                context_msg="Remote '${REMOTE_NAME}' already configured. All remotes and branches will be lost."
                needs_confirmation=true
            elif [ -n "$branches" ]; then
                # Branches exist but no remote conflicts
                echo -e "${YELLOW}⚠ Existing branches detected:${NC}"
                echo "$branches"
                echo
                context_msg="Existing branches detected. All branches and git history will be lost."
                needs_confirmation=true
            fi
            
            # If conditions require confirmation, prompt NOW (before any other operations)
            if [ "$needs_confirmation" = true ]; then
                # Require two-step confirmation - ALWAYS required for -O flag (safety first)
                # This happens FIRST, before preview or any other operations
                # Even with -f flag, this confirmation cannot be bypassed
                if ! confirm_destructive_git_removal "$context_msg"; then
                    # User chose "keep" - exit without removing .git
                    exit 0
                fi
                # User confirmed both steps - proceed with removal
                echo -e "${BLUE}Removing existing .git directory...${NC}"
                rm -rf .git
                DEFER_GIT_INIT_AFTER_APPROVAL=true
                IS_EXISTING_REPO=false
                echo -e "${GREEN}✓ .git directory removed - will reinitialize${NC}"
                # Return early - .git is removed, normal flow will continue in main()
                return 0
            fi
        fi
        
        # If we reach here, either -O was not set, or .git was already removed above
        # Continue with normal git repository detection
        DEFER_GIT_INIT_AFTER_APPROVAL=false  # No need to defer, repo already exists
        
        # Check remotes and handle scenarios
        local remote_count=$(git remote | wc -l)
        local existing_remote=$(git remote | head -n1)
        
        # TODO: Future feature - Multi-remote support
        # Handle -R flag: Add new remote (keep existing)
        # This would allow adding a secondary remote (e.g., for different provider)
        # if [ -n "$NEW_REMOTE_NAME" ]; then
        #     if git remote | grep -q "^${NEW_REMOTE_NAME}$"; then
        #         echo -e "${YELLOW}Remote '${NEW_REMOTE_NAME}' already exists${NC}"
        #     else
        #         echo -e "${BLUE}Will add new remote: ${YELLOW}${NEW_REMOTE_NAME}${NC}"
        #     fi
        #     # Continue regardless of existing remotes when -R is used
        # # Handle -O flag: Override existing remote
        # elif [ "$OVERRIDE_REMOTE" = true ]; then
        #     if git remote | grep -q "^${REMOTE_NAME}$"; then
        #         echo -e "${YELLOW}Will override existing remote: ${BLUE}${REMOTE_NAME}${NC}"
        #     elif [ "$remote_count" -gt 0 ]; then
        #         echo -e "${YELLOW}Remote '${existing_remote}' already exists${NC}"
        #         git remote -v
        #         echo
        #         read -p "Do you want to replace '${existing_remote}' with '${REMOTE_NAME}'? (YES/NO): " response
        #         if [[ "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
        #             echo -e "${BLUE}Will override remote: ${YELLOW}${existing_remote}${NC} -> ${BLUE}${REMOTE_NAME}${NC}"
        #         else
        #             echo -e "${RED}Operation cancelled by user${NC}"
        #             exit 0
        #         fi
        #     fi
        
        # Current behavior: Check for conflicts with existing remotes
        # Handle three scenarios: multiple remotes, single remote conflict, or no conflict
        # Note: If -O flag was set, confirmation already happened above and .git was removed
        # So we only reach here if -O was not set or if .git was already removed
        if [ "$remote_count" -gt 1 ]; then
            # Scenario 1: Multiple remotes detected
            # git-remote-forge only works with a single remote, so this is a conflict
            # If we reach here with -O flag, it means .git was already removed above
            if [ "$OVERRIDE_GIT" = true ] && [ ! -d ".git" ]; then
                # .git was already removed above, continue normally
                :
            else
                # -O flag not set: Exit with error and show options
                # This is the safe default behavior - don't destroy data without explicit flag
                echo -e "${RED}✗ Multiple remotes detected${NC}"
                git remote -v
                echo
                echo -e "${YELLOW}git-remote-forge operates on '${REMOTE_NAME}' only${NC}"
                echo -e "${YELLOW}Options:${NC}"
                echo "  1. Rename other remotes: git remote rename <n> <new-name>"
                echo "  2. Remove extra remotes: git remote remove <n>"
                echo "  3. Use -O flag to override and reinitialize (removes .git)"
                echo "  4. Manage this repo manually outside gitremote"
                exit 1
            fi
        elif [ "$remote_count" -eq 1 ]; then
            # Scenario 2: Single remote exists
            if [ "$existing_remote" = "$REMOTE_NAME" ]; then
                # The remote name we want to use already exists
                # We'll check if the URL matches after setup_provider() sets REMOTE_URL
                # This allows operations like creating .gitignore even if remote already exists
                # If -O flag was set, confirmation already happened above and .git was removed
                if [ "$OVERRIDE_GIT" = true ] && [ ! -d ".git" ]; then
                    # .git was already removed above, continue normally
                    :
                else
                    # -O flag not set: Remote exists, but we'll check URL match later
                    # Don't exit here - allow operation to continue (user might only want .gitignore)
                    # URL validation happens in main() after setup_provider if remote setup is needed
                    REMOTE_EXISTS_CHECK_PENDING=true
                fi
            else
                # No conflict: Different remote name exists, but we want to use REMOTE_NAME
                # This is OK - we can add a new remote with the specified name alongside the existing one
                # git-remote-forge will work with REMOTE_NAME, existing remote is left untouched
                # Note: URL duplicate check happens after setup_provider() sets REMOTE_URL
                echo -e "${YELLOW}Remote '${existing_remote}' exists, will use '${REMOTE_NAME}'${NC}"
                echo -e "${BLUE}Note: Will check for URL duplicates after provider setup${NC}"
            fi
        fi
        # else: No remotes - continue (OK, will add remote)
        
        # Check if repo has branches to determine if it's truly an existing repo
        # This handles the case where there are no remote conflicts but branches exist
        # If -O flag was set, confirmation already happened above and .git was removed
        if has_branches "."; then
            # Scenario 3: Branches exist but no remote conflicts (or conflicts already handled above)
            # If -O flag was set and .git was already removed above, just continue
            if [ "$OVERRIDE_GIT" = true ] && [ ! -d ".git" ]; then
                # .git was already removed above, continue normally
                :
            else
                # -O flag not set, or already handled remote conflict above
                # Treat as existing repository and continue normally
                IS_EXISTING_REPO=true
                echo -e "${GREEN}✓ Existing branches detected${NC}"
            fi
        else
            # No branches detected: Empty .git directory (git init but no commits)
            # Treat as new repository - no override needed
            echo -e "${YELLOW}No branches detected - will initialize as new${NC}"
        fi
    else
        # No .git directory: Keep deferral flag true (will initialize after user confirmation)
        echo -e "${BLUE}No Git repository detected - will initialize after confirmation${NC}"
        # DEFER_GIT_INIT_AFTER_APPROVAL is already true by default
        IS_EXISTING_REPO=false
    fi
}

# Main script
main() {
    echo "git-remote-forge - Repository Setup Script v${version}"
    echo "-----------------------------"
    
    # Validate required inputs and set defaults
    # If no -d and no -p, default to current directory
    # This enables: gitremote -n my_name (uses current directory)
    if [ -z "$DIRECTORY_NAME" ] && [ -z "$DIRECTORY_PATH" ]; then
        DIRECTORY_PATH="."
    fi
    
    # If -p is provided but -d is not, extract directory name from path
    # This enables: gitremote -n my_name -p /path/to/repo (extracts "repo" as name)
    if [ -z "$DIRECTORY_NAME" ] && [ -n "$DIRECTORY_PATH" ]; then
        local normalized_path=$(normalize_path "$DIRECTORY_PATH")
        DIRECTORY_NAME=$(basename "$normalized_path")
    fi
    
    # Normalize DIRECTORY_NAME when it refers to current directory (e.g. "-d .")
    # so that REPO_NAME reflects the actual folder name instead of a literal ".".
    if [ -z "$DIRECTORY_NAME" ] || [ "$DIRECTORY_NAME" = "." ]; then
        local base_path
        if [ -n "$DIRECTORY_PATH" ]; then
            base_path=$(normalize_path "$DIRECTORY_PATH")
        else
            base_path="$BASE_DIR"
        fi
        DIRECTORY_NAME=$(basename "$base_path")
    fi
    
    # Set repository name based on directory name (used both for creation and deletion flows)
    REPO_NAME="$DIRECTORY_NAME"

    if [ "$GET_PROJECT_ID_ONLY" = true ]; then
        find_project_id_gitlab
        exit 0
    fi

    # Early branch: remote deletion mode (-k / -K) – GitLab-only, remote-only, no local changes
    if [ -n "$DELETE_ONLINE_REPO_MODE" ]; then
        # If namespace or repository name is missing/placeholder, try to infer
        # them from the current git remote before failing.
        if [ -z "$TARGET" ] || [ -z "$REPO_NAME" ] || [ "$REPO_NAME" = "." ]; then
            infer_gitlab_project_from_remote || true
        fi

        if [ -z "$TARGET" ] || [ -z "$REPO_NAME" ] || [ "$REPO_NAME" = "." ]; then
            echo "Error: -k / -K requires a GitLab namespace and repository name."
            echo "Provide -n <namespace> and -d/-p, or run inside a git repo with a configured remote."
            exit 1
        fi

        # Setup provider (must be gitlab for deletion in this version)
        setup_provider "$PROVIDER" "$TARGET" "$SELF_HOSTED_URL"

        case "$PROVIDER" in
            gitlab)
                if [ "$DELETE_ONLINE_REPO_MODE" = "safe" ]; then
                    delete_online_repo_safe
                else
                    delete_online_repo_force
                fi
                exit 0
                ;;
            *)
                echo "Error: -k / -K remote deletion is currently implemented for GitLab provider only."
                exit 1
                ;;
        esac
    fi

    # Step 1: Manage local directory
    # Pass DIRECTORY_NAME (may be empty if only -p provided, but local_directory handles it)
    # This function handles: new directory creation, existing directory detection, path normalization
    local_directory "${DIRECTORY_NAME:-}"
    
    # Normalize LOCAL_TARGET for clean display (removes ./ from paths)
    LOCAL_TARGET=$(normalize_path "$LOCAL_TARGET")
    
    # Extract directory name from resolved path (for use as repository name)
    # This ensures REPO_NAME matches the actual directory name
    DIRECTORY_NAME=$(basename "$LOCAL_TARGET")
    
    # Step 2: Manage git repository
    manage_git "$LOCAL_TARGET"
    
    echo -e "${BLUE}Full path: ${YELLOW}$LOCAL_TARGET${NC}"
    echo
    
    # Get git user info
    contributor=$(get_git_user_info)
    
    # Update repository name after resolving full path
    REPO_NAME="$DIRECTORY_NAME"

    # Step 3: Setup provider with self-hosted URL if provided
    # Note: We set up provider even if only creating .gitignore, but we'll handle remote conflicts gracefully
    if [ -n "$TARGET" ]; then
        setup_provider "$PROVIDER" "$TARGET" "$SELF_HOSTED_URL"
        
        # Check if remote exists and URL matches (deferred from manage_git)
        # If user only wants .gitignore, we allow operation to continue even with remote conflicts
        if [ "$REMOTE_EXISTS_CHECK_PENDING" = true ]; then
            cd "$LOCAL_TARGET"
            local existing_remote_url=$(get_remote_url "$REMOTE_NAME" "$LOCAL_TARGET")
            if [ -n "$existing_remote_url" ] && [ "$existing_remote_url" = "$REMOTE_URL" ]; then
                # Remote exists and URL matches - this is fine, just skip adding remote
                echo -e "${GREEN}✓ Remote '${REMOTE_NAME}' already configured with matching URL${NC}"
                echo -e "${BLUE}  ${existing_remote_url}${NC}"
                echo -e "${BLUE}  Skipping remote setup, continuing with other operations...${NC}"
                REMOTE_EXISTS_CHECK_PENDING=false
            elif [ -n "$existing_remote_url" ]; then
                # Remote exists but URL doesn't match - prompt user for action
                # If user only wants .gitignore, warn but continue; otherwise prompt
                if [ "$CREATE_GITIGNORE" = true ] && [ "$IS_EXISTING_REPO" = true ]; then
                    # User wants .gitignore on existing repo - warn but continue
                    echo -e "${YELLOW}⚠ Remote '${REMOTE_NAME}' exists with different URL${NC}"
                    echo -e "${BLUE}Current: ${existing_remote_url}${NC}"
                    echo -e "${BLUE}Would create: ${REMOTE_URL}${NC}"
                    echo -e "${YELLOW}Continuing with .gitignore creation (remote setup skipped)${NC}"
                    REMOTE_EXISTS_CHECK_PENDING=false
                else
                    # Need remote setup - prompt user for replace/keep/abort
                    local choice=$(prompt_replace_remote "$REMOTE_NAME" "$REMOTE_URL" "$existing_remote_url")
                    case "$choice" in
                        replace)
                            # User chose to replace URL
                            git remote set-url "$REMOTE_NAME" "$REMOTE_URL"
                            echo -e "${GREEN}✓ Updated remote '${REMOTE_NAME}' URL${NC}"
                            REMOTE_EXISTS_CHECK_PENDING=false
                            ;;
                        keep)
                            # User chose to keep existing URL - abort operation
                            echo -e "${YELLOW}Keeping existing remote URL. Operation cancelled.${NC}"
                            exit 0
                            ;;
                        abort)
                            # User chose to abort
                            echo -e "${YELLOW}Operation cancelled by user${NC}"
                            exit 0
                            ;;
                    esac
                fi
            fi
        fi
        
        # Check for duplicate URLs when different remote name exists
        # This prevents adding multiple remotes with the same URL
        cd "$LOCAL_TARGET"
        local remote_with_same_url=$(check_remote_url_exists "$REMOTE_URL" "$LOCAL_TARGET")
        if [ -n "$remote_with_same_url" ] && [ "$remote_with_same_url" != "$REMOTE_NAME" ]; then
            # URL already exists with a different remote name
            if [ "$REPLACE_REMOTE" = true ]; then
                # -R flag: Rename existing remote to new name (same URL)
                echo -e "${BLUE}Renaming remote '${remote_with_same_url}' to '${REMOTE_NAME}' (same URL)${NC}"
                git remote rename "$remote_with_same_url" "$REMOTE_NAME"
                echo -e "${GREEN}✓ Remote renamed successfully${NC}"
            else
                # -r flag: Prevent duplicate, show options
                echo -e "${RED}✗ Remote URL '${REMOTE_URL}' already exists as remote '${remote_with_same_url}'${NC}"
                echo -e "${BLUE}Current remotes:${NC}"
                git remote -v
                echo
                echo -e "${YELLOW}Options:${NC}"
                echo "  1. Use existing remote '${remote_with_same_url}' (don't specify -r, or use -r ${remote_with_same_url})"
                echo "  2. Use -R flag to replace remote name (with same URL: namespace and provider)"
                echo "  3. Remove existing remote manually outside gitremote: git remote remove ${remote_with_same_url}"
                echo "  5. Use -O flag to override and reinitialize (removes .git) - WARNING: DESTRUCTIVE. Read documentation, this would delete all existing .git history"
                exit 1
            fi
        fi
        
        # Notify user when adding new remote with different URL (other remotes exist)
        local other_remotes=$(git remote | grep -v "^${REMOTE_NAME}$" | tr '\n' ',' | sed 's/,$//')
        if [ -n "$other_remotes" ] && ! git remote | grep -q "^${REMOTE_NAME}$"; then
            # Adding new remote and other remotes exist - notify user
            echo -e "${YELLOW}⚠ Other remotes exist: ${other_remotes}${NC}"
            echo -e "${BLUE}Adding new remote '${REMOTE_NAME}' with URL '${REMOTE_URL}'${NC}"
        fi
    fi

    echo -e "\nStarting repository setup..."

    # Preview operations if not in force mode
    if [ "$FORCE_MODE" = false ]; then
        preview_operations "$DIRECTORY_NAME" "$contributor" "$TECHNOLOGIES" "$CHECKOUT_BRANCH"
    fi
    
    # Initialize git repository if deferred (after user confirmation)
    # This happens when:
    #   - New repository (no .git directory existed)
    #   - Repository was overridden with -O flag (removed and needs reinit)
    if [ "$DEFER_GIT_INIT_AFTER_APPROVAL" = true ]; then
        echo -e "${BLUE}Initializing new Git repository${NC}"
        cd "$LOCAL_TARGET"
        git init
        
        # Create .gitignore if -i flag is set
        # This handles cases where:
        #   - New repo is being created
        #   - Existing repo was overridden with -O flag and reinitialized
        if [ "$CREATE_GITIGNORE" = true ]; then
            create_gitignore "$LOCAL_TARGET"
        fi
    elif [ "$CREATE_GITIGNORE" = true ] && [ "$IS_EXISTING_REPO" = false ]; then
        # Edge case: .git directory exists but has no branches (empty repository)
        # Still create .gitignore if -i flag is set, even though git init wasn't needed
        create_gitignore "$LOCAL_TARGET"
    fi
    
    # Step 4: Create git repo structure (README, initial commit) if new
    if [ "$IS_EXISTING_REPO" = false ]; then
        create_local_repo "$LOCAL_TARGET" "$contributor" "$TECHNOLOGIES"
    fi
    
    # Handle .gitignore creation for all scenarios
    if [ "$CREATE_GITIGNORE" = true ]; then
        cd "$LOCAL_TARGET"
        if create_gitignore "$LOCAL_TARGET"; then
            # .gitignore was created - add to git if repository exists
            if [ -d ".git" ]; then
                git add .gitignore 2>/dev/null || true
                if [ -f ".repo_initiated_by_gitremoteforge" ]; then
                    git add .repo_initiated_by_gitremoteforge 2>/dev/null || true
                fi
                # Commit if there are changes staged and repo has commits
                if ! git diff --cached --quiet 2>/dev/null && has_branches "."; then
                    git commit -m "Add .gitignore and repository marker (git-remote-forge)" 2>/dev/null || true
                    echo -e "${GREEN}✓ Added .gitignore to repository${NC}"
                fi
            fi
        fi
        # If .gitignore already existed, create_gitignore() already informed the user
    fi
    
    # Step 5: Push to remote (only if we have a target and no pending remote conflicts)
    if [ -n "$TARGET" ] && [ "$REMOTE_EXISTS_CHECK_PENDING" = false ]; then
        if push_to_remote "$CHECKOUT_BRANCH"; then
            echo -e "\n${GREEN}Repository setup completed successfully!${NC}"
        else
            echo -e "\n${RED}Repository setup completed with errors - see above for details${NC}"
            exit 1
        fi
    elif [ "$CREATE_GITIGNORE" = true ]; then
        # Only .gitignore was created - operation complete
        echo -e "\n${GREEN}Operation completed successfully!${NC}"
    else
        echo -e "\n${GREEN}Repository setup completed successfully!${NC}"
    fi
}

# Parse command line arguments
parse_arguments "$@"

# If no arguments provided, show help and exit
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

# Start the script
main "$@"
