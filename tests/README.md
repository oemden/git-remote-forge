# Tests

Basic manual test scripts are provided for git-remote-forge.

- `tests.sh`: main test orchestrator
- `tests.cfg`: shared configuration for all test scripts
- `test_new_repo.sh`: new repo from new non-existing directory
- `test_existing_dir_nongit.sh`: existing non-git directory
- `test_existing_git_repo.sh`: existing git-initiated directory
- `test_destructive_reset.sh`: destructive reset scenario using `-O` (guarded by `DESTRUCTIVE_TESTS=1`)

## tests.cfg

`tests.cfg` is a simple shell file sourced by all test scripts. It defines:

- `dummy_project_1`..`dummy_project_4`: dummy project directory names created under `dummy_parent_directory`
- `dummy_username`: namespace used on the provider, usually taken from `GITREMOTE_FORGE_NAMESPACE_DUMMY`
- `dummy_technologies`: example technologies list (not required by core tests)
- `dummy_branche_1`, `dummy_branche_2`: branch names used in some scenarios
- `dummy_origin_01`, `dummy_origin_02`: remote names used in tests
- `dummy_parent_directory`: base directory where dummy projects are created
- `gitremoteforge_dev_script_path`: resolved path to `gitremote.sh` used by the test scripts

You can adjust these values to point to your own dummy workspace or namespace before running the tests.
