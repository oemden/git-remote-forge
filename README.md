# GIT REMOTE FORGE (git-remote-forge)

A tool to create and setup git projects locally and push them remotely on GitLab, with a focus on streamlined repository initialization and remote platform integration.

## Prerequisites
- Git configured locally (`user.name` and `user.email`)
- SSH key setup and configured for GitLab access
- GitLab namespace (username or group name where the repository will be created)

## Features (v0.9.1)
- Absolute and relative path support in `-d`
- Better path display (directory name + parent separately)
- Early abort on first fatal push error
- Scenario-based remote conflict messaging

## Features (v0.9.0)
- Existing directory and git repository detection
- Smart initialization (creates or uses existing dir/repo)
- Branch detection and safe handling (no destructive changes)
- Master vs main detection (legacy repo support)
- Multi-provider architecture (GitLab, Gitea, GitHub, Bitbucket ready)
- Parameter-driven config: `-n` namespace, `-R` provider, `-T` technologies
- Auto-detect tech with `-t` flag
- Self-hosted support via `-S` option
- Provider-agnostic functions (StandardConfig abstraction)
- Bash 3.x compatible

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

### Optional: 

**use install script**

`bash install.sh` will install git-remote-forge `gitremote.sh` to `/usr/local/bin/gitremote`

or do it manually

**Add to `/usr/local/bin/`**

`cp gitremote.sh gitremote`

or

**Add to your PATH**

`sudo ln -s $(pwd)/gitremote /usr/local/bin/gitremote`

##  Usage

### Preview mode (default):

- `gitremote -d project_name -n myuser -T "python,django"`

### Force mode (no preview):

- `gitremote -d project_name -n myuser -f`


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

2. Prompt for confirmation before executing
3. Only proceed if confirmed

