# Changelog

All notable changes to git-remote-forge are documented here.

## [0.10.1] - 2026-02-06

### Added

- Dynamic dummy repository names for test scripts via `tests/generate_dummy_repo_name.sh`, removing hard-coded project names from `tests/tests.cfg`
- New cleanup utility `tests/test_cleanup_dummy_repos.sh` to discover and delete dummy test repositories both remotely (GitLab) and locally
- `-c` flag in `tests/tests.sh` to run the cleanup utility from the main test orchestrator

### Changed

- Updated existing test scripts to accept an optional dummy project name argument and fall back to generated names when not provided
- Improved test script documentation with concise PURPOSE headers and inline comments to clarify each scenario and safety guard

---

## [0.10.0] - 2026-02-06

### Added

- `-k` soft delete flow for GitLab remote repositories, including tracking of original and scheduled-deletion remote URLs in `.repo_initiated_by_gitremoteforge`
- `-K` hard delete flow for GitLab, built on top of `-k` and issuing a best-effort immediate permanent deletion request using the GitLab Projects API
- `-W` helper flag to resolve and print the current GitLab project ID from the configured git remote
- `-F` flag to force remote delete confirmations for `-k` / `-K`, enabling non-interactive usage in CI/CD and automated tests
- Dedicated test scripts `tests/test_delete_online_repo_gitlab_safe.sh` and `tests/test_delete_online_repo_gitlab_force.sh` for safe and hard delete scenarios

### Changed

- Refined `.repo_initiated_by_gitremoteforge` to record both scheduled and completed remote deletions for GitLab projects
- Improved remote deletion messaging and safety checks, including a follow-up verification call for hard deletes

---

## [0.9.8] - 2026-02-05

### Added

- Basic manual test scripts in `tests/` covering core scenarios (new repo, existing non-git dir, existing git repo, destructive reset)
- Shared `tests/tests.cfg` configuration file to centralize dummy project names, paths, and script location
- `tests/README.md` with short documentation of the test layout and `tests.cfg`

---

## [0.9.7] - 2026-01-XX

### Added

- `-P` flag for provider selection (gitlab|github|bitbucket|gitea, default: gitlab)
- Provider validation with error handling for invalid provider values
- Case-insensitive provider value matching

### Changed

- Provider option now accepts command-line argument (prepares for multi-provider support)
- Default provider remains GitLab when `-P` is not specified

### Note

- Currently only GitLab provider is fully functional
- GitHub, Bitbucket, and Gitea providers are in development

---

## [0.9.6] - 2026-01-XX

### Fixed

- No arguments now displays help/usage message instead of prompting to create repository
- `gitremote.sh` (no args) now behaves the same as `gitremote.sh -h`

---

## [0.9.5] - 2026-01-16

### Added

- `-R` flag for replacing/renaming remotes with same URL
- URL duplicate detection to prevent multiple remotes with same URL
- Helper functions: `check_remote_url_exists()`, `get_remote_url()`, `prompt_replace_remote()`
- User prompts for replace/keep/abort when remote URL differs

### Fixed

- Prevent `-r` flag from creating duplicate remotes with same URL
- Clearer error messages with options including `-R` flag usage

### Changed

- Updated documentation with new use cases and examples for remote management

---

## [0.9.4] - 2026-01-16

### Added

- `-i` flag to create basic .gitignore file with default patterns (.*env, !.env.example, .repo_initiated_by_gitremoteforge)
- `-O` flag to override existing .git directory (removes and reinitializes)
- Repository marker file `.repo_initiated_by_gitremoteforge` with version tracking
- Two-step confirmation for destructive .git removal (even with `-f` flag)

### Changed

- Enhanced remote conflict handling with clearer messaging

---

## [0.9.3] - 2026-01-15

### Fixed

- Git init flow: create .git folder only after user approval or `-f` flag
- Prevents .git creation before preview and confirmation

---

## [0.9.2] - 2026-01-15

### Added

- `-r` flag for custom remote names (default: origin)
- Default current directory behavior when no `-d` or `-p` provided
- Comprehensive code comments throughout script

