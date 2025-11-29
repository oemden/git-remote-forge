#!/bin/bash

# GRF (git-remote-forge)
# A tool to create and setup git projects locally and push it remotely via ssh ( on gitlab.com for Now )
# Creates three default branches:
#   - main: primary branch
#   - production: for production releases
#   - develop: active development branch

Version="0.7"

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
TECHNOLOGIES=""
FORCE_MODE=false

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
    echo "  -d    Directory/Project name (required)"
    echo "  -B    Branch to checkout after creation (default: develop)"
    echo "  -t    Technologies (optional, comma-separated)"
    echo "  -f    Force mode (skip dry-run and confirmation)"
    echo "  -h    Display this help message"
    echo
    echo "Default branches created: main, production, develop"
    echo "Default checkout: develop (unless -B specified)"
    exit 1
}

# Parse command line arguments
parse_arguments() {
    while getopts "d:B:t:fh" opt; do
        case ${opt} in
            d )
                DIRECTORY_NAME=$OPTARG
                ;;
            B )
                CHECKOUT_BRANCH=$OPTARG
                ;;
            t )
                TECHNOLOGIES=$OPTARG
                ;;
            f )
                FORCE_MODE=true
                ;;
            h )
                usage
                ;;
            \? )
                usage
                ;;
        esac
    done
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

# Function to preview operations
preview_operations() {
    local dir_name="$1"
    local contributor="$2"
    local technologies="$3"
    local checkout_branch="$4"
    local namespace="$5"

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
    echo -e "   • Configure remote origin:"
    echo -e "     ${BLUE}${GITLAB_BASE_URL}${namespace}/${dir_name}.git${NC}"

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

# Function to create local repository
create_local_repo() {
    local dir_name="$1"
    local full_path="${BASE_DIR}/${dir_name}"
    
    if [ -d "$full_path" ]; then
        echo "Error: Directory $full_path already exists"
        exit 1
    fi
    
    mkdir -p "$full_path" && cd "$full_path"
    git init
    
    # Create README.md with dynamic content
    cat > README.md << EOL
# $dir_name

## Project Overview
This repository contains the source code for $dir_name.

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

# Function to push to GitLab
push_to_gitlab() {
    # local namespace="$1"
    # local checkout_branch="$2"
    local checkout_branch="$1"
    
    # Setup remote and push main
    # local remote_url="${GITLAB_BASE_URL}${namespace}/${DIRECTORY_NAME}.git"
    local remote_url="$REMOTE_URL"
    git remote add origin "$remote_url"
    git push --set-upstream origin main
    
    # Create and push production
    git checkout -b production
    git push --set-upstream origin production
    
    # Create and push develop
    git checkout -b develop
    git push --set-upstream origin develop
    
    # Checkout based on -B flag or default to develop
    if [ ! -z "$checkout_branch" ]; then
        git checkout "$checkout_branch"
    else
        git checkout develop
    fi
    
    # Detect and update technologies if not specified
    if [ -z "$TECHNOLOGIES" ]; then
        local detected_tech=$(detect_technologies ".")
        if [ ! -z "$detected_tech" ]; then
            git checkout main
            echo -e "\n## Technologies\n$detected_tech" >> README.md
            git add README.md
            git commit -m "Update README: Add detected technologies"
            git push origin main
            
            # Update production and develop
            git checkout production
            git merge main
            git push origin production
            
            git checkout develop
            git merge main
            git push origin develop
            
            # Return to previous branch
            if [ ! -z "$checkout_branch" ]; then
                git checkout "$checkout_branch"
            else
                git checkout develop
            fi
        fi
    fi
}

# Main script
main() {
    echo "GitLab Repository Setup Script v${Version}"
    echo "-----------------------------"
    
    # Validate required inputs
    if [ -z "$DIRECTORY_NAME" ]; then
        echo "Error: Directory/Project name is required"
        usage
    fi
    
    # Get git user info
    contributor=$(get_git_user_info)
    
    # Setup provider (GitLab only for now)
    REPO_NAME="$DIRECTORY_NAME"
    handle_gitlab_setup ""  "" # Empty string triggers interactive mode - For now, defaults to gitlab.com

    echo -e "\nStarting repository setup..."
    
    # Preview operations if not in force mode
    if [ "$FORCE_MODE" = false ]; then
        preview_operations "$DIRECTORY_NAME" "$contributor" "$TECHNOLOGIES" "$CHECKOUT_BRANCH" "$gitlab_ns"
    fi
    
    # Create local repository
    create_local_repo "$DIRECTORY_NAME" "$contributor" "$TECHNOLOGIES"
    
    # Push to GitLab
    push_to_gitlab "$gitlab_ns" "$CHECKOUT_BRANCH"
    
    echo -e "\nRepository setup completed successfully!"
}

# Parse command line arguments
parse_arguments "$@"

# Start the script
main "$@"