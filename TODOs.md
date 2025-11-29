## TODO List

### High Priority
- [ ]  🚧 **Add target**: ( namespace, username or group name where the repository will be created, same for Github, bitbucket)
- [ ]  🚧 **Multi-platform Support**: Add support for GitHub, Bitbucket, and self-hosted Git servers
- [ ]  🚧 **syntax unifier** ( intermediate function for commands from different providers (github, gitlab, bitbukcet, ..) -> make workflow Provider agnostic? )
- [ ]  🚧 **Configuration File**: Create `.grfconfig` for storing default namespace and preferences, always add to gitignore
- [ ]  🚧  **create grfconfig.exemple
- [ ]  🚧 **Error Handling**: Improve error messages and recovery options
- [ ]  🚧 **Validation**: Check if remote repository already exists before pushing
- [ ]  🚧 **.gitignore**: manage gitingore at creation of repo ( or exisiting repo ) with industry basic ( .venv, .env, .secrets, .build ...)
- [ ]  🚧 Init in existing Directory
- [ ]  🚧 Manage White spaces and special characters in Repo Name
- [ ]  🚧 Public / Private Options
- [ ]  🚧 Branch rules Options  ( protected branches, ... )
- [ ]  🚧 Custom Branches Names
 
### Medium Priority
- [ ]  🚧 **Template Support**: Allow custom README templates
- [ ]  🚧 **License Selection**: Add option to include license file
- [ ]  🚧 **.gitignore Generation**: Create appropriate .gitignore based on detected technologies
- [ ]  🚧 **Batch Mode**: Support creating multiple repositories from a list
- [ ]  🚧 **Update Mode**: Allow updating existing repositories with GRF features
- [ ]  🚧 **Existing Repo** make it possible to use the tool in an existing Repo
- [ ]  🚧 **Manage Branch Rules and Protection** decide whihc branches are protected adn option to choose default branch
- [ ]  🚧 **Target Group (Gitlab)** Option to set target group for Gitlab
- [ ]  🚧 **ensure credntials are valid**: Gitlab then github
- [ ]  🚧 **URL Pattern for origin URL**: Gitlab vs Github
- [ ]  🚧 **Option to choose remote**: Gitlab vs GitHub ( for now )
- [ ]  🚧 **Install Script**: ( check n3u script )
- [ ]  🚧 **Check Credentials**: ( User's env, ssh keys and or provider access check )
    - [ ]  🚧 allow Credentials bypass: ( local .env, parameters? )

### Low Priority
- [ ]  🚧 **Interactive Mode**: Full interactive setup wizard for beginners
- [ ]  🚧 **Logging**: Add detailed logging with verbosity levels
- [ ]  🚧 **Hooks Integration**: Support for pre/post creation hooks
- [ ]  🚧 **Statistics**: Track repository creation history and metrics
- [ ]  🚧 **Plugin System**: Allow extending functionality with custom scripts
- [ ]  🚧 **Show git repo options**: ( aka remote origin, branches, ... )

### Future Enhancements
- [ ]  🚧 **API Integration**: Use GitLab API / Github API for more advanced features
- [ ]  🚧 **GitHub API handling**:  to create Repos from grf and not only Gitlab
- [ ]  🚧 **Team Collaboration**: Support for adding collaborators during creation
- [ ]  🚧 **CI/CD Integration**: Optional GitLab CI/CD pipeline setup
- [ ]  🚧 **Documentation Generation**: Auto-generate docs based on code analysis
- [ ]  🚧 **Version Control**: Track GRF version used to create each repository


