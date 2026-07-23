# Jam Docker Sandbox kits

Docker Sandbox kits, mixins, and verified runtime recipes used with
[Jam](https://github.com/thenvoi/tjam)-owned agent runtimes.

## Contents

| Path | Kind | Purpose |
|---|---|---|
| [`mixins/band`](./mixins/band/) | Docker Sandbox `mixin` | Adds Band network policy, proxy-managed bootstrap credentials, and deterministic self-onboarding context to an existing coding-agent sandbox. |
| [`mixins/jam-managed-workspace`](./mixins/jam-managed-workspace/) | Docker Sandbox `mixin` | Installs the native `jam-managed-workspace-v1` Codex skill and the guest half of Jam's authenticated local-platform bridge, requests the reviewed remote Developer destinations, and adds a host-proxied GitHub credential contract for Jam-owned zero-to-many-repository workspaces. |
| [`recipes/copilot-runtime.md`](./recipes/copilot-runtime.md) | Verified recipe | Runs Jam's owned Copilot SDK runtime through Docker's built-in `copilot` template; a custom image is unnecessary. |

## Ownership boundary

This repository owns assets for Jam and interactive coding-harness sandboxes.
Deployable Python and TypeScript SDK-agent images stay in their respective SDK
repositories. Jam core implementation stays in `thenvoi/tjam`.

The preferred Codex path uses Docker's built-in `codex` template and Jam's native
app-server stdio connection. Add a custom Codex kit here only when a concrete,
documented acceptance gate cannot be met by the built-in template.

For this Jam-owned path, Band connectivity, durable queues, acknowledgements,
and custody keys remain in host-side `jamd`; the guest receives messages, not a
Band credential. The separate `band` self-onboarding mixin serves a different
architecture in which the sandboxed agent itself becomes the Band peer.

`jam-managed-workspace` is intentionally a mixin rather than a custom Codex
image. It places one native skill under `$HOME/.agents/skills`, a stock Codex
discovery location that does not depend on `CODEX_HOME`. Jam supplies and scopes
the corresponding dynamic tools at runtime. The mixin does not duplicate that
authority or modify the Jam-owned source workspace. Its GitHub declaration is
the Docker-side half of the host `github` service-secret contract; only the
`proxy-managed` sentinel enters the guest.

The mixin also installs `~/.local/bin/jam-local-platform-bridge`. Jam starts one
instance for an explicitly enabled runtime session and injects a short-lived,
session-scoped capability into that Codex thread. The helper listens only on
guest loopback and forwards bounded HTTP requests and WebSocket byte streams
over its owned stdio channel; it contains no host destination, credential, or
persistent authority. WebSocket upgrades reject extensions, replace the
attacker-controlled origin with Jam's fixed numeric-loopback upstream, and
preserve the exact handshake and data bytes end to end. Jam owns the fixed host
destination, authorization lease, rate and concurrency limits, logging,
cancellation, and cleanup. Jam bootstraps the helper over the same private stdio
channel, so the capability never appears in `sbx exec` arguments and does not
depend on Docker CLI environment-file forwarding. Installing the helper alone
does not enable host access.

The remote Developer destination set includes Band/runtime services, GitHub,
and common package/container registries. It is requested policy, not effective
policy: Docker organization governance can replace local and kit rules. Jam
must inspect Docker's effective decision separately. Configured staging and
approved corporate public HTTPS endpoints are runtime configuration and are
therefore intentionally absent from this public static artifact.

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
native skill and bridge-helper locations, HTTP/WebSocket protocol and tool contract,
least-authority boundary, exact proxy-managed GitHub injection/domains, and
absence of commands, workspace files, raw credentials, or guest host-control
selectors. The helper's independent regression is:

```sh
node tests/local-platform-bridge-helper.test.mjs
```

Validate the standalone Band self-onboarding mixin with:

```sh
tests/band-mixin.test.sh
```

This freezes the normalized proxy-managed credential injection, exact reviewed
helper source and checksum, network allowlist, T1 custody disclosure, and the
absence of a custom sandbox image or entrypoint.

## Published releases

The public GitHub repository is the reviewable source. Docker Hub carries the
OCI kit consumed by Docker Sandboxes so users do not need to expand Docker's
default `kit.allowedSources`. Jam pins the digest, never the mutable version tag.

| Kit | Source tree | Version tag | Immutable consumer reference |
|---|---|---|---|
| `band-mixin-v1` | `58720cdbbe95985665eb776281d234ac5984f126` | `docker.io/vladthenvoi/band-mixin:1.0.0` | `docker.io/vladthenvoi/band-mixin@sha256:79f9ba8f6a83d560f20f82ed7d86604f8c5400c3b9c12386e3df1a015d65d8df` |
| `jam-managed-workspace-v1` | `ca2c04df615961a688c292faa0cab325485f6412` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.0` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:ecc35d251eca1b079660094297f88752e87c9f322ff1cf28241bc669006e951c` |
| `jam-managed-workspace-v1` branch workflow | `f5982fd4064ecccd2322c30c827c00dcbe994db2` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.1` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:2f2e2c3fef8555051148aac5e151916b9ad5d3a0ee59b977e01f38a937877159` |
| `jam-managed-workspace-v1` commit workflow | `ec7647c57d8517d11699824720de01ed259ba911` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.2` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:9e10c38ebd5c2e4b633f1b627f3d6cd6104386e84bcaa9617b3cb972af87a6ab` |
| `jam-managed-workspace-v1` push/GitHub proxy workflow | `ed860dec51670a76e47d9690cf93eaec055e726d` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.3` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:52af5751b22dcd028aa8459c7db7972fb63fb519d048f60dc46965af4cb8c105` |
| `jam-managed-workspace-v1` optional GitHub proxy workflow | `50898bd01edc5413fac1e41cd53026817389559c` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.4` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:95aad9693a9dcc5d7b487cb94b0ed4c85a821114483fecdc012df7d076c2cceb` |
| `jam-managed-workspace-v1` pull-request workflow | `fed8bf0a28f15991ebacb4a60dd54cb6eb83e845` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.5` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:a26dfab23184101a907b9dbaa1eb560582fd1f747c20813094db9dce490443ea` |
| `jam-managed-workspace-v1` check-inspection workflow | `51e2a86bee0161930445f862f351a018e9ecd2a1` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.6` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:d0457e006f7a59dbb2504527a0600357e30d291d2d4870e2d893abc89beab5df` |
| `jam-managed-workspace-v1` Developer network request | `419e8803f66a18c830b674797828c9219d893757` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.7` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:42d5cf09741a855fc731da689dfe99e16007d68d2675487ee6bf090679c42c38` |
| `jam-managed-workspace-v1` authenticated local-platform bridge helper | `8827cf8f50b39b959b7b0ba6cfb7480873a88238` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.8` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:8b9c60e1a26cbd192362f0bc561766811dbf861012164f6d396701870db6555d` |
| `jam-managed-workspace-v1` private-stdio bridge bootstrap | `39713bbed21228733d198b397ef8a774d1f94d12` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.9` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:a0162714988e895d6060eded0427b17869217b9fb74a7c60c663da7c67e70cb0` |
| `jam-managed-workspace-v1` bounded large bridge responses | `d30e1905e5822b8d15ffadd56d9291f949e22a17` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.10` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:fd2985ed03d84b586a2e14f4192f7dbda4a1686483c68b2e6cb6e6749bd83f13` |
| `jam-managed-workspace-v1` bounded WebSocket bridge | `650e47777f77407f9851bb6ae74a16c272e4db69` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.11` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:0cafdc8427ced357244f3e1c38ec56df65cde02b617e408bfc7b07a6b1d3ef60` |
| `jam-managed-workspace-v1` runtime-host trust boundaries | `711b5614791e6bc56cf9486359673d427ff8bdf6` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.12` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:78e2557fd60f8da8ed80adba067525fd663576d53a84394c547070de9b452261` |
| `jam-managed-workspace-v1` host-owned Band custody boundary | `9692e77ea63207fef092f4d5b699dff3c4577f93` | `docker.io/vladthenvoi/jam-managed-workspace:1.0.13` | `docker.io/vladthenvoi/jam-managed-workspace@sha256:caa53c556adfb0f48f9658de49d1aa3c2221b9c086de9c60a46df544713600e4` |

Machine-readable release records are under [`releases/`](./releases/). The Band
mixin record is [`band-mixin-1.0.0.json`](./releases/band-mixin-1.0.0.json), and
the latest managed-workspace record is
[`jam-managed-workspace-1.0.13.json`](./releases/jam-managed-workspace-1.0.13.json).
Verify the exact artifacts with:

```sh
sbx kit inspect 'docker.io/vladthenvoi/band-mixin@sha256:79f9ba8f6a83d560f20f82ed7d86604f8c5400c3b9c12386e3df1a015d65d8df' --json
sbx kit inspect 'docker.io/vladthenvoi/jam-managed-workspace@sha256:caa53c556adfb0f48f9658de49d1aa3c2221b9c086de9c60a46df544713600e4' --json
```

To use the standalone Band mixin, store the bootstrap key under the kit's
`band` service, then create the sandbox interactively so Docker can ask you to
approve injection only to `app.band.ai`:

```sh
sbx secret set -g band
sbx run codex --kit 'docker.io/vladthenvoi/band-mixin@sha256:79f9ba8f6a83d560f20f82ed7d86604f8c5400c3b9c12386e3df1a015d65d8df' .
```

That first consent creates the user-owned credential binding. A non-interactive
create without an existing binding starts without injection and reports a
warning; storing the secret alone does not authorize a destination. Compose a
reviewed harness-specific Band integration as another kit or provide it in the
base sandbox—the base mixin installs only the deterministic registration
helper.

The initial OCI release uses the authenticated publisher's `vladthenvoi`
namespace because that Docker Hub account has no `thenvoi` organization
membership. Moving the artifact later requires a fresh publication, digest,
release record, Jam pin, and consumer verification; a namespace alias is not
assumed.
