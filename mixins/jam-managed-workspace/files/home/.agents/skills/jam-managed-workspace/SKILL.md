---
name: jam-managed-workspace
description: Work safely in a Jam-managed Docker Sandbox workspace with zero, one, or many repositories. Use when Codex needs to inspect workspace repositories, verify GitHub readiness, clone another repository, manage its private coding-session tasks, preserve unpushed work, or report Jam runtime readiness and recovery blockers.
---

# Jam Managed Workspace

Contract version: `jam-managed-workspace-v1`.

Jam owns runtime identity, workspace placement, credentials, and lifecycle outside
the guest. Treat repositories as work inside the current session workspace, never
as the identity of the agent, room, runtime host, or runtime session.

## Inspect before acting

- Call `WorkspaceRepositories` to obtain the current zero, one, or many repository
  inventory and preservation blockers. Do not guess from the process working
  directory or scan outside the workspace.
- Call `WorkspaceGitHubReadiness` before private GitHub work when authentication
  or policy readiness is uncertain. Report credential, policy, repository access,
  and service failures as distinct blockers.
- Never request or print a raw GitHub, provider, Band, bridge, staging, or
  production credential. Docker and Jam keep supported credentials outside the
  repository and ordinary command arguments.

## Clone another repository

1. Call `WorkspaceClone` with credential-free `owner/repository` coordinates and
   an optional portable top-level destination.
2. Retain the returned operation ID and poll only that operation with
   `WorkspaceOperation` until it reaches a terminal state.
3. Refresh `WorkspaceRepositories` after success.
4. Enter the reported repository and use ordinary `git` and `gh` for branch,
   commit, push, pull-request, and check workflows.
5. Report the repository, relative path, remote owner/name, branch, dirty state,
   ahead state, PR URL, and check result relevant to the task.

Do not call host-side Jam workspace commands from the guest. Jam injects these
capabilities as exact-session tools with no agent, room, host, workspace, or
runtime-session selector. If a tool is absent, report that the runtime capability
is unavailable; do not invent a socket, selector, or CLI path.

## Track the coding session's work

Prefer injected `TaskCreate`, `TaskUpdate`, `TaskGet`, and `TaskList` task tools
for this coding runtime session's private task list. Use Codex task/todo tracking
only when those task tools are unavailable. A shared Band board is a different
product surface; do not merge, replace, or infer shared-board tasks from the
private list.

## Preserve work

- Before reset, archive, removal, or cleanup, call `WorkspaceRepositories` and
  preserve every repository with dirty or unpushed work.
- Treat detached commits, no-remote state, unknown inspection, unregistered files,
  and failed operations as blockers until the user has an explicit recovery path.
- Never delete partial clone bytes after an interrupted operation. Report the
  operation state and let Jam's recovery workflow decide what is safe.
- Never put credentials, provider state, transcripts, runtime IDs, or task-tool
  payloads into a repository or log.

## Network and local development

Guest `localhost` is the sandbox itself, not the host. Use the approved local
platform bridge only when Jam exposes that capability for this runtime. If the
local platform bridge is absent, report it as unavailable; do not create a generic
host proxy or claim that Docker network policy enables direct host localhost.

For staging, corporate services, registries, or production, distinguish requested
policy, effective Docker policy, credential readiness, and authenticated service
readiness. Production access requires its own visible authorization.

## Report actionable failures

Name the failed layer and the next safe action. Include only bounded, non-secret
identifiers already returned by Jam: relative repository path, classified state,
operation ID, and remediation. Do not expose host paths, raw remote URLs containing
credentials, command output that may contain secrets, or another session's data.
