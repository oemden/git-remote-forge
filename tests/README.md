# Tests

Basic manual test scripts are provided for git-remote-forge.

- `tests.sh`: main test orchestrator
- `tests.cfg`: shared configuration for all test scripts
- `generate_dummy_repo_name.sh`: random dummy name generator with collision detection
- `test_new_repo.sh`: new repo from new non-existing directory
- `test_existing_dir_nongit.sh`: existing non-git directory
- `test_existing_git_repo.sh`: existing git-initiated directory
- `test_destructive_reset.sh`: destructive reset scenario using `-O` (guarded by `DESTRUCTIVE_TESTS=1`)
- `test_delete_online_repo_gitlab_safe.sh`: GitLab safe deletion using `-k` flag
- `test_delete_online_repo_gitlab_force.sh`: GitLab force deletion using `-K` flag
- `test_delete_online_repo_gitlab.sh`: orchestrator for GitLab deletion tests
- `test_cleanup_dummy_repos.sh`: automated cleanup utility for all existing dummy repos

## Dynamic Dummy Name Generation

Test scripts now use dynamically generated random dummy repository names to avoid collisions and improve test isolation.

### generate_dummy_repo_name.sh

This helper script generates unique dummy repository names in the format `dummy<6-char-hex>` (e.g., `dummy7a3f8c`, `dummyb4e2d1`).

**Features:**

- Uses `/dev/urandom` or `openssl` for random hex generation
- Checks for local directory collisions in `$dummy_parent_directory`
- Retry logic with max 10 attempts to find a unique name
- Exits with error if unable to generate unique name after max attempts

**Usage:**

```bash
# Generate a random unique dummy name
dummy_name=$(./generate_dummy_repo_name.sh)
echo $dummy_name
# Output: dummy7a3f8c
```

### Passing Custom Dummy Names

Each test script accepts an optional dummy name argument:

```bash
# Run with generated name
./test_new_repo.sh

# Run with custom name
./test_new_repo.sh my_custom_dummy_name
```

This is useful for debugging specific scenarios or reusing test repositories.

## tests.cfg

`tests.cfg` is a simple shell file sourced by all test scripts. It defines:

- `dummy_username`: namespace used on the provider, usually taken from `GITREMOTE_FORGE_NAMESPACE_DUMMY`
- `dummy_technologies`: example technologies list (not required by core tests)
- `dummy_branche_1`, `dummy_branche_2`: branch names used in some scenarios
- `dummy_origin_01`, `dummy_origin_02`: remote names used in tests
- `dummy_parent_directory`: base directory where dummy projects are created
- `gitremoteforge_dev_script_path`: resolved path to `gitremote.sh` used by the test scripts

**Note:** Hardcoded dummy project names have been removed. Each test now generates its own unique name via `generate_dummy_repo_name.sh`.

You can adjust these values to point to your own dummy workspace or namespace before running the tests.

## Benefits of Dynamic Names

- **No name conflicts:** Each test run generates unique repository names
- **Parallel testing:** Tests can run concurrently without collision
- **Maintainability:** No need to manually manage dummy name assignments
- **Flexibility:** Can still pass custom names for debugging
- **Cleanup-friendly:** Easy to identify and clean up dummy repos by `dummy*` prefix

## Cleanup Test Utility

### test_cleanup_dummy_repos.sh

Automated cleanup utility that discovers and deletes all existing dummy test repositories (both remote and local).

**Purpose:** Clean up leftover test repositories after testing sessions to avoid clutter and maintain a clean test environment.

**Phase 1 Scope - Only processes repositories that:**

- Have a valid `.git` directory
- Have an `origin` remote configured
- Are NOT scheduled for soft deletion (no deletion marker in `.repo_initiated_by_gitremoteforge`)
- Have a remote that exists online (not already deleted)

**Process Flow:**

1. **Discovery Phase**
   - Scans `$dummy_parent_directory` for all `dummy*` directories
   - Lists all found repositories

2. **Verification Phase**
   - Checks if directory is a git repository
   - Verifies origin remote exists
   - Checks for scheduled deletion markers in `.repo_initiated_by_gitremoteforge`
   - Reports skipped repositories with reasons

3. **Deletion Phase**
   - For each valid repository:
     - Retrieves GitLab project ID using `gitremote.sh -W`
     - Deletes remote repository using `gitremote.sh -K -F` (force delete with auto-confirm)
     - Removes local directory
   - Continues processing even if individual deletions fail

4. **Summary Phase**
   - Reports total repositories found
   - Reports successfully deleted
   - Reports skipped (no remote, scheduled deletion, not a git repo)
   - Reports failures

**Usage:**

```bash
# Run cleanup directly
./test_cleanup_dummy_repos.sh

# Run via main orchestrator
./tests.sh -c
```

**Safety Features:**

- Validates all required environment variables before proceeding
- Only processes directories matching `dummy*` pattern
- Skips repos without remotes (prevents errors)
- Skips repos with scheduled soft deletions (prevents duplicate deletion attempts)
- Provides detailed status messages for each repository
- Continues processing if individual deletions fail

**When to Use:**

- After running multiple test sessions
- Before starting fresh test runs
- When `$dummy_parent_directory` has accumulated test repositories
- To clean up orphaned test repositories

**Example Output:**

```bash
==========================================
Git Remote Forge - Cleanup Test Script
Version: 0.10.1
==========================================

==========================================
DISCOVERY PHASE
==========================================
Scanning directory: /tmp/gitremote_test

Found 3 dummy repositor(y/ies):
  - dummy929acd
  - dummy7a3f8c
  - dummyb4e2d1

==========================================
VERIFICATION PHASE
==========================================

Verifying dummy929acd...
  VALID: Ready for cleanup

Verifying dummy7a3f8c...
  SKIP: No origin remote configured

Verifying dummyb4e2d1...
  SKIP: Scheduled deletion found in marker file

==========================================
DELETION PHASE
==========================================
Processing 1 valid repositor(y/ies)...

Processing dummy929acd...
----------------------------------------
Getting project ID for dummy929acd...
Resolved GitLab project ID: 12345678
Deleting remote repo for dummy929acd...
Removing local directory: /tmp/gitremote_test/dummy929acd
SUCCESS: dummy929acd deleted (remote + local)

==========================================
CLEANUP COMPLETE
==========================================

Summary:
  Total repos found:      3
  Successfully deleted:   1
  Skipped:                2
  Failed:                 0
```
