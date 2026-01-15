#!/bin/bash

# gitremote (git-remote-forge)
# A tool to create and setup git projects locally and push it remotely via ssh ( on gitlab.com for Now )
# Creates three default branches:
#   - main: primary branch
#   - production: for production releases
#   - develop: active development branch

Version="0.9.2"

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
TARGET=""
PROVIDER="gitlab"
CHECKOUT_BRANCH="develop"
SELF_HOSTED_URL=""
REMOTE_NAME="origin"
NEW_REMOTE_NAME=""
OVERRIDE_REMOTE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d    Local Directory/Project name (required for new repo)"
    echo "  -n    Namespace - for Gitlab /username - for GitHub (target on provider)"
    echo "  -r    Set custom remote name (default: origin)"
    # TODO: Future features (commented out for now)
    # echo "  -R    Add new remote name (keeps existing remotes) - Future: multi-provider support"
    # echo "  -O    Override existing remote - Future: remote override support"
    # echo "  -S    Self-hosted URL (optional, for self-hosted providers)"
    echo "  -t    Auto-detect technologies (existing directory mode)"
    echo "  -T    Technologies (user-provided, comma-separated, optional)"
    echo "  -b    Branch to checkout after creation (default: develop)"
    echo "  -p    Path to local directory (optional, for existing directory mode)"
    echo "  -f    Force mode (skip dry-run and confirmation)"
    echo "  -h    Display this help message"
    echo
    echo "Modes:"
    echo "  New Repository:       gitremote -d myproject -n myuser -T 'python,js'"
    echo "  Existing Directory:   gitremote -n myuser -t (auto-detect) or -T 'tech'"
    echo "  Existing Directory:   gitremote -p /path/to/dir -n myuser -t"
    echo
    echo "Default branches created: main, production, develop"
    echo "Default checkout: develop (unless -b specified)"
    exit 1
}

# Parse command line arguments
# Handles all command-line flags and sets corresponding variables
parse_arguments() {
    # Current flags: d, n, t, T, B, S, p, r, f, h
    # TODO: Future flags -R and -O commented out for multi-remote support
    while getopts "d:n:t:T:b:S:p:r:fh" opt; do
    # Future: while getopts "d:n:t:T:R:B:S:p:r:Ofh" opt; do
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
            # TODO: Future feature - Add new remote (multi-provider support)
            # R )
            #     # Add new remote name (keeps existing remotes)
            #     # Example: -R github (adds github remote, keeps origin)
            #     NEW_REMOTE_NAME=$OPTARG
            #     ;;
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
            # TODO: Future feature - Override existing remote
            # O )
            #     # Override existing remote (use with -r to override without prompt)
            #     OVERRIDE_REMOTE=true
            #     ;;
            : )
                # Missing argument for option
                echo "Error: Option -$OPTARG requires an argument"
                usage
                ;;
            f )
                # Force mode: skip preview and confirmation
                FORCE_MODE=true
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
    echo -e "   • Initialize git repository"
    echo -e "   • Create and commit README.md with:"
    echo -e "     - Project name: ${BLUE}$dir_name${NC}"
    echo -e "     - Contributor: ${BLUE}$contributor${NC}"
    [[ ! -z "$technologies" ]] && echo -e "     - Technologies: ${BLUE}$technologies${NC}"

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

    # Initial commit on main
    git add README.md
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
    
    # Current behavior: Add remote if it doesn't exist
    # manage_git() already validated that remote doesn't conflict
    if ! git remote | grep -q "^${target_remote}$"; then
        git remote add "$target_remote" "$remote_url"
        echo -e "${GREEN}✓ Added remote: ${BLUE}${target_remote}${NC}"
    else
        # This shouldn't happen if manage_git() worked correctly
        # But handle gracefully just in case
        echo -e "${YELLOW}Remote '${target_remote}' already exists, using existing${NC}"
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
            handle_gitea_setup "$target" "$self_hosted_url"
            ;;
        *)
            echo "Error: Unknown provider: $provider"
            exit 1
            ;;
    esac
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
        if [ "$remote_count" -gt 1 ]; then
            # Scenario: Multiple remotes detected
            echo -e "${RED}✗ Multiple remotes detected${NC}"
            git remote -v
            echo
            echo -e "${YELLOW}git-remote-forge operates on '${REMOTE_NAME}' only${NC}"
            echo -e "${YELLOW}Options:${NC}"
            echo "  1. Rename other remotes: git remote rename <n> <new-name>"
            echo "  2. Remove extra remotes: git remote remove <n>"
            echo "  3. Manage this repo manually outside gitremote"
            exit 1
        elif [ "$remote_count" -eq 1 ]; then
            # Scenario: Single remote exists
            if [ "$existing_remote" = "$REMOTE_NAME" ]; then
                # The remote we want to use already exists
                echo -e "${RED}✗ Remote '${REMOTE_NAME}' already configured${NC}"
                echo -e "${BLUE}Current remote:${NC}"
                git remote -v
                echo
                echo -e "${YELLOW}Options:${NC}"
                echo "  1. Change remote URL: git remote set-url ${REMOTE_NAME} <new-url>"
                echo "  2. Remove remote: git remote remove ${REMOTE_NAME}"
                echo "  3. Use -r <name> to specify a different remote name"
                echo "  4. Manage this repo manually outside gitremote"
                exit 1
            else
                # Different remote name exists, but we want to use REMOTE_NAME
                # This is OK - we'll add the new remote with the specified name
                echo -e "${YELLOW}Remote '${existing_remote}' exists, will use '${REMOTE_NAME}'${NC}"
            fi
        fi
        # else: No remotes - continue (OK, will add remote)
        
        # Check if repo has branches to determine if it's truly an existing repo
        if has_branches "."; then
            IS_EXISTING_REPO=true
            echo -e "${GREEN}✓ Existing branches detected${NC}"
        else
            # Empty .git directory - treat as new repo
            echo -e "${YELLOW}No branches detected - will initialize as new${NC}"
        fi
    else
        # No .git directory: Initialize new repository
        echo -e "${BLUE}Initializing new Git repository${NC}"
        git init
        IS_EXISTING_REPO=false
    fi
}

# Main script
main() {
    echo "git-remote-forge - Repository Setup Script v${Version}"
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
    
    # Set repository name
    REPO_NAME="$DIRECTORY_NAME"

    # Step 3: Setup provider with self-hosted URL if provided
    setup_provider "$PROVIDER" "$TARGET" "$SELF_HOSTED_URL"

    echo -e "\nStarting repository setup..."

    # Preview operations if not in force mode
    if [ "$FORCE_MODE" = false ]; then
        preview_operations "$DIRECTORY_NAME" "$contributor" "$TECHNOLOGIES" "$CHECKOUT_BRANCH"
    fi
    
    # Step 4: Create git repo structure (README, initial commit) if new
    if [ "$IS_EXISTING_REPO" = false ]; then
        create_local_repo "$LOCAL_TARGET" "$contributor" "$TECHNOLOGIES"
    fi
    
    # Step 5: Push to remote
    if push_to_remote "$CHECKOUT_BRANCH"; then
        echo -e "\n${GREEN}Repository setup completed successfully!${NC}"
    else
        echo -e "\n${RED}Repository setup completed with errors - see above for details${NC}"
        exit 1
    fi
}

# Parse command line arguments
parse_arguments "$@"

# Start the script
main "$@"
