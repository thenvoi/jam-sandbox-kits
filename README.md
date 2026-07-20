# Jam Docker Sandbox kits

Docker Sandbox kits, mixins, and verified runtime recipes used with
[Jam](https://github.com/thenvoi/tjam)-owned agent runtimes.

## Contents

| Path | Kind | Purpose |
|---|---|---|
| [`mixins/band`](./mixins/band/) | Docker Sandbox `mixin` | Adds Band network policy, proxy-managed bootstrap credentials, and deterministic self-onboarding context to an existing coding-agent sandbox. |
| [`mixins/jam-managed-workspace`](./mixins/jam-managed-workspace/) | Docker Sandbox `mixin` | Installs the native `jam-managed-workspace-v1` Codex skill for Jam-owned zero-to-many-repository workspaces without adding credentials, network policy, commands, or workspace files. |
| [`recipes/copilot-runtime.md`](./recipes/copilot-runtime.md) | Verified recipe | Runs Jam's owned Copilot SDK runtime through Docker's built-in `copilot` template; a custom image is unnecessary. |

## Ownership boundary

This repository owns assets for Jam and interactive coding-harness sandboxes.
Deployable Python and TypeScript SDK-agent images stay in their respective SDK
repositories. Jam core implementation stays in `thenvoi/tjam`.

The preferred Codex path uses Docker's built-in `codex` template and Jam's native
app-server stdio connection. Add a custom Codex kit here only when a concrete,
documented acceptance gate cannot be met by the built-in template.

`jam-managed-workspace` is intentionally a mixin rather than a custom Codex
image. It places one native skill under `$HOME/.agents/skills`, a stock Codex
discovery location that does not depend on `CODEX_HOME`. Jam supplies and scopes
the corresponding dynamic tools at runtime. The mixin does not duplicate that
authority or modify the Jam-owned source workspace.

## Safety and release rules

- Keep sandbox egress deny-by-default and allow only reviewed destinations.
- Use Docker proxy-managed credentials; never place real API keys in kit files.
- Pin remote source and OCI references immutably.
- Run both `sbx kit validate` and `sbx kit inspect --json`; validation alone does
  not prove that every intended field survived schema parsing.
- Publish versioned releases before referencing an asset from Jam production
  configuration.
- Consume Git-hosted kits by their full 40-character commit SHA; tags and
  branches are not immutable pins.

## Validation

Run the repository contract test after changing the managed-workspace skill:

```sh
tests/managed-workspace-skill.test.sh
```

It runs Docker's canonical kit validator/normalized inspector and verifies the
native skill location, protocol/tool contract, least-authority boundary, and
absence of credentials, commands, network policy, workspace files, or guest
host-control selectors.

## Published releases

The public GitHub repository is the reviewable source. Docker Hub carries the
OCI kit consumed by Docker Sandboxes so users do not need to expand Docker's
default `kit.allowedSources`. Jam pins the digest, never the mutable version tag.

| Kit | Source tree | Version tag | Immutable consumer reference |
|---|---|---|---|
| `jam-managed-workspace-v1` | `ca2c04df615961a688c292faa0cab325485f6412` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.0` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:ecc35d251eca1b079660094297f88752e87c9f322ff1cf28241bc669006e951c` |
| `jam-managed-workspace-v1` branch workflow | `f5982fd4064ecccd2322c30c827c00dcbe994db2` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.1` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:2f2e2c3fef8555051148aac5e151916b9ad5d3a0ee59b977e01f38a937877159` |

Machine-readable release records are under [`releases/`](./releases/); the latest is
[`jam-managed-workspace-1.0.1.json`](./releases/jam-managed-workspace-1.0.1.json).
Verify the exact artifact with:

```sh
sbx kit inspect 'docker.io/vladthenvoi/jam-managed-workspace@sha256:2f2e2c3fef8555051148aac5e151916b9ad5d3a0ee59b977e01f38a937877159' --json
```

The initial OCI release uses the authenticated publisher's `vladthenvoi`
namespace because that Docker Hub account has no `thenvoi` organization
membership. Moving the artifact later requires a fresh publication, digest,
release record, Jam pin, and consumer verification; a namespace alias is not
assumed.
