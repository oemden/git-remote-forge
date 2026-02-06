#!/bin/bash

version="0.10.0"

set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "${SCRIPT_DIR}/tests.cfg"

main() {
    echo "Case05-safe:"
    echo "Delete online GitLab repo using -k (safe delete)."

    cd "${dummy_parent_directory}"

    echo "Creating dummy project '${dummy_project_4}' for -k (safe) deletion test..."
    "${gitremoteforge_dev_script_path}" -d "${dummy_project_4}" -n "${dummy_username}" -f -i || \
        echo "Warning: repository setup reported errors; continuing with safe delete test."

    cd "${dummy_project_4}"
    echo "Local repo path: $(pwd)"
    git remote -v

    project_id="$("${gitremoteforge_dev_script_path}" -W)"
    echo "Resolved GitLab project id for safe delete: ${project_id}"

    echo "Testing -k (safe) deletion with explicit namespace and forced confirmations (-F)..."
    "${gitremoteforge_dev_script_path}" -k -n "${dummy_username}" -F

    cd "${dummy_parent_directory}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

