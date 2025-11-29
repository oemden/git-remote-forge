# Changelog

All notable changes to GRF (git-remote-forge) are documented here.

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
- Version bumped to 0.7.1

### Notes
- Architecture ready for GitHub and Bitbucket provider support
- Next phase: `-t --target` and `-R --repo` parameters

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