### Fixed

- `normalize_path()` macOS compatibility (realpath doesn't support `-m` flag)
- Path existence check before calling realpath on macOS

### Changed

- Changed branch checkout flag from `-B` to `-b`
- Updated README with comprehensive use cases and examples

---

## [0.9.1] - 2025-11-29

### Fixed

- Support absolute paths in `-d` parameter (fixes double-path bug)
- Extract basename from full paths for cleaner project name display
- Early abort on first fatal push error (don't continue to next branch)
- Better error messages with "aborting" feedback

### Changed

- Improved directory output: display name, parent path, and status separately
- Clearer push error feedback per branch with immediate abort

### Known Issues (backlog Phase 3)

- Remote URL configured but online repo doesn't exist (needs provider API validation)

---

## [0.9.0] - 2025-11-29

### Added

- `local_directory()` function - manages directory creation/detection
- `manage_git()` function - detects or initializes git repositories
- `has_branches()` function - checks if repo has any commits/branches
- Smart repo initialization: creates new if empty `.git`, uses existing if branches found
- Early directory/git validation before provider setup
- Support for empty `git init` repos (treats as new)
- Scenario-based remote conflict messaging (multiple/single/none remotes)

### Changed

- Refactored `create_local_repo()` - now only handles README + commit (no mkdir)
- Refactored `main()` workflow into 5 clear steps: dir → git → provider → create → push
- `push_to_remote()` now handles both new repos (create branches) and existing (push all)
- Early detection approach: validates dir/git before user interaction

### Fixed

- No more "directory exists" errors when using empty `.git` repos
- Handles existing repos without destroying branch structure
- Safe approach: detects state, never modifies without explicit flow

### Architecture Changes

- Separation of concerns: directory management vs git management
- `IS_EXISTING_REPO` flag now accurately reflects branch existence, not just `.git` presence
- LocalTarget path exported from `local_directory()` for downstream functions

---

## [0.8] - 2025-11-29

### Added

- `-n, --namespace` parameter for provider target (replaces interactive prompt)
- `-t` flag for auto-detect technologies (existing directory mode only)
- `-T, --tech` parameter for user-provided technologies
- `-R, --repo` parameter for provider selection (gitlab|github|bitbucket|gitea)
- `-S, --self-hosted` parameter for custom domain support (self-hosted instances)
- `-p, --path` parameter for existing directory mode
- `setup_provider()` router function for provider-agnostic setup
- `handle_gitea_setup()` adapter for Gitea support
- Gitea provider support (functional parity with GitLab)
- Multi-provider architecture documentation

### Changed

- Renamed `-t` (old target param) to `-n` (namespace) for clarity
- Removed `-e` flag; auto-detect existing .git directory instead
- Renamed `push_to_gitlab()` → `push_to_remote()` (provider-agnostic)
- Updated help text with usage modes and examples

### Fixed

- Parameter handling for multi-provider setup
- Technology output in README now respects `-T` parameter

---

## [0.7.1] - 2025-11-29

### Added

- Provider abstraction architecture (ARCHITECTURE.md)
- `handle_gitlab_setup()` adapter function for GitLab-specific logic
- StandardConfig structure documentation for multi-provider support
- `get_tech_from_extension()` helper function (bash 3.x compatible)

### Fixed

- Bash 3.x compatibility: replaced `declare -A` (associative arrays) with case statements
- Bash 3.x compatibility: replaced parameter expansion `${ext,,}` with `tr` for lowercase conversion
- Technology detection function now works on macOS with bash 3.x

### Changed

- Refactored technology detection logic into provider-agnostic functions

---

## [0.7] - Initial Release

### Features

- Local repository creation with three-branch model (main, production, develop)
- GitLab remote integration via SSH
- Git user information auto-detection
- Optional technology specification or auto-detection
- Dry-run preview mode with confirmation
- Force mode for automation
- Ability to run script from anywhere

### Known Limitations

- GitLab only (GitHub and Bitbucket support planned)
- Interactive namespace prompt only (parameter support in v0.8)
- Bash 4+ required initially (fixed in v0.7.1)
