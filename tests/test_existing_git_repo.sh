#!/bin/bash

# Test scenario: create online repo from an existing git-initiated local directory.
# Mirrors original Case03 behavior from tests.sh.

set -e
set -x

# Resolve script directory and source shared test configuration.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

main() {
    echo "Case03:"
    echo "Create online repo ${dummy_project_3} from existing git initiated Local directory \`-p\` ${dummy_project_3} with \`-r\` ${dummy_origin_01} and existing .gitignore file \`-i\` basic std gitignore and auto approve \`-f\`"

    cd "${dummy_parent_directory}"
    "${gitremoteforge_dev_script_path}" -p "${dummy_project_3}" -n "${GITREMOTE_FORGE_NAMESPACE_DUMMY}" -r "${dummy_origin_01}" -i -f

    cd "${dummy_project_3}"
    git remote -v

    cd "${dummy_parent_directory}"
    sleep 5
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

