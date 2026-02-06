#!/bin/bash
# PURPOSE: tests/generate_dummy_repo_name.sh - Generate unique random dummy repository names with collision detection
# Used by test scripts to avoid hard-coded project names and local collisions.

set -e

# Resolve script directory and source shared test configuration
# tests.cfg provides dummy_parent_directory used for collision checks
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

# Maximum number of attempts to generate a unique name before failing
MAX_ATTEMPTS=10

# Generate a random 6-character hexadecimal suffix
# Returns lowercase hex characters so resulting names stay simple.
generate_random_suffix() {
    # Use /dev/urandom to generate random bytes, convert to hex, take first 6 chars
    # Fallback to openssl if /dev/urandom is not available
    if [[ -r /dev/urandom ]]; then
        LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 6
    else
        openssl rand -hex 3
    fi
}

# Check if a dummy project name collides with an existing local directory
# Returns 0 if collision exists, 1 if name is unique
check_local_collision() {
    local name="$1"
    
    if [[ -z "${dummy_parent_directory}" ]]; then
        echo "Error: dummy_parent_directory is not set in tests.cfg" >&2
        return 2
    fi
    
    if [[ -d "${dummy_parent_directory}/${name}" ]]; then
        return 0  # Collision exists
    else
        return 1  # Name is unique
    fi
}

# Main function to generate a unique dummy repository name
# Tries up to MAX_ATTEMPTS different values before giving up.
main() {
    local attempt=0
    local dummy_name
    local suffix
    
    while [[ $attempt -lt $MAX_ATTEMPTS ]]; do
        attempt=$((attempt + 1))
        
        # Generate random suffix and construct dummy name
        suffix=$(generate_random_suffix)
        dummy_name="dummy${suffix}"
        
        # Check for local collision
        if check_local_collision "$dummy_name"; then
            # Collision detected, try again
            continue
        else
            # Unique name found, output and exit
            echo "$dummy_name"
            return 0
        fi
    done
    
    # Failed to generate unique name after max attempts
    echo "Error: Unable to generate unique dummy name after ${MAX_ATTEMPTS} attempts" >&2
    return 1
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
