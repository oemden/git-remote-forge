# Changelog

All notable changes to git-remote-forge are documented here.

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
