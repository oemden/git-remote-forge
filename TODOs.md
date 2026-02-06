# TODO List

- [x] `-k` `--delete-online-repo`       DELETE online Repo, Require user confirmation. (GitLab implementation complete, v0.10.0)
- [x] `-K` `--force-delete-online-repo` DELETE immediatly online repo (GitLab 2 step process: schedule + immediate delete) - REQUIRES 2 times user confirmation with BIG WARNINGS. (implemented v0.10.0)
  - [x] when `-k` sucessful AND `-K` has not been called
      ( eg: only -k is called  as -K calls -k function too ), adapt remote URL/path accordingly.
    - [x] save current remote URL to `.repo_initiated_by_gitremoteforge`
    - [x] save new URL ( scheduled for deletion ) in `.repo_initiated_by_gitremoteforge` with reminder date
- [ ]      Always create a `.repo_initiated_by_gitremoteforge` ( with gitremote version, add to `.gitignore` if exist or create .gitignore exclusion even without -i arg)
- [ ] `-N` Create New Namespace ( Gitlab ) - Requires `-V` ( `priv` `private` vs `pub` `public` ) - do not create a New User in GitHub !
- [ ] `-V` Visibility - Private vs Public repo (on Gitlab - depends on namespace visibility - to check for Github and others ) defaults to Private `priv` `private`
- [ ] `-E` --keep          Keep existing files eg: README.md, .gitignore\
- [ ] `-I`,                Specify what to add to .gitignore ? #TODO
- [ ] `--version`          Display git-remote-forge version
- [ ] `-v`                 show git remote(s) in current dir `git remote -v` ( detect if `$PWD` is a git repo)
- [ ] `-R`                 Replace remote ( same Name different provider or URL ) # ✅ COMPLETE (v0.9.5)
- [ ]                      Download .gitignore templates from [https://github.com/github/gitignore]
- [x]  Add a Clean test repos (eg: when testing new repo or other tests, clean up every dummy repos locally and online ) (v0.10.1)

## Parameter Strategy

```bash
-d, --dir                    Project directory/name (required for new repo) # ✅ COMPLETE
-c, --current                Project directory/name (required for new repo) from current Directory. ( no -d), same as -p # TODO
-n, --namespace              Namespace/username (target on provider) # ✅ COMPLETE
-P, --provider               Provider: (gitlab|github|bitbucket|gitea) (default: gitlab) # ✅ COMPLETE (v0.9.7)
-S, --self-hosted            Self-hosted URL (optional, for self-hosted instances gitlab|gitea) # ✅ COMPLETE
-t                           Auto-detect technologies (existing directory mode only) # ✅ COMPLETE
-T, --tech                   Technologies (user-provided, comma-separated, optional) # ✅ COMPLETE
-b, --branch                 Checkout branch after creation (default: develop) # ✅ COMPLETE
-B, --branches               Add / Override  specific custom branches (other than develop|main|production) # TODO
-r, --remote-name            Set Remote Name ( default: origin ) # ✅ COMPLETE (v0.9.2)
-R, --replace-remote         Replace remote URL (prompts for confirmation) # ✅ COMPLETE (v0.9.5)
-i, --gitignore              Create basic std gitignore file ( default: .*env, !.env.example, .repo_init_by_gitremoteforge) # ✅ COMPLETE (v0.9.4)
-I,                          Specify what to add to .gitignore ? # TODO
-p, --path                   Path to local directory (existing directory mode) # ✅ COMPLETE
-f, --force                  Skip preview and confirmation # ✅ COMPLETE
-F                           Force remote delete confirmations for -k / -K (non-interactive hard delete) # ✅ COMPLETE (v0.10.0)
-k, --delete-online-repo     Soft delete remote repo on provider (GitLab implemented) # ✅ COMPLETE (v0.10.0)
-K, --force-delete-online-repo  Hard delete remote repo on provider (GitLab implemented) # ✅ COMPLETE (v0.10.0)
-W                           Resolve and print GitLab project id from current git remote # ✅ COMPLETE (v0.10.0)
-h, --help                   Display help message # ✅ COMPLETE
--dry                        Dry Mode, eg: do not do anything, just show remote repo URL, remote name (origin), branches to create # TODO
```

### TESTS

- [x] Split Tests.sh into smaller tests
- [x] Create tests.cfg - Move hardcoded VALUES in script to tests.cfg

### Configuration

- Location: `~/.config/.gitremoteforge/.grfconfig`
- Priority: Parameters override config file
- Content: default namespace, default provider, default technologies, default branch
- No `-c` parameter needed; config is implicit in standard location
- trim white spaces ( -d option) echo error ask user to continue (trim) or abort

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

### Phase 2: Existing Directory Support (v0.9.0-0.9.3) ✅ COMPLETE

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
- [x] Support absolute paths in `-d` parameter (v0.9.1)
- [x] Better formatted path output (v0.9.1)
- [x] Display full path in output (v0.9.1)
- [x] Detect git push failures, exit with error code (v0.9.1)
- [x] Early abort on first push failure (v0.9.1)
- [x] Fix macOS realpath compatibility (v0.9.2) - check path existence before calling realpath
- [x] Add default current directory behavior when no -d/-p (v0.9.2)
- [x] Add -r flag for custom remote names (v0.9.2)
- [x] Change branch checkout flag from -B to -b (v0.9.2)
- [x] Update README with comprehensive use cases (v0.9.2)
- [x] Add comprehensive code comments (v0.9.2)
- [x] Defer git init until after user confirmation (v0.9.3) - prevents .git creation before preview

- ### Phase 2: Existing Directory Support (v0.9.4) ✅ COMPLETE

- [x] `-r`, --remote-name  Set Remote Name ( default: origin ) # ✅ COMPLETE (v0.9.2)
- [x] `-i`, --gitignore    Create basic std .gitignore file ( default: .*env, !.env.example, .repo_init_by_gitremoteforge) # ✅ COMPLETE (v0.9.4)
- [x] `-O` Override any existing .git in existing target directory - user prompted twice for this DESTRUCTIVE operation ( usefull to duplicate a repo ) # ✅ COMPLETE (v0.9.4)
- [x] `-R` Replace remote URL (prompts for confirmation if URL differs) # ✅ COMPLETE (v0.9.5)
- [x] URL duplicate detection - prevent adding multiple remotes with same URL # ✅ COMPLETE (v0.9.5)
- [x] Fix no-args behavior: display help/usage instead of prompting to create repo # ✅ COMPLETE (v0.9.6)
- [x] `-P` Provider selection option (gitlab|github|bitbucket|gitea, default: gitlab) # ✅ COMPLETE (v0.9.7)

---

## BACKLOG - Phase 3+

### Testing & CI/CD

- [ ] Create test automation script covering core scenarios
- [ ] Test scenarios: new repo, absolute path, relative path, existing .git, existing branches, remote conflicts, push failures, force mode
- [ ] Prepare CI/CD pipeline for develop→main merges
- [ ] Add GitHub Actions or GitLab CI config
- [ ] Automated tests on: parameter validation, path handling, git operations, provider routing
- [ ] Mock provider responses for testing without GitLab account
- [ ] Coverage: success paths and error paths

### Setup Validation & Error Handling

- [x] Defer git init until after user confirmation (v0.9.3) - prevents .git creation before preview
- [ ] Validate remote created before success message
- [ ] Check remote repo exists on provider before push (Phase 3)
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
- [ ] URL pattern detection per provider (<git@gitlab.com>: vs github.com)

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
