#!/bin/bash
# PURPOSE: tests/test_cleanup_dummy_repos.sh - Clean up all existing dummy test repositories (remote + local)
# High-level flow:
#   1) Discover dummy* directories under dummy_parent_directory
#   2) Verify which ones are valid git repos with a live origin remote
#   3) Delete matching remote projects using gitremote.sh -K -F
#   4) Remove local directories and print a summary report

version="0.10.1"

set -e

# Resolve script directory and source shared test configuration
# tests.cfg provides dummy_parent_directory, dummy_username and gitremoteforge_dev_script_path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

# Counters used to build the final summary output
total_found=0
total_processed=0
total_skipped=0
total_failed=0

# Discover all dummy* directories in parent directory
# This function prints human readable information to stderr and the list of
# repository names (one per line) to stdout so callers can safely capture it.
discover_dummy_repos() {
    echo "==========================================" >&2
    echo "DISCOVERY PHASE" >&2
    echo "==========================================" >&2
    echo "Scanning directory: ${dummy_parent_directory}" >&2
    echo "" >&2
    
    if [[ ! -d "${dummy_parent_directory}" ]]; then
        echo "ERROR: dummy_parent_directory does not exist: ${dummy_parent_directory}" >&2
        exit 1
    fi
    
    # Find all dummy* directories
    local repos=()
    while IFS= read -r -d '' dir; do
        local basename=$(basename "$dir")
        repos+=("$basename")
    done < <(find "${dummy_parent_directory}" -maxdepth 1 -type d -name "dummy*" -print0 2>/dev/null)
    
    total_found=${#repos[@]}
    
    if [[ $total_found -eq 0 ]]; then
        echo "No dummy repositories found." >&2
        exit 0
    fi
    
    echo "Found ${total_found} dummy repositor(y/ies):" >&2
    for repo in "${repos[@]}"; do
        echo "  - ${repo}" >&2
    done
    echo "" >&2
    
    # Return the array via stdout (one per line)
    printf '%s\n' "${repos[@]}"
}

# Check if directory is a valid git repo with live remote (Phase 1 criteria)
# Only repositories that pass this check will be considered for cleanup.
verify_repo() {
    local repo_path="$1"
    local repo_name="$2"
    
    echo "Verifying ${repo_name}..."
    
    # Check .git exists
    if [[ ! -d "${repo_path}/.git" ]]; then
        echo "  SKIP: Not a git repository"
        return 1
    fi
    
    # Check origin remote exists
    if ! git -C "${repo_path}" remote get-url origin >/dev/null 2>&1; then
        echo "  SKIP: No origin remote configured"
        return 1
    fi
    
    # Check for scheduled deletion in marker file
    if [[ -f "${repo_path}/.repo_initiated_by_gitremoteforge" ]]; then
        if grep -q "scheduled.*deletion" "${repo_path}/.repo_initiated_by_gitremoteforge" 2>/dev/null; then
            echo "  SKIP: Scheduled deletion found in marker file"
            return 1
        fi
    fi
    
    echo "  VALID: Ready for cleanup"
    return 0
}

# Delete a single repository (both remote project and local directory)
# Assumes verify_repo has already been called and returned success.
delete_repo() {
    local repo_name="$1"
    local repo_path="${dummy_parent_directory}/${repo_name}"
    
    echo ""
    echo "Processing ${repo_name}..."
    echo "----------------------------------------"
    
    # Change to repo directory
    cd "${repo_path}" || {
        echo "  ERROR: Cannot cd into ${repo_path}"
        return 1
    }
    
    # Get and display GitLab project ID
    echo "Getting project ID for ${repo_name}..."
    local project_id
    if ! project_id=$("${gitremoteforge_dev_script_path}" -W 2>&1); then
        echo "  ERROR: Failed to get project ID"
        echo "  Output: ${project_id}"
        cd "${dummy_parent_directory}"
        return 1
    fi
    echo "Resolved GitLab project ID: ${project_id}"
    
    # Call gitremote.sh directly with -K -F flags
    echo "Deleting remote repo for ${repo_name}..."
    if ! "${gitremoteforge_dev_script_path}" -K -F 2>&1; then
        echo "  ERROR: Failed to delete remote repository"
        cd "${dummy_parent_directory}"
        return 1
    fi
    
    # Remove local directory
    cd "${dummy_parent_directory}" || {
        echo "  ERROR: Cannot return to parent directory"
        return 1
    }
    
    echo "Removing local directory: ${repo_path}"
    if ! rm -rf "${repo_path}"; then
        echo "  ERROR: Failed to remove local directory"
        return 1
    fi
    
    echo "SUCCESS: ${repo_name} deleted (remote + local)"
    return 0
}

# Main cleanup orchestrator
# Coordinates discovery, verification, deletion and final reporting.
main() {
    echo "=========================================="
    echo "Git Remote Forge - Cleanup Test Script"
    echo "Version: ${version}"
    echo "=========================================="
    echo ""
    
    # Safety checks to ensure configuration is present before doing anything destructive
    if [[ -z "${dummy_parent_directory}" ]]; then
        echo "ERROR: dummy_parent_directory is not set in tests.cfg"
        echo "Please set GITREMOTE_FORGE_DUMMY_PARENT_DIRECTORY environment variable"
        exit 1
    fi
    
    if [[ -z "${dummy_username}" ]]; then
        echo "ERROR: dummy_username is not set in tests.cfg"
        echo "Please set GITREMOTE_FORGE_NAMESPACE_DUMMY environment variable"
        exit 1
    fi
    
    if [[ -z "${gitremoteforge_dev_script_path}" ]]; then
        echo "ERROR: gitremoteforge_dev_script_path is not set in tests.cfg"
        exit 1
    fi
    
    if [[ ! -x "${gitremoteforge_dev_script_path}" ]]; then
        echo "ERROR: gitremote.sh script not found or not executable: ${gitremoteforge_dev_script_path}"
        exit 1
    fi
    
    # Discovery phase: collect raw list of dummy* directory names
    local repos=()
    while IFS= read -r repo; do
        [[ -n "$repo" ]] && repos+=("$repo")
    done < <(discover_dummy_repos)
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        exit 0
    fi
    
    echo "=========================================="
    echo "VERIFICATION PHASE"
    echo "=========================================="
    echo ""
    
    # Verification phase - collect only repositories that match Phase 1 rules
    local valid_repos=()
    for repo in "${repos[@]}"; do
        local repo_path="${dummy_parent_directory}/${repo}"
        if verify_repo "${repo_path}" "${repo}"; then
            valid_repos+=("${repo}")
        else
            ((total_skipped++))
        fi
        echo ""
    done
    
    if [[ ${#valid_repos[@]} -eq 0 ]]; then
        echo "No valid repositories to clean up."
        echo ""
        print_summary
        exit 0
    fi
    
    echo "=========================================="
    echo "DELETION PHASE"
    echo "=========================================="
    echo "Processing ${#valid_repos[@]} valid repositor(y/ies)..."
    echo ""
    
    # Deletion phase - attempt remote + local cleanup for each validated repository
    for repo in "${valid_repos[@]}"; do
        if delete_repo "${repo}"; then
            ((total_processed++))
        else
            ((total_failed++))
        fi
        echo ""
    done
    
    echo "=========================================="
    echo "CLEANUP COMPLETE"
    echo "=========================================="
    print_summary
}

# Print summary statistics for the whole cleanup run
print_summary() {
    echo ""
    echo "Summary:"
    echo "  Total repos found:      ${total_found}"
    echo "  Successfully deleted:   ${total_processed}"
    echo "  Skipped:                ${total_skipped}"
    echo "  Failed:                 ${total_failed}"
    echo ""
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
