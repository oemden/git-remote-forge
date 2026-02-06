# GitLab Remote Repository Deletion Behavior

This document explains how GitLab handles project (repository) deletion and how it interacts with the `-k` and `-K` options in `git-remote-forge`.

## Standard Delete vs Immediate Permanent Delete

GitLab exposes project deletion through the Projects REST API.

- Endpoint: `DELETE /projects/:id`
- Docs: GitLab REST API, Projects → Delete project.

### Standard Delete (Soft / Scheduled)

By default, `DELETE /projects/:id` follows your instance’s deletion policy:

- On many instances, the project is **marked as scheduled for deletion**.
- Actual removal happens later according to delayed deletion settings.

Example:

```bash
curl --request DELETE \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.example.com/api/v4/projects/12345"
```

In this mode the project typically enters a “pending deletion” state and can sometimes be restored by an administrator until the retention window expires.

When GitLab schedules a project for deletion on GitLab.com, the project path is usually rewritten from:

- `namespace/name`

to:

- `namespace/name-deletion_scheduled-<project_id>`

and the SSH/HTTPS remote URLs reflect this new scheduled-deletion name.

### Immediate Permanent Delete (Bypass Schedule)

Newer GitLab versions support **immediately** and permanently deleting a project (bypassing the delayed deletion schedule) using extra query parameters on the same endpoint:

- `permanently_remove=true`
- `full_path=<namespace/name-deletion_scheduled-<project_id>>` (URL-encoded where needed, for example `namespace%2Fname-deletion_scheduled-12345678`)

Flow:

1. Call `DELETE /projects/:id` to mark the project for deletion (soft delete).
2. Call `DELETE /projects/:id?permanently_remove=true&full_path=<scheduled-deletion-full-path>` to request immediate removal of the **scheduled-deletion** project.

Behavior depends on your GitLab configuration:

- When immediate deletion is **allowed**, the second call permanently removes the project right away.
- When immediate deletion is **disabled**, GitLab returns a `400` error (for example, `"not permitted on this instance"`), and the project remains in the scheduled-for-deletion state.

## Edition and Hosting Differences

The `permanently_remove=true` parameter is available on both CE and EE, but behavior depends on how the instance is configured.

High-level summary:

- **Self-managed (CE/EE)**:
  - Admins can allow immediate deletion via instance settings.
  - When enabled, the two-step delete flow (soft-delete + immediate delete) works from the API.
- **GitLab.com SaaS**:
  - Immediate deletion via API is generally disabled for safety.
  - Projects usually stay in scheduled deletion for the retention period (for example, 30 days).
  - Early permanent deletion might require GitLab support intervention.
- **GitLab Dedicated**:
  - Similar safety defaults to SaaS; consult your dedicated admin or support.

## How `git-remote-forge` Uses the API

`git-remote-forge` provides two options for GitLab remote deletion:

- `-k` / `--delete-online-repo` (soft delete):
  - Resolves the project using the namespace (`TARGET`) and repository name (`REPO_NAME`).
  - Calls the standard delete endpoint once (`DELETE /projects/:id`), which schedules the project for deletion.
  - Derives the scheduled-deletion name:
    - `name-deletion_scheduled-<project_id>`
  - Records, in `.repo_initiated_by_gitremoteforge`:
    - Original SSH/HTTPS remote URLs.
    - Scheduled-deletion SSH/HTTPS remote URLs.
    - A reminder date (for example, 30 days later).
- `-K` / `--force-delete-online-repo` (hard delete):
  - First runs the same soft-delete flow as `-k` (including confirmation and scheduling).
  - Then attempts a second API call:
    - `DELETE /projects/:id?permanently_remove=true&full_path=<namespace/name-deletion_scheduled-<project_id>>`
  - If the second call is accepted, `git-remote-forge`:
    - Updates `.repo_initiated_by_gitremoteforge` to replace the “deletion scheduled” block with a “deletion completed” block recording:
      - The original SSH/HTTPS remote URLs.
      - The timestamp when the remote repository was deleted.
  - If the second call is rejected by the instance (for example, HTTP `400`), `git-remote-forge`:
    - Reports that immediate deletion is not allowed.
    - Leaves the project in the scheduled-for-deletion state and keeps the original “deletion scheduled” block.

In all cases:

- Only the **remote GitLab project** is targeted.
- Local files and any local `.git` repository are **not** modified.

## Checking Your Instance Settings

On self-managed GitLab, admins can inspect and control deletion behavior. A simplified outline:

1. Log in as an administrator.
2. Go to the Admin Area.
3. Review the settings related to:
   - Delayed project deletion.
   - Whether immediate deletion is allowed.

From the API side, admins can query application settings:

```bash
curl --header "PRIVATE-TOKEN: $ADMIN_TOKEN" \
  "https://your-gitlab.example.com/api/v4/application/settings"
```

Look for keys related to:

- Delayed project deletion.
- Immediate namespace or project deletion controls.

If your instance returns `400` for `permanently_remove=true`, it is very likely that immediate deletion is disabled or restricted by these settings.

## Practical Tips

- Test on a dummy project first to understand how your GitLab instance behaves.
- If you need guaranteed immediate permanent deletion and your instance refuses `permanently_remove=true`, coordinate with your GitLab administrator or support.
- When in doubt, prefer `-k` (standard delete) and treat `-K` as a “best effort” attempt at immediate deletion whose success depends on instance configuration.
