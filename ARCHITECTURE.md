# GRF Provider Abstraction Architecture

## StandardConfig Structure

All provider adapters must export these variables after setup:

```bash
# Repository & Target Info
PROVIDER_NAME          # "gitlab" | "github" | "bitbucket"
TARGET                 # namespace (gitlab), username (github), workspace (bitbucket)
REPO_NAME              # repository name (sanitized)

# Remote Configuration
REMOTE_URL             # full git URL (git@gitlab.com:namespace/repo.git OR https://...)
REMOTE_PROTOCOL        # "ssh" | "https"

# API Configuration (if applicable)
API_ENDPOINT           # provider API base URL
API_TOKEN              # auth token (if needed, from env/config)

# Validation Results
AUTH_VALID             # true | false (credentials checked)
TARGET_EXISTS          # true | false (target namespace/user exists)
REPO_EXISTS            # true | false (remote repo already exists)

# Additional Metadata
VISIBILITY             # "public" | "private" (default per provider)
DEFAULT_BRANCH         # provider's default branch name
```

## Provider Adapter Pattern

Each provider has adapter function:

```bash
handle_<provider>_setup() {
    local target=$1
    # Provider-specific logic:
    # - Validate target exists
    # - Check auth credentials
    # - Determine API endpoint
    # - Export StandardConfig variables
}
```

## Core Functions (Provider-Agnostic)

All core functions use StandardConfig only. No provider checks:

- `create_remote_repo()` - uses REMOTE_URL, REMOTE_PROTOCOL
- `push_to_remote()` - uses REMOTE_URL
- `setup_branches()` - works with any REMOTE_URL
- `detect_and_update_tech()` - works locally, repo-agnostic

## Flow

```
Input Parameters
    ↓
Route to Provider Adapter (handle_gitlab_setup, handle_github_setup, etc.)
    ↓
Adapter validates & exports StandardConfig
    ↓
Core Functions use StandardConfig (no provider awareness)
    ↓
Output
```

## Testing Strategy

Each refactoring step:
1. Extract provider logic into adapter
2. Export StandardConfig from adapter
3. Test adapter in isolation
4. Test core functions still work
5. Commit working state
