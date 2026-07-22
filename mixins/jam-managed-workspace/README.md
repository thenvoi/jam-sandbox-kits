# Jam managed workspace mixin

This Codex-only Jam integration installs the native
`jam-managed-workspace-v1` skill at:

```text
$HOME/.agents/skills/jam-managed-workspace/SKILL.md
```

It also installs the guest half of Jam's authenticated local-platform bridge at
`$HOME/.local/bin/jam-local-platform-bridge`. The helper is inert until Jam
starts it for an explicitly enabled runtime session. It binds an ephemeral
guest-loopback port, requires that session's short-lived capability, and sends
bounded HTTP request frames and WebSocket byte streams to Jam over owned stdio.
WebSocket extensions are rejected; the helper forwards the exact upstream
handshake and data bytes without terminating or reframing the protocol. It does
not know or select the host destination, and it persists no credential or
authority. Jam sends the one-time initialization frame over private stdin before
the listener opens; the capability is never placed in `sbx exec` arguments or
environment flags.

The helper permits at most 16 concurrent WebSockets per runtime session, not per
host or installation. WebSocket chunks are capped at 256 KiB, traffic is capped
at 32 MiB per minute in each direction, guest output buffering is capped at
4 MiB, and an upgrade must complete within five seconds. Jam can revoke the
session capability and close all associated connections immediately.

Stock Codex discovers user-scoped skills there independently of `CODEX_HOME`.
The mixin writes no managed-workspace files and declares no commands or agent
context. Its Developer network request covers Band/runtime services, GitHub,
and common language/container registries, plus Docker's proxy-managed
`GITHUB_TOKEN` contract. Docker's effective local or organization policy stays
authoritative: a requested allow is never evidence that traffic is effective.
Configured staging and approved corporate HTTPS destinations remain dynamic
Jam policy, not hard-coded public kit entries. The credential is optional so
public clone and non-GitHub work do not block sandbox creation. A host-side
`github` service secret is required for authenticated private clone, push, PR,
and check workflows; the real token never enters the VM.

Jam remains authoritative for exact-session runtime tools and attaches the
reviewed, immutable OCI-digest-pinned mixin only to new Managed Docker-backed
Codex runtime templates. The public source commit and release manifest identify
the reviewed source tree behind that artifact. The skill explains how to use
the injected clone, branch, commit, push, pull-request, inventory, readiness, and operation-status
tools; it cannot select another agent, room, runtime host, workspace, or
runtime session. Commit author and signing policy remain operator-owned runtime
template configuration and cannot be selected by the model.

Band transport is deliberately not part of this guest mixin. `jamd` keeps the
Band socket, durable queues, acknowledgements, and user/agent custody keys on the
host and delivers only room messages through the owned app-server channel. The
guest receives no Band key and must not establish a second Band connection.

The skill also explains the placement boundary that Jam—not the guest—controls.
Shared placement is one agent trust boundary and amortizes one roughly 300 MB idle
microVM across compatible room sessions. Dedicated placement consumes one microVM
per active session in exchange for stronger process, filesystem, credential,
network, resource, and failure isolation. Agent-, runtime-host-, and session-scoped
lifecycle actions remain distinct host-side authority; the guest receives no host
selector or lifecycle command.

The installed `sbx v0.34` consumer rejects the newer `requires.agent` schema
field, so the artifact cannot express Codex affinity in `spec.yaml` yet. Jam's
typed Managed-Codex default enforces that affinity. Add `requires.agent: codex`
only after the minimum supported Docker consumer accepts and enforces it.

Validate both schema normalization and the skill contract from the repository
root:

```sh
tests/managed-workspace-skill.test.sh
node tests/local-platform-bridge-helper.test.mjs
```
