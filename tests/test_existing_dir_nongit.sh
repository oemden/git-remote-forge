#!/bin/bash
# PURPOSE: tests/test_existing_dir_nongit.sh - Create online repo from existing non-git local directory

version="0.10.1"

# Test scenario: create online repo from an existing non-git local directory.
# Mirrors original Case02 behavior from tests.sh and reuses an existing folder.

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

    echo "Case02:"
    echo "Create online repo ${dummy_project} from existing non git initiated Local directory \`-p\` ${dummy_project} with \`-r\` ${dummy_origin_02} and no .gitignore file \`-i\` basic std gitignore"

    cd "${dummy_parent_directory}"
    "${gitremoteforge_dev_script_path}" -p "${dummy_project}" -n "${GITREMOTE_FORGE_NAMESPACE_DUMMY}" -r "${dummy_origin_02}" -i -f

    cd "${dummy_project}"
    git remote -v

    cd "${dummy_parent_directory}"
    sleep 2
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

