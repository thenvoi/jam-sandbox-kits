# Jam empty MCP sentinel

This MCP server exposes one inert status tool and no prompts, resources, credentials, mounts,
or network access. Docker v0.39 rejects a static MCP backend that exposes zero tools, so the
status tool is the smallest usable sentinel. It only reports that no user-selected MCP
services are enabled.

Docker Sandboxes use dynamic MCP discovery when `--static-mcp` is absent.
Jam loads this server as the complete static set when an agent selects no external MCP servers.
That behavior prevents the guest from discovering host-registered services.

The image contains one static Go binary in a `scratch` image.
The server uses the official MCP Go SDK. Its sole tool is
`jam_empty_mcp_selection`; it cannot read, write, execute, or access the network.

Run the source tests with:

```sh
cd server
go test ./...
```

Build the image with:

```sh
docker build -t docker.io/vladthenvoi/jam-empty-mcp-sentinel:0.1.0 .
```

The published multi-platform release is pinned as:

```text
docker.io/vladthenvoi/jam-empty-mcp-sentinel@sha256:63a610c31e4f6be882bab1e2f28b5888e53bd2ea972965fa57c9b1fb2a3f4cc3
```

Register a development build with Docker's static MCP gateway using the
MCP Registry-compatible [`server.json`](server.json) descriptor. The descriptor
declares one OCI `stdio` package and intentionally declares no arguments,
environment variables, secrets, mounts, or remote endpoints.
