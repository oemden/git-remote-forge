#!/bin/bash

Version="0.5"

# Constants
GITLAB_BASE_URL="git@gitlab.com:"

# Default values
BRANCH_NAME="main"
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
    echo "  -d    Directory/Project name"
    echo "  -b    Branch name (default: main)"
    echo "  -t    Technologies (optional, comma-separated)"
    echo "  -f    Force mode (skip dry-run and confirmation)"
    echo "  -h    Display this help message"
    exit 1
}

# Parse command line arguments
parse_arguments() {
    while getopts "d:b:t:fh" opt; do
        case ${opt} in
            d )
                DIRECTORY_NAME=$OPTARG
                ;;
            b )
                BRANCH_NAME=$OPTARG
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

# Function to detect technologies based on file extensions
detect_technologies() {
    local dir="$1"
    local tech_list=""
    local extensions=()
    
    # Map of file extensions to technologies
    declare -A tech_map
    tech_map['.py']=Python
    tech_map['.js']='JavaScript'
    tech_map['.ts']='TypeScript'
    tech_map['.html']='HTML'
    tech_map['.css']='CSS'
    tech_map['.java']='Java'
    tech_map['.cpp']='C++'
    tech_map['.c']='C'
    tech_map['.go']='Go'
    tech_map['.rb']='Ruby'
    tech_map['.php']='PHP'
    tech_map['.rs']='Rust'
    tech_map['.swift']='Swift'
    tech_map['.kt']='Kotlin'
    tech_map['.scala']='Scala'
    tech_map['.sh']='Shell'
    tech_map['.yml']='YAML'
    tech_map['.yaml']='YAML'
    tech_map['.json']='JSON'
    tech_map['.xml']='XML'
    tech_map['.md']='Markdown'
    tech_map['.sql']='SQL'
    tech_map['.dockerfile']='Docker'
    tech_map['.tf']='Terraform'
    tech_map['.gradle']='Gradle'
    tech_map['.maven']='Maven'
    
    # Look for special files
    if [ -f "$dir/Dockerfile" ]; then
        extensions+=("Docker")
    fi
    if [ -f "$dir/package.json" ]; then
        extensions+=("Node.js")
    fi
    if [ -f "$dir/requirements.txt" ]; then
        extensions+=("Python")
    fi
    if [ -f "$dir/pom.xml" ]; then
        extensions+=("Java/Maven")
    fi
    if [ -f "$dir/build.gradle" ]; then
        extensions+=("Java/Gradle")
    fi
    
    # Find all file extensions in the directory
    find "$dir" -type f -print0 | while IFS= read -r -d '' file
    do
        ext="${file##*.}"
        if [[ -n "$ext" && "$ext" != "$file" ]]; then
            ext=".${ext,,}"  # Convert to lowercase
            if [[ -n "${tech_map[$ext]}" ]]; then
                extensions+=("${tech_map[$ext]}")
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

# Function to preview operations
preview_operations() {
    local dir_name="$1"
    local contributor="$2"
    local technologies="$3"
    local branch_name="$4"
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
    echo -e "   • Current branch: ${BLUE}main${NC}"
    [[ "$branch_name" != "main" ]] && echo -e "   • Create and switch to: ${BLUE}$branch_name${NC}"

    # Push operations
    echo -e "\n${GREEN}4. Push Operations:${NC}"
    echo -e "   • Push branch: ${BLUE}main${NC}"
    [[ "$branch_name" != "main" ]] && echo -e "   • Push branch: ${BLUE}$branch_name${NC}"

    if [ -z "$TECHNOLOGIES" ]; then
        echo -e "\n${GREEN}5. Post-Setup Operations:${NC}"
        echo -e "   • Detect technologies in repository"
        echo -e "   • Update README.md if technologies found"
        echo -e "   • Push updates to origin"
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
    local contributor="$2"
    local technologies="$3"
    local branch_name="$4"
    
    if [ -d "$dir_name" ]; then
        echo "Error: Directory $dir_name already exists"
        exit 1
    fi
    
    mkdir "$dir_name" && cd "$dir_name"
    git init
    
    # Create README.md with dynamic content
    cat > README.md << EOL
# $dir_name

## Project Overview
This repository contains the source code for $dir_name.

## Main Contributor
$contributor
EOL

    # Add technologies section only if technologies are specified
    if [ ! -z "$technologies" ]; then
        cat >> README.md << EOL

## Technologies
$technologies
EOL
    fi

    git add README.md
    git commit -m "Initial commit: Add README.md"
}

# Function to push to GitLab
push_to_gitlab() {
    local namespace="$1"
    local branch_name="$2"
    
    # Setup remote
    local remote_url="${GITLAB_BASE_URL}${namespace}/${DIRECTORY_NAME}.git"
    git remote add origin "$remote_url"
    
    # Push main branch
    git push --set-upstream origin main
    
    # Create and push feature branch if specified
    if [ "$branch_name" != "main" ]; then
        git checkout -b "$branch_name"
        git push --set-upstream origin "$branch_name"
    fi
    
    # Detect and update technologies if not specified
    if [ -z "$TECHNOLOGIES" ]; then
        local detected_tech=$(detect_technologies ".")
        if [ ! -z "$detected_tech" ]; then
            # Switch back to main to update README
            if [ "$branch_name" != "main" ]; then
                git checkout main
            fi
            
            echo -e "\n## Technologies\n$detected_tech" >> README.md
            git add README.md
            git commit -m "Update README: Add detected technologies"
            git push origin main
            
            # If we were on a feature branch, go back and sync it
            if [ "$branch_name" != "main" ]; then
                git checkout "$branch_name"
                git merge main
                git push origin "$branch_name"
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
    
    # Get GitLab namespace
    gitlab_ns=$(get_gitlab_namespace)
    
    echo -e "\nStarting repository setup..."
    
    # Preview operations if not in force mode
    if [ "$FORCE_MODE" = false ]; then
        preview_operations "$DIRECTORY_NAME" "$contributor" "$TECHNOLOGIES" "$BRANCH_NAME" "$gitlab_ns"
    fi
    
    # Create local repository
    create_local_repo "$DIRECTORY_NAME" "$contributor" "$TECHNOLOGIES" "$BRANCH_NAME"
    
    # Push to GitLab
    push_to_gitlab "$gitlab_ns" "$BRANCH_NAME"
    
    echo -e "\nRepository setup completed successfully!"
}

# Parse command line arguments
parse_arguments "$@"

# Start the script
main "$@"