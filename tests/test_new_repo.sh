#!/bin/bash

version="0.10.0"

# Test scenario: create online repo from a new non-existing local directory.
# Mirrors original Case01 behavior from tests.sh.

set -e
set -x

# Resolve script directory and source shared test configuration.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

main() {
    echo "Case01:"
    echo "Create online repo ${dummy_project_1} and new non existing Local directory ${dummy_project_1} in ${dummy_parent_directory} with \`-i\` basic std .gitignore and checkout to \`-b\` production branch"

    cd "${dummy_parent_directory}"
    "${gitremoteforge_dev_script_path}" -d "${dummy_project_1}" -n "${GITREMOTE_FORGE_NAMESPACE_DUMMY}" -b production -f

    cd "${dummy_project_1}"
    git remote -v

    cd "${dummy_parent_directory}"
    sleep 5
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

