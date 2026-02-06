#!/bin/bash
# PURPOSE: tests/test_delete_online_repo_gitlab.sh - Orchestrator for GitLab deletion tests (safe and force)
# High-level wrapper that runs both the -k (safe) and -K (force) deletion scenarios.

version="0.10.1"

# Test scenario: delete online GitLab repo from an existing local repository.
# Exercises:
#   - -k safe deletion flow (single confirmation, scheduled delete)
#   - -K force deletion flow (two-step confirmation, immediate delete attempt)
#   - Autodetection of namespace/repo from git remote when -n/-d are omitted
#
# NOTE:
# - This script assumes a valid GitLab access token is already exported
#   (e.g. GITREMOTE_FORGE_GITLAB_TOKEN or GITLAB_ACCESS_TOKEN).
# - It also assumes that the dummy namespace can create and delete projects.

set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

main() {
    echo "Case05:"
    echo "Delete online GitLab repo using -k (safe) and -K (force) flows."

    bash "${SCRIPT_DIR}/test_delete_online_repo_gitlab_safe.sh"
    bash "${SCRIPT_DIR}/test_delete_online_repo_gitlab_force.sh"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

