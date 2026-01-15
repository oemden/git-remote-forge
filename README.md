# GIT REMOTE FORGE (git-remote-forge)

A tool to create and setup git projects locally and push them remotely on GitLab, with a focus on streamlined repository initialization and remote platform integration.

## Status

**v0.9.1 - Ready for Use (GitLab Only)**

git-remote-forge has reached a stable state suitable for production use.
The core workflow is tested and reliable: create local repositories, initialize branches by default (main, develop, production) localy, then push to GitLab with a single command.
GitHub, Bitbucket, and Gitea providers are in the roadmap but not yet implemented.
If you use GitLab, this tool will save you time on repetitive setup tasks.

For exemple:

create a local empty directory, set up git branches or use an existing directory ( with or without git initiated) and push the newly created repo to your gitlab's namespace in a single command.

- Start from scratch:

```bash
gitremote -d my-noexisting-repo -n my_gitlab_namespace -R gitlab -B develop
```

- Use an existing directory, on which you've started working locally:

```bash
gitremote -d /path/to/my-existing-repo -n my_gitlab_namespace -R gitlab -B develop -T "python"
```

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

You can specify a different branch to checkout using the `-B` option:

`gitremote -d project_name -B production  # Creates all branches, checks out to production`

- Default working branch is `develop` unless specified via `-B`

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

## Usage

### Preview mode (default)

- `gitremote -d project_name -n my_gitlab_namespace -T "python,django"`

### Force mode (no preview)

- `gitremote -d project_name -n my_gitlab_namespace -f`

## Options

- `-d` : Directory/Project name (required)
- `-n` : Namespace/username (target on provider)
- `-R` : Provider: gitlab|github|bitbucket|gitea (default: gitlab)
- `-S` : Self-hosted URL (optional)
- `-t` : Auto-detect technologies (flag, no argument)
- `-T` : Technologies (comma-separated, optional)
- `-B` : Branch to checkout (default: develop)
- `-p` : Path to directory (optional)
- `-f` : Force mode
- `-h` : Help

### Preview Mode

When run without the `-f` flag, the script will:

1. Display planned operations:

- Local repository setup details
- Remote repository configuration
- Branch operations
- Push operations
- Post-setup operations (if any)

1. Prompt for confirmation before executing
2. Only proceed if confirmed
