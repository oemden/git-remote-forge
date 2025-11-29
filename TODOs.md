## TODO List

### Parameter Strategy
```
-d, --dir          Project directory/name (required for new repo)
-n, --namespace    Namespace/username (target on provider)
-R, --repo         Provider: gitlab|github|bitbucket|gitea (default: gitlab)
-S, --self-hosted  Self-hosted URL (optional, for self-hosted instances)
-t                 Auto-detect technologies (existing directory mode only)
-T, --tech         Technologies (user-provided, comma-separated, optional)
-B, --branch       Checkout branch after creation (default: develop)
-p, --path         Path to local directory (existing directory mode)
-f, --force        Skip preview and confirmation
-h, --help         Display help message
```

### Configuration
- Location: `~/.config/.gitremoteforge/.grfconfig`
- Priority: Parameters override config file
- Content: default namespace, default provider, default technologies, default branch
- No `-c` parameter needed; config is implicit in standard location

---

## COMPLETED ✅

### Phase 0: Architecture & Refactoring
- [x] Define StandardConfig structure (ARCHITECTURE.md)
- [x] Extract GitLab logic into `handle_gitlab_setup()` adapter
- [x] Rewrite core functions to use StandardConfig (agnostic)
- [x] Validate all GitLab workflows work post-refactor
- [x] Fix bash 3.x compatibility (declare -A → case statements)
- [x] Update script version to 0.7.1

### Phase 1: Target & Provider Support (v0.8)
- [x] Add `-n, --namespace` parameter (replaces interactive prompt)
- [x] Add `-R, --repo` parameter (gitlab|github|bitbucket|gitea)
- [x] Rename `-t` to `-n` for namespace, use `-t` for auto-detect tech
- [x] Add `-t` auto-detect flag (existing directory mode)
- [x] Add `-T, --tech` parameter for user technologies
- [x] Add `-S, --self-hosted` parameter for custom domains
- [x] Update parse_arguments() with new options
- [x] Update usage() documentation with modes/examples
- [x] Pass parameters to handle_gitlab_setup()
- [x] Add provider routing (setup_provider function)
- [x] Add handle_gitea_setup() adapter

### Phase 2: Existing Directory Support (v0.9.0) ✅ COMPLETE
- [x] `local_directory()` - manage dir creation/detection
- [x] `manage_git()` - detect or initialize git repos
- [x] `has_branches()` - check if repo has branches
- [x] Smart init: empty `.git` → new, branches exist → existing
- [x] Refactor `create_local_repo()` - only README + commit (no mkdir)
- [x] Refactor `main()` - 5 step workflow
- [x] Update `push_to_remote()` - handle both new and existing
- [x] Early validation before provider setup
- [x] Support empty `git init` repos (backwards compatible)
- [x] Safe approach: detect state, never destroy
- [x] Scenario-based remote messaging (multiple/single/none)
- [x] Show remote URLs in conflict messages
- [x] Tested: empty dir, empty .git, existing repo with branches

---

## BACKLOG - Phase 3+

### Setup Validation & Error Handling
- [x] Detect git push failures, exit with error code
- [ ] Validate remote created before success message
- [ ] Check remote repo exists on provider before push
- [ ] Provide clear error messages with troubleshooting steps
- [ ] Add `-v/--verbose` flag for detailed output
- [ ] Add `--dry-run` option (parse only, no execution)

### Path Handling Improvements
- [x] Support absolute paths in `-d` parameter (v0.9.1)
- [x] Better formatted path output (v0.9.1)
- [x] Display full path in output (v0.9.1)
- [ ] Merge `-d` and `-p` logic (clarify intent)
- [ ] Add path validation before operations
- [ ] Warn on deeply nested paths

### Remote Management Enhancements
- [ ] Add `--force-remote` flag to skip remote conflict checks
- [ ] Add `--change-remote` option with URL parameter
- [ ] Support workflow: detect remote conflict → prompt user → execute option
- [ ] Add pre-configured options menu for common scenarios:
  - Change remote URL (git remote set-url origin)
  - Remove remote (git remote remove origin)
  - Rename remote (git remote rename origin)
  - List all remotes with fetch/push URLs
  - Validate remote exists before push
- [ ] Background: Allow managing multiple remotes (Phase 4+)

### Phase 3: Config File System
- [ ] Create `.grfconfig` template in `~/.config/.gitremoteforge/`
- [ ] Parse config file on startup
- [ ] Allow parameter override of config values
- [ ] Create example config file (`grfconfig.example`)
- [ ] Add `.grfconfig` to `.gitignore` (local + global)

### Multi-Platform Support Architecture
- [ ] Implement GitHub provider (API-based repo creation)
- [ ] Implement Bitbucket provider (optional for v1)
- [ ] URL pattern detection per provider (git@gitlab.com: vs github.com/)

### Credential & Validation
- [ ] Validate Git config (user.name, user.email)
- [ ] Check SSH key setup per provider
- [ ] Validate namespace/username exists (API check)
- [ ] Validate remote repo doesn't already exist
- [ ] Allow credential bypass via local .env or parameters

---

## Phase 4: Enhancement Features

### .gitignore Management
- [ ] Generate .gitignore based on detected technologies
- [ ] Support industry-standard templates (.venv, .env, .secrets, .build, etc.)
- [ ] Allow custom .gitignore specification

### Branch & Repository Rules
- [ ] Public/private repository option (`--visibility`)
- [ ] Branch protection rules configuration
- [ ] Set default branch per provider
- [ ] Custom branch names (instead of fixed main/production/develop)
- [ ] Branch naming validation (spaces, special chars)

### Repository Metadata
- [ ] License selection option
- [ ] Description option
- [ ] README template support
- [ ] Manage whitespace and special characters in repo names

---

## Phase 5: Advanced Features

### Batch & Template Operations
- [ ] Batch mode: create multiple repos from list
- [ ] Update mode: GRF features on existing repositories
- [ ] Template support: custom README templates
- [ ] Interactive wizard mode for beginners

### Monitoring & Integration
- [ ] Logging with verbosity levels
- [ ] Repository creation history tracking
- [ ] Pre/post creation hooks
- [ ] CI/CD pipeline templates (GitLab CI/GitHub Actions)

### Provider-Specific Features
- [ ] GitLab API integration (advanced features)
- [ ] GitHub API full integration
- [ ] Team collaboration: add collaborators during creation
- [ ] Auto-generate documentation from code analysis

---

## Low Priority (Future)

- [ ] Plugin system for custom extensions
- [ ] GRF version tracking per repository
- [ ] Statistics and metrics
- [ ] Show git repo options (remote, branches, etc.)
- [ ] Install script for setup
