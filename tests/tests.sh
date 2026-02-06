#!/bin/bash
# PURPOSE: tests/tests.sh - Main orchestrator for git-remote-forge test scenarios
# gitremoteforge_dev.sh
# Orchestrator for git-remote-forge basic test scenarios.

version="0.10.1"

set -e
set -x

# Resolve script directory and source shared test configuration.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

usage() {
    # Print a short usage help message describing available test cases
    cat <<EOF
Usage: $0 [options]

Run git-remote-forge basic test scenarios.

Options:
  -1        Run Case01: new repo from new directory (test_new_repo.sh)
  -2        Run Case02: existing non-git directory (test_existing_dir_nongit.sh)
  -3        Run Case03: existing git directory (test_existing_git_repo.sh)
  -4        Run Case04: destructive reset (test_destructive_reset.sh)
  -5        Run Case05: delete online GitLab repo (-k / -K) (test_delete_online_repo_gitlab.sh)
  -c        Run Cleanup: clean up all existing dummy repos (test_cleanup_dummy_repos.sh)
  -a        Run all non-destructive tests (1, 2, 3, 5)
  -A        Run all tests including destructive (requires DESTRUCTIVE_TESTS=1)
  -h        Show this help message
EOF
}

run_case1() {
    # Case01: new repo from a new non-existing directory
    bash "${SCRIPT_DIR}/test_new_repo.sh"
}

run_case2() {
    # Case02: existing non-git directory (no .git yet)
    bash "${SCRIPT_DIR}/test_existing_dir_nongit.sh"
}

run_case3() {
    # Case03: existing git-initiated directory
    bash "${SCRIPT_DIR}/test_existing_git_repo.sh"
}

run_case4() {
    # Case04: destructive reset scenario guarded by DESTRUCTIVE_TESTS
    bash "${SCRIPT_DIR}/test_destructive_reset.sh"
}

run_case5() {
    # Case05: GitLab deletion flows (-k then -K)
    bash "${SCRIPT_DIR}/test_delete_online_repo_gitlab.sh"
}

run_cleanup() {
    # Cleanup: remove existing dummy test repositories (remote + local)
    bash "${SCRIPT_DIR}/test_cleanup_dummy_repos.sh"
}

parse_arguments() {
    # Parse short flags and dispatch the correct test scenario
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    while getopts "12345caAh" opt; do
        case ${opt} in
            1 )
                echo "Running Case01 (new repo from new directory)"
                run_case1
                ;;
            2 )
                echo "Running Case02 (existing non-git directory)"
                run_case2
                ;;
            3 )
                echo "Running Case03 (existing git directory)"
                run_case3
                ;;
            4 )
                echo "Running Case04 (destructive reset)"
                run_case4
                ;;
            5 )
                echo "Running Case05 (delete online GitLab repo with -k / -K)"
                run_case5
                ;;
            c )
                echo "Running Cleanup (clean up all existing dummy repos)"
                run_cleanup
                ;;
            a )
                echo "Running all non-destructive tests (1, 2, 3, 5)"
                run_case1
                run_case2
                run_case3
                run_case5
                ;;
            A )
                echo "Running all tests including destructive (requires DESTRUCTIVE_TESTS=1)"
                run_case1
                run_case2
                run_case3
                run_case4
                ;;
            h )
                usage
                exit 0
                ;;
            \? )
                echo "Invalid option: -$OPTARG"
                usage
                exit 1
                ;;
        esac
    done
}

main() {
    parse_arguments "$@"
}

main "$@"
