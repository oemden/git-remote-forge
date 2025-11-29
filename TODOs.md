## TODO List

### Parameter Strategy
```
-d, --dir          Project directory/name (required for new repo)
-t, --target       Namespace/username (GitLab groups, GitHub users, etc.)
-R, --repo         Provider: gitlab|github|bitbucket (default: gitlab)
-T, --tech         Technologies (comma-separated, optional)
-B, --branch       Checkout branch after creation (default: develop)
-e, --existing     Existing repo mode (detect or explicit flag)
-p, --path         Path to repo (optional, for existing repo outside cwd)
-f, --force        Skip preview and confirmation
-h, --help         Display help message
```

### Configuration
- Location: `~/.config/.gitremoteforge/.grfconfig`
- Priority: Parameters override config file
- Content: default target, default provider, default technologies, default branch
- No `-c` parameter needed; config is implicit in standard location

---

## Phase 1: Core Features (IMMEDIATE)

### Target & Provider Support
- [ ] Add `-t, --target` parameter (namespace/username agnostic)
- [ ] Add `-R, --repo` parameter (gitlab|github|bitbucket)
- [ ] Rename `-t` to `-T, --tech` for technologies
- [ ] Update preview/output to reflect target and provider

### Existing Repository Support
- [ ] Add `-e, --existing` flag for existing repo mode
- [ ] Add `-p, --path` parameter (optional path to repo)
- [ ] Auto-detect `.git` directory in current location
- [ ] Skip `mkdir` and `git init` in existing mode
- [ ] Validate existing remote or add new remote
- [ ] Handle existing branches (don't recreate if present)

### Documentation
- [ ] Update README.md with new parameters
- [ ] Update usage examples
- [ ] Document both new-repo and existing-repo workflows

---

## Phase 2: Foundation & Configuration

### Config File System
- [ ] Create `.grfconfig` template in `~/.config/.gitremoteforge/`
- [ ] Parse config file on startup
- [ ] Allow parameter override of config values
- [ ] Create example config file (`grfconfig.example`)
- [ ] Add `.grfconfig` to `.gitignore` (local + global)

### Multi-Platform Support Architecture
- [ ] Create provider abstraction layer/syntax unifier
- [ ] Implement GitLab provider wrapper (refactor from current)
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

## Phase 3: Enhancement Features

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

## Phase 4: Advanced Features

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
