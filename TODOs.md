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

---

## CURRENT WORK: Phase 2 - Existing Directory Support
**Branch:** `feature/existing-directory-init`

### Existing Directory/Repository Support
- [ ] Remove hardcoded `-d` requirement (optional for existing mode)
- [ ] Auto-detect `.git` directory in current location
- [ ] Auto-detect if `-p` path contains existing git repo
- [ ] Skip `mkdir` and `git init` if .git exists
- [ ] Handle existing remote configuration
- [ ] Handle existing branches (don't recreate main/production/develop)
- [ ] Initialize new repos in existing directory with files
- [ ] Call `detect_technologies()` when `-t` flag provided
- [ ] Update README with detected/user-provided technologies
- [ ] Support both modes: `grf -n user -t` and `grf -p /path -n user -t`

### Documentation & Tests
- [ ] Update README with existing directory mode examples
- [ ] Test new repo creation (ensure backward compatible)
- [ ] Test existing directory without .git
- [ ] Test existing git repo (add remote only)
- [ ] Test `-t` auto-detect functionality
- [ ] Test technology output in README

---

## Phase 3: Foundation & Configuration

### Config File System
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
