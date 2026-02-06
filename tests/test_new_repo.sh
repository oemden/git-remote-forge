#!/bin/bash
# PURPOSE: tests/test_new_repo.sh - Create online repo from new non-existing local directory

version="0.10.1"

# Test scenario: create online repo from a new non-existing local directory.
# Mirrors original Case01 behavior from tests.sh and uses a dummy* project name.

set -e
set -x

# Resolve script directory and source shared test configuration.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

main() {
    # Accept optional dummy project name argument, generate one if not provided
    if [[ -n "$1" ]]; then
        dummy_project="$1"
    else
        dummy_project=$("${SCRIPT_DIR}/generate_dummy_repo_name.sh")
    fi

    echo "Case01:"
    echo "Create online repo ${dummy_project} and new non existing Local directory ${dummy_project} in ${dummy_parent_directory} with \`-i\` basic std .gitignore and checkout to \`-b\` production branch"

    cd "${dummy_parent_directory}"
    # Use -d to create a new directory and -b to switch to production branch
    "${gitremoteforge_dev_script_path}" -d "${dummy_project}" -n "${GITREMOTE_FORGE_NAMESPACE_DUMMY}" -b production -f

    cd "${dummy_project}"
    git remote -v

    cd "${dummy_parent_directory}"
    sleep 2
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

