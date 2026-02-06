#!/bin/bash
# PURPOSE: tests/test_delete_online_repo_gitlab_force.sh - Delete online GitLab repo using -K hard delete flag
# This script focuses on the hard delete (-K) flow and immediate permanent removal.

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

    echo "Case05-force:"
    echo "Delete online GitLab repo using -K (hard delete, immediate permanent removal)."

    cd "${dummy_parent_directory}"

    # First create a temporary dummy project that will later be deleted with -K
    echo "Creating dummy project '${dummy_project}' for -K (force) deletion test..."
    "${gitremoteforge_dev_script_path}" -d "${dummy_project}" -n "${dummy_username}" -f || \
        echo "Warning: repository setup reported errors; continuing with force delete test."

    cd "${dummy_project}"
    echo "Local repo path: $(pwd)"
    git remote -v

    # Resolve the GitLab project id to make it visible in the test output
    project_id="$("${gitremoteforge_dev_script_path}" -W)"
    echo "Resolved GitLab project id for hard delete: ${project_id}"

    echo "Testing -K (force) deletion with autodetected namespace/repo from git remote and forced confirmations (-F)..."
    "${gitremoteforge_dev_script_path}" -K -F

    cd "${dummy_parent_directory}"
    echo "Cleaning up local test repo: ${dummy_parent_directory}/${dummy_project}"
    rm -rf "${dummy_parent_directory:?}/${dummy_project}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

