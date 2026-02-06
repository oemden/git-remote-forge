#!/bin/bash

version="0.10.0"

set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

main() {
    echo "Case05-force:"
    echo "Delete online GitLab repo using -K (hard delete, immediate permanent removal)."

    cd "${dummy_parent_directory}"

    echo "Creating dummy project '${dummy_project_5}' for -K (force) deletion test..."
    "${gitremoteforge_dev_script_path}" -d "${dummy_project_5}" -n "${dummy_username}" -f || \
        echo "Warning: repository setup reported errors; continuing with force delete test."

    cd "${dummy_project_5}"
    echo "Local repo path: $(pwd)"
    git remote -v

    project_id="$("${gitremoteforge_dev_script_path}" -W)"
    echo "Resolved GitLab project id for hard delete: ${project_id}"

    echo "Testing -K (force) deletion with autodetected namespace/repo from git remote and forced confirmations (-F)..."
    "${gitremoteforge_dev_script_path}" -K -F

    cd "${dummy_parent_directory}"
    echo "Cleaning up local test repo: ${dummy_parent_directory}/${dummy_project_5}"
    rm -rf "${dummy_parent_directory:?}/${dummy_project_5}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

