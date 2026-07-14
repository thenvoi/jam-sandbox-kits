# Jam Docker Sandbox kits

Docker Sandbox kits, mixins, and verified runtime recipes used with
[Jam](https://github.com/thenvoi/tjam)-owned agent runtimes.

## Contents

| Path | Kind | Purpose |
|---|---|---|
| [`mixins/band`](./mixins/band/) | Docker Sandbox `mixin` | Adds Band network policy, proxy-managed bootstrap credentials, and deterministic self-onboarding context to an existing coding-agent sandbox. |
| [`recipes/copilot-runtime.md`](./recipes/copilot-runtime.md) | Verified recipe | Runs Jam's owned Copilot SDK runtime through Docker's built-in `copilot` template; a custom image is unnecessary. |

## Ownership boundary

This repository owns assets for Jam and interactive coding-harness sandboxes.
Deployable Python and TypeScript SDK-agent images stay in their respective SDK
repositories. Jam core implementation stays in `thenvoi/tjam`.

The preferred Codex path uses Docker's built-in `codex` template and Jam's native
app-server stdio connection. Add a custom Codex kit here only when a concrete,
documented acceptance gate cannot be met by the built-in template.

## Safety and release rules

- Keep sandbox egress deny-by-default and allow only reviewed destinations.
- Use Docker proxy-managed credentials; never place real API keys in kit files.
- Pin remote source and OCI references immutably.
- Run both `sbx kit validate` and `sbx kit inspect --json`; validation alone does
  not prove that every intended field survived schema parsing.
- Publish versioned releases before referencing an asset from Jam production
  configuration.
