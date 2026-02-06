#!/bin/bash
# PURPOSE: tests/test_destructive_reset.sh - Destructive reset of existing git repository using -O flag

version="0.10.1"

# Test scenario: destructive reset of an existing git repository using -O.
# Mirrors original Case04 behavior from tests.sh and adds an explicit safety guard.

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

    echo "Case04:"
    echo "Create online repo ${dummy_project} from existing git initiated Local directory \`-p\` ${dummy_project} with \`-r\` ${dummy_origin_01} and .gitignore file \`-i\` basic std gitignore and git RESET to Virgin git repo - DESTRUCTIVE Test with \`-O\` and autoapprove \`-f\` (should prompt user 2 times to confirm destructive operation)"

    # Extra safety: require DESTRUCTIVE_TESTS=1 to allow running this scenario
    if [[ "${DESTRUCTIVE_TESTS}" != "1" ]]; then
        echo "DESTRUCTIVE_TESTS is not set to 1, skipping destructive reset test to avoid unintended data loss."
        exit 0
    fi

    cd "${dummy_parent_directory}"
    "${gitremoteforge_dev_script_path}" -p "${dummy_parent_directory}/${dummy_project}" -n "${GITREMOTE_FORGE_NAMESPACE_DUMMY}" -r "${dummy_origin_01}" -i -O -f

    cd "${dummy_project}"
    git remote -v

    cd "${dummy_parent_directory}"
    sleep 2
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

