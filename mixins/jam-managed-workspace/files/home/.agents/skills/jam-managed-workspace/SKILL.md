---
name: jam-managed-workspace
description: Work safely in a Jam-managed Docker Sandbox workspace with zero, one, or many repositories. Use when Codex needs to inspect workspace repositories, verify GitHub readiness, clone another repository, create a branch, commit, push, open a pull request, inspect its checks, manage private coding-session tasks, preserve unpushed work, or report Jam runtime readiness and recovery blockers.
---

# Jam Managed Workspace

Contract version: `jam-managed-workspace-v1`.

Jam owns runtime identity, workspace placement, credentials, and lifecycle outside
the guest. Treat repositories as work inside the current session workspace, never
as the identity of the agent, room, runtime host, or runtime session.

## Understand placement and action scope

Jam selects the runtime-host placement; do not try to change or reproduce it from
inside the guest. **Shared** placement lets compatible room sessions for one
immutable agent identity reuse one microVM and app-server. Those sessions retain
exact runtime-session directories and tools, but the microVM is one agent trust
boundary—not hard isolation between rooms. **Dedicated** placement gives one
runtime session its own microVM and is the stronger per-session isolation choice
for process, filesystem, credential, network, resource, or failure boundaries.

Each active microVM uses approximately 300 MB while idle. Shared placement
amortizes that capacity across compatible rooms; Dedicated consumes it per active
session. Agent-wide actions affect every room for the identity, a host-wide action
affects every session sharing that runtime host, and an exact-session action affects
only its room. Jam owns all lifecycle actions outside the guest. Never infer
host-wide authority from the current directory, room, or injected session tools.

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

Band connectivity stays in jamd on the host. The daemon owns the Band socket,
durable queue, room membership, delivery acknowledgements, and credential
custody, then delivers only the room message over the owned app-server channel.
Do not look for a Band credential or open a second Band connection from the
guest; no Band custody key belongs in the sandbox environment.

## Clone another repository

1. Call `WorkspaceClone` with credential-free `owner/repository` coordinates and
   an optional portable top-level destination.
2. Retain the returned operation ID and poll only that operation with
   `WorkspaceOperation` until it reaches a terminal state.
3. Refresh `WorkspaceRepositories` after success.
4. Call `WorkspaceBranch` with the exact relative repository path reported by
   inventory, a new branch name, and an optional start point. Poll the returned
   operation ID with `WorkspaceOperation`, then refresh inventory.
5. Use ordinary `git add` to select the intended changes. Then call
   `WorkspaceCommit` with the exact relative repository path and a bounded
   commit message. Poll its operation ID with `WorkspaceOperation`. Jam applies
   the operator-owned author and signing policy; never try to pass or override
   author identity, signing mode, runtime identity, or another session.
6. Call `WorkspacePush` with the exact relative repository path. Jam fixes the
   remote and refspec to the current branch's same-named `origin` branch; the
   tool cannot redirect Docker-managed credentials. Poll its operation ID with
   `WorkspaceOperation`, then refresh inventory.
7. Call `WorkspacePullRequest` with the exact relative repository path, title,
   and body. Jam updates the current branch's existing pull request or creates
   one when absent; repository, head, and base selection cannot be redirected.
   Poll its operation ID with `WorkspaceOperation`.
8. Call `WorkspaceChecks` with the exact relative repository path. Jam derives
   the current branch's pull request and returns only a bounded aggregate state:
   passed, pending, failed/cancelled, or no checks. Poll its operation ID with
   `WorkspaceOperation`. Never select a PR number, URL, branch, remote, check,
   credential, or another runtime session.
9. Report the repository, relative path, remote owner/name, branch, dirty state,
   ahead state, PR URL, and check result relevant to the task.

Do not call host-side Jam workspace commands from the guest. Jam injects these
capabilities as exact-session tools with no agent, room, host, workspace, or
runtime-session selector. If a tool is absent, report that the runtime capability
is unavailable; do not invent a socket, selector, or CLI path.

If `WorkspaceCommit` reports missing identity, the operator must configure an
explicit author in the runtime template or persistent sandbox Git
`user.name`/`user.email`. If required signing fails, report the blocker; Jam
never retries that commit unsigned.

If `WorkspacePush` reports missing GitHub authentication, the operator must
configure Docker's `github` service secret. Never ask for the token in the
guest. Detached HEAD and missing `origin` are explicit blockers; do not invent a
remote or refspec.

If `WorkspacePullRequest` fails, report the classified blocker and preserve the
branch. Never retry by selecting a different repository, head, base, remote, or
credential path, and never put the pull-request body or a credential in command
arguments or logs.

If `WorkspaceChecks` reports no pull request, create one through
`WorkspacePullRequest` before retrying. Pending checks are not a terminal task
success; wait and inspect again. Failed or cancelled checks are blockers. Jam
intentionally does not return check names, links, or provider output through the
durable operation journal; use ordinary `gh` only when detailed diagnostics are
needed and policy allows it.

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
The same injected bridge URL supports ordinary HTTP and WebSocket clients. For a
WebSocket endpoint, change only the URL scheme from `http` to `ws` (or `https` to
`wss`) and retain the injected capability header during the upgrade. Do not
request WebSocket extensions such as compression. Jam preserves protocol bytes,
but owns the fixed upstream origin, authorization, bounds, logging, and cleanup.

For staging, corporate services, registries, or production, distinguish requested
policy, effective Docker policy, credential readiness, and authenticated service
readiness. Production access requires its own visible authorization.

## Report actionable failures

Name the failed layer and the next safe action. Include only bounded, non-secret
identifiers already returned by Jam: relative repository path, classified state,
operation ID, and remediation. Do not expose host paths, raw remote URLs containing
credentials, command output that may contain secrets, or another session's data.
