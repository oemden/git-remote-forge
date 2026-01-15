# GIT REMOTE FORGE (git-remote-forge)

A tool to create and setup git projects locally and push them remotely on GitLab, with a focus on streamlined repository initialization and remote platform integration.

## Status

**v0.9.2 - Ready for Use (GitLab Only)**

git-remote-forge has reached a stable state suitable for production use.
The core workflow is tested and reliable: create local repositories, initialize branches by default (main, develop, production) locally, then push to GitLab with a single command.
GitHub, Bitbucket, and Gitea providers are in the roadmap but not yet implemented.
If you use GitLab, this tool will save you time on repetitive setup tasks.

## Use Cases

### Case 1: Create New Repository in Current Directory

Create a new folder inside the current directory, initialize git, and push to GitLab:

```bash
gitremote -d my-new-repo -n my_gitlab_namespace
```

This will:

- Create `./my-new-repo/` directory
- Initialize git repository
- Create README.md
- Create branches: main, production, develop
- Push to GitLab: `git@gitlab.com:my_gitlab_namespace/my-new-repo.git`
- Checkout to `develop` branch

### Case 2: Create Repository from Existing Directory (Specified Path)

Use an existing directory at a specific path:

```bash
gitremote -n my_gitlab_namespace -p /path/to/existing/folder
```

Or with relative path:

```bash
gitremote -n my_gitlab_namespace -p ./my-existing-project
```

This will:

- Use the existing directory at `/path/to/existing/folder`
- Initialize git if not already initialized
- Create README.md if it's a new repo
- Push to GitLab (creates remote if none exists)
- Works with or without existing `.git` directory

### Case 3: Create Repository from Current Directory

Use the current directory (no `-d` or `-p` needed):

```bash
cd /path/to/my-project
gitremote -n my_gitlab_namespace
```

This will:

- Use the current directory (`.`)
- Initialize git if not already initialized
- Create README.md if it's a new repo
- Push to GitLab (creates remote if none exists)
- Works with or without existing `.git` directory

### Case 4: Custom Remote Name

Use a custom remote name instead of default "origin":

```bash
gitremote -d my-repo -n my_gitlab_namespace -r gitlab
```

This will:
- Create the repository as usual
- Use `gitlab` as the remote name instead of `origin`
- Remote URL: `git@gitlab.com:my_gitlab_namespace/my-repo.git`

## Prerequisites

- Git configured locally (`user.name` and `user.email`)
- SSH key setup and configured for GitLab access
- GitLab namespace (username or group name where the repository will be created)

## Branch Structure

GIT REMOTE FORGE creates three default branches:

- `main`: Primary branch for stable code
- `production`: Production-ready releases
- `develop`: Active development branch

The script automatically:

1. Creates all three default branches
2. Initializes with README on main branch
3. Propagates initial setup to all branches
4. Checks out to develop branch by default

You can specify a different branch to checkout using the `-b` option:

`gitremote -d project_name -b production  # Creates all branches, checks out to production`

- Default working branch is `develop` unless specified via `-b`

### Branch Management

- All changes start on `main` branch
- Changes are propagated to `production` and `develop`

## Installation

### Clone the repository

`git clone git@github.com:username/git-remote-forge.git`

`cd git-remote-forge`

### Make the script executable

`chmod +x gitremote.sh`

### Optional

Use install script:

`bash install.sh` will install git-remote-forge `gitremote.sh` to `/usr/local/bin/gitremote`

or manually add it to `/usr/local/bin/`:

`cp gitremote.sh gitremote`

or add it to your PATH:

`sudo ln -s $(pwd)/gitremote /usr/local/bin/gitremote`

## How It Works

### Preview Mode (Default)

When you run git-remote-forge, it will:

1. **Display a preview** of all operations:
   - Directory creation/usage
   - Git repository initialization
   - Remote configuration
   - Branch operations
   - Push operations

2. **Prompt for confirmation** before executing

3. **Execute** only if you confirm

Example:

```bash
gitremote -d my-project -n myusername
```

### Force Mode

Skip preview and confirmation (useful for scripts):

```bash
gitremote -d my-project -n myusername -f
```

## Options

### Required Options

- `-n` : Namespace/username (target on provider, e.g., your GitLab username or group)

### Directory Options

- `-d` : Directory/Project name (creates new directory in current location)
- `-p` : Path to existing directory (absolute or relative path)
  - If neither `-d` nor `-p` provided, uses current directory (`.`)

### Remote Options

- `-r` : Set custom remote name (default: `origin`)
  - Example: `-r gitlab` uses "gitlab" instead of "origin"

### Branch Options

- `-b` : Branch to checkout after creation (default: `develop`)
  - Example: `-b production` checks out to production branch

### Technology Options

- `-T` : Technologies (comma-separated, optional)
  - Example: `-T "python,django,postgresql"`
- `-t` : Auto-detect technologies from existing files (flag, no argument)

### Provider Options

- `-S` : Self-hosted URL (optional, for self-hosted GitLab instances)
  - Example: `-S gitlab.example.com`

### Other Options

- `-f` : Force mode (skip preview and confirmation)
- `-h` : Display help message

## Examples

### Basic Usage

```bash
# Create new repo in current directory
gitremote -d my-project -n myusername

# Use existing directory
gitremote -n myusername -p /path/to/existing/project

# Use current directory
cd /path/to/project
gitremote -n myusername
```

### Advanced Usage

```bash
# Create repo with technologies specified
gitremote -d my-python-app -n myusername -T "python,flask,postgresql"

# Create repo and checkout to production branch
gitremote -d my-project -n myusername -b production

# Use custom remote name
gitremote -d my-project -n myusername -r gitlab

# Use existing directory with auto-detect technologies
gitremote -n myusername -p /path/to/project -t

# Force mode (skip confirmation)
gitremote -d my-project -n myusername -f
```

### Combining Options

```bash
# Full example: new repo, custom remote, technologies, specific branch
gitremote -d my-api -n myusername -r gitlab -T "python,fastapi" -b production

# Existing directory with relative path
gitremote -n myusername -p ./my-existing-repo -T "javascript,nodejs"
```

## What Gets Created

### Directory Structure

```
my-project/
├── .git/
├── README.md
└── (your files)
```

### Git Branches

- `main` - Primary branch (initial commit here)
- `production` - Production-ready releases
- `develop` - Active development (default checkout)

### Remote Configuration

- Remote name: `origin` (or custom with `-r` flag)
- Remote URL: `git@gitlab.com:namespace/repo-name.git`

### README.md

Automatically created with:
- Project name
- Main contributor (from git config)
- Technologies (if specified with `-T`)

## Troubleshooting

### Remote Already Exists

If a remote with the same name already exists, the script will:
- Show the existing remote URL
- Provide options to resolve the conflict
- Exit safely without making changes

**Solutions:**
- Use `-r <different-name>` to specify a different remote name
- Manually change/remove the remote: `git remote set-url origin <new-url>`
- Remove the remote: `git remote remove origin`

### Directory Already Exists

If the directory already exists:
- The script will use it (won't overwrite)
- If it's a git repo, it will detect and handle accordingly
- If it has files, they won't be deleted

### Git Not Configured

Make sure git is configured:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```
