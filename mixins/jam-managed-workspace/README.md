# Jam managed workspace mixin

This Codex-only Jam integration installs the native
`jam-managed-workspace-v1` skill at:

```text
$HOME/.agents/skills/jam-managed-workspace/SKILL.md
```

Stock Codex discovers user-scoped skills there independently of `CODEX_HOME`.
The mixin writes no managed-workspace files and declares no commands or agent
context. It does declare the reviewed GitHub domains plus Docker's
proxy-managed `GITHUB_TOKEN` contract. The credential is optional so public
clone and non-GitHub work do not block sandbox creation. A host-side `github`
service secret is required for authenticated private clone, push, PR, and check
workflows; the real token never enters the VM.

Jam remains authoritative for exact-session runtime tools and attaches the
reviewed, immutable OCI-digest-pinned mixin only to new Managed Docker-backed
Codex runtime templates. The public source commit and release manifest identify
the reviewed source tree behind that artifact. The skill explains how to use
the injected clone, branch, commit, push, pull-request, inventory, readiness, and operation-status
tools; it cannot select another agent, room, runtime host, workspace, or
runtime session. Commit author and signing policy remain operator-owned runtime
template configuration and cannot be selected by the model.

The installed `sbx v0.34` consumer rejects the newer `requires.agent` schema
field, so the artifact cannot express Codex affinity in `spec.yaml` yet. Jam's
typed Managed-Codex default enforces that affinity. Add `requires.agent: codex`
only after the minimum supported Docker consumer accepts and enforces it.

Validate both schema normalization and the skill contract from the repository
root:

```sh
tests/managed-workspace-skill.test.sh
```
