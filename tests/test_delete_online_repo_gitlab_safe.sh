#!/bin/bash
# PURPOSE: tests/test_delete_online_repo_gitlab_safe.sh - Delete online GitLab repo using -k safe delete flag
# This script focuses on the safe delete (-k) flow and scheduled deletion tracking.

version="0.10.1"

set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

main() {
    # Accept optional dummy project name argument, generate one if not provided
    if [[ -n "$1" ]]; then
        dummy_project="$1"
    else
        dummy_project=$("${SCRIPT_DIR}/generate_dummy_repo_name.sh")
    fi

    echo "Case05-safe:"
    echo "Delete online GitLab repo using -k (safe delete)."

    cd "${dummy_parent_directory}"

    # First create a temporary dummy project that will later be deleted with -k
    echo "Creating dummy project '${dummy_project}' for -k (safe) deletion test..."
    "${gitremoteforge_dev_script_path}" -d "${dummy_project}" -n "${dummy_username}" -f -i || \
        echo "Warning: repository setup reported errors; continuing with safe delete test."

    cd "${dummy_project}"
    echo "Local repo path: $(pwd)"
    git remote -v

    # Resolve the GitLab project id to make it visible in the test output
    project_id="$("${gitremoteforge_dev_script_path}" -W)"
    echo "Resolved GitLab project id for safe delete: ${project_id}"

    echo "Testing -k (safe) deletion with explicit namespace and forced confirmations (-F)..."
    "${gitremoteforge_dev_script_path}" -k -n "${dummy_username}" -F

    cd "${dummy_parent_directory}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

