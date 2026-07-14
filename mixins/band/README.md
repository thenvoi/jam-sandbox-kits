# Band base mixin

This `kind: mixin` adds the minimum Band substrate to an existing Docker
Sandbox agent:

- proxy-managed Band bootstrap credential;
- allowlisted Band and reviewed artifact endpoints;
- a checksum-verified, commit-pinned registration helper installed at sandbox
  creation; and
- concise custody and network-policy context.

It deliberately does **not** ask the running model to discover and install an
arbitrary harness integration. Compose it with a separately reviewed,
versioned harness-specific mixin or bake that integration into the base
sandbox. This keeps installation deterministic and makes the network policy
auditable.

## Custody

The base mixin is T1 onboarding: the owner/register key remains behind the
Docker credential proxy, but registration returns a durable agent key into the
VM. Do not describe that as never-in-VM custody.

For T2 production custody, pre-register the agent and bind its agent-scoped key
as the proxy-managed `BAND_API_KEY`; do not run `band-register-agent`. In either
mode, deleting the sandbox does not revoke the Band identity or delete its
remote rooms, memories, or usage records.

## Determinism

The helper source is pinned to add-band commit
`bf68ea9a4977e83d1c0f66cf1baaab05d055910d` and SHA-256
`b679950af38224bd21fa54e5a3f88496fcdf80e0c034082853619bba0c3db9dd`.
Update the commit and digest together after review. A truncated or changed
download fails kit installation before any runtime command executes.

## Validation

Run both validation and normalized inspection; validation alone may accept a
credential block whose unknown fields are later discarded:

```sh
sbx kit validate .
sbx kit inspect . --json
```

The inspected credential must have non-empty `service`, `apiKey.name`,
`inject[].domain`, `header`, and `format`, with `proxyManaged: true`.

Remote Git kit references should be commit- or release-pinned and require the
Docker source allowlist to include `github.com/band-ai/`. Prefer publishing the
reviewed kit to Docker Hub, which remains the default permitted remote source.
