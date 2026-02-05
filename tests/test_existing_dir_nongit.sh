#!/bin/bash

# Test scenario: create online repo from an existing non-git local directory.
# Mirrors original Case02 behavior from tests.sh.

set -e
set -x

# Resolve script directory and source shared test configuration.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

main() {
    echo "Case02:"
    echo "Create online repo ${dummy_project_2} from existing non git initiated Local directory \`-p\` ${dummy_project_2} with \`-r\` ${dummy_origin_02} and no .gitignore file \`-i\` basic std gitignore"

    cd "${dummy_parent_directory}"
    "${gitremoteforge_dev_script_path}" -p "${dummy_project_2}" -n "${GITREMOTE_FORGE_NAMESPACE_DUMMY}" -r "${dummy_origin_02}" -i -f

    cd "${dummy_project_2}"
    git remote -v

    cd "${dummy_parent_directory}"
    sleep 5
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

