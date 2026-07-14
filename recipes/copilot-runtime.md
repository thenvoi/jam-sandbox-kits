# Copilot runtime "kit" (Phase 1) — a recipe, not an image

The planned "Copilot runtime kit" turned out to be **unnecessary as a custom
image**: sbx v0.34 ships a first-class `copilot` agent template and a
first-class `github` service secret. Everything the kit was going to build is
already in the substrate:

| Planned kit duty | Covered by |
|---|---|
| Copilot CLI in the VM | built-in template (`sbx create copilot …`) preinstalls GitHub Copilot CLI (`/home/agent/.local/bin/copilot`) |
| gh auth without leaking the token (SP-1) | `sbx secret set <sandbox> github` — in-VM `GH_TOKEN` is a **placeholder** (`gho_sbxproxymanaged000…`); the egress proxy substitutes the real token per request; token never in the VM (verified: prefix grep over `~`, `/run`, `/etc` finds nothing) |
| Workspace safety (J8) | native `--clone`: private in-container clone, host source mounted RO at `/run/sandbox/source`, commits recoverable via the `sandbox-<name>` git remote |
| Egress scope | the template's own policy (deny-by-default proxy) |

## The recipe

```bash
# 1. Secret FIRST — sbx bakes the credential mode at create time.
#    (A secret added later never flips SBX_CRED_GITHUB_MODE from `none`.)
gh auth token | sbx secret set <sandbox-name> github     # or -g for global

# 2. Create (jam's ensure path issues exactly this when missing):
sbx create copilot <workspace> --clone --name <sandbox-name>

# 3. Attach through jam (the Phase-1 patch):
jam attach --room <room> --runtime owned --transport copilot-sdk \
    --spawn-sandbox --spawn-sandbox-name <sandbox-name>
```

jam's copilot host then drives `sbx exec -i <name> -- copilot --server --stdio …`
(the SDK fork's `prefix_args` slot makes the wrap transparent), parks the VM on
teardown (`sbx stop`), and wakes it on the next spawn (`sbx exec` transparently
boots a stopped sandbox).

Jam records the authoritative sandbox plan outside the guest in its host state
directory and writes only a random binding nonce into the VM. Reuse requires
both to match; the agent cannot rewrite its session/workspace/template ownership.
Use `--no-spawn-sandbox` to explicitly disable a persisted sandbox setting.

## Verified runtime facts (2026-07-12, sbx v0.34.0, copilot CLI 1.0.65)

- A real Copilot turn completes inside the microVM authenticated purely by
  proxy injection (`copilot -p …` → answer + credits/token report).
- `sbx exec` cwd inside the VM = the workspace's **host path** (mount-at-same-
  path), so jam's `cwd` config passes through unchanged.
- Env for the runtime rides a short-lived fsynced 0600 `sbx exec --env-file` —
  host process env never crosses the VM boundary, and values do not appear in
  process argv (J7).
- `sbx rm` on a `--clone` sandbox **discards in-VM commits** unless
  `git fetch sandbox-<name>` ran first — jam's future reset path must fetch
  before removing (the Phase-1 patch documents this on `sandbox::remove`).
- `sbx rm` is interactive without `--force`.
- The per-turn CLI footer (credits + tokens up/down) is a J10 usage source
  candidate on top of the SDK protocol stream.

## What still deserves a real kit later

- A **Band mixin** (INT-977/978 style) if the sandboxed copilot agent must call
  Band tools directly from inside the VM — not needed for jam-owned runtimes
  (jam is outside the VM and owns the Band side).
- The **Codex runtime kit** (Phase 2) — codex has no placeholder-credential
  template parity yet; its LLM key rides the `openai`/`anthropic` service
  secrets the same way (`sbx secret set … openai`), to be verified at Phase 2.
