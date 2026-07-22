import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import http from "node:http";
import path from "node:path";
import readline from "node:readline";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const helper = path.join(
  root,
  "mixins/jam-managed-workspace/files/home/.local/bin/jam-local-platform-bridge",
);
const runtimeSessionId = "00000000-0000-4000-8000-000000000074";
const capability = "test-capability-do-not-log";

const child = spawn(process.execPath, [helper], {
  env: {
    PATH: process.env.PATH,
    JAM_LOCAL_BRIDGE_RUNTIME_SESSION_ID: runtimeSessionId,
    JAM_LOCAL_BRIDGE_CAPABILITY: capability,
    JAM_LOCAL_BRIDGE_PORT: "0",
  },
  stdio: ["pipe", "pipe", "pipe"],
});
let stderr = "";
let port = 0;
child.stderr.on("data", (chunk) => {
  stderr += chunk;
});
await new Promise((resolve, reject) => {
  const deadline = setTimeout(() => reject(new Error(`helper readiness timeout: ${stderr}`)), 5_000);
  child.stderr.on("data", () => {
    const match = stderr.match(/ready on guest loopback port (\d+)/);
    if (match) {
      port = Number(match[1]);
      clearTimeout(deadline);
      resolve();
    }
  });
  child.once("exit", (code) => reject(new Error(`helper exited ${code}: ${stderr}`)));
});

function request({ token, method = "GET", path = "/health", body = Buffer.alloc(0) }) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        host: "127.0.0.1",
        port,
        method,
        path,
        headers: {
          ...(token ? { "x-jam-bridge-capability": token } : {}),
          "content-type": "application/json",
          "content-length": String(body.length),
          "x-forwarded-host": "forbidden.example",
        },
      },
      (res) => {
        const chunks = [];
        res.on("data", (chunk) => chunks.push(chunk));
        res.on("end", () => resolve({ status: res.statusCode, body: Buffer.concat(chunks) }));
      },
    );
    req.once("error", reject);
    req.end(body);
  });
}

assert.equal((await request({})).status, 401);
assert.equal((await request({ token: "wrong" })).status, 401);

const lines = readline.createInterface({ input: child.stdout, crlfDelay: Infinity });
const framePromise = new Promise((resolve) => lines.once("line", (line) => resolve(JSON.parse(line))));
const clientPromise = request({
  token: capability,
  method: "POST",
  path: "/api/v1/runtime/usage?source=test",
  body: Buffer.from('{"hello":"world"}'),
});
const frame = await framePromise;
assert.equal(frame.kind, "http_request");
assert.equal(frame.runtime_session_id, runtimeSessionId);
assert.equal(frame.capability, capability);
assert.equal(frame.method, "POST");
assert.equal(frame.path, "/api/v1/runtime/usage?source=test");
assert.equal(Buffer.from(frame.body_base64, "base64").toString(), '{"hello":"world"}');
assert.equal(Object.hasOwn(frame, "origin"), false);
assert.equal(Object.hasOwn(frame, "host"), false);
assert.equal(frame.headers.some(([name]) => name === "host"), false);
assert.equal(frame.headers.some(([name]) => name === "x-forwarded-host"), false);
assert.equal(frame.headers.some(([name]) => name === "x-jam-bridge-capability"), false);

child.stdin.write(
  `${JSON.stringify({
    version: 1,
    kind: "http_response",
    request_id: frame.request_id,
    status: 201,
    headers: [["content-type", "application/json"]],
    body_base64: Buffer.from('{"accepted":true}').toString("base64"),
  })}\n`,
);
const client = await clientPromise;
assert.equal(client.status, 201);
assert.equal(client.body.toString(), '{"accepted":true}');

const oversized = await request({
  token: capability,
  method: "POST",
  path: "/large",
  body: Buffer.alloc(4 * 1024 * 1024 + 1),
});
assert.equal(oversized.status, 413);

assert.equal(stderr.includes(capability), false);
child.kill("SIGTERM");
await new Promise((resolve) => child.once("exit", resolve));
lines.close();
console.log("local-platform-bridge-helper: ok");
