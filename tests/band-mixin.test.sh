#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
kit="$repo_root/mixins/band"
spec="$kit/spec.yaml"

fail() {
  printf 'band-mixin: %s\n' "$1" >&2
  exit 1
}

test -f "$spec" || fail "missing mixin spec"
command -v sbx >/dev/null 2>&1 || fail "sbx is required for canonical kit validation"

sbx kit validate "$kit" >/dev/null
inspection=$(sbx kit inspect "$kit" --json)

python3 -c '
import json, sys

artifact = json.load(sys.stdin)
manifest = artifact["manifest"]
assert manifest["schemaVersion"] == "2"
assert manifest["kind"] == "mixin"
assert manifest["name"] == "band-mixin"
assert not manifest.get("sandbox")

credentials = artifact["credentials"]
assert len(credentials) == 1
band = credentials[0]
assert band["service"] == "band"
assert band["required"] is True
api_key = band["apiKey"]
assert api_key["name"] == "BAND_API_KEY"
assert api_key["proxyManaged"] is True
assert api_key["inject"] == [{
    "domain": "app.band.ai",
    "header": "x-api-key",
    "format": "%s",
}]

allowed = set(artifact["caps"]["network"]["allow"])
assert allowed == {
    "app.band.ai:443",
    "github.com:443",
    "codeload.github.com:443",
    "raw.githubusercontent.com:443",
    "objects.githubusercontent.com:443",
    "pypi.org:443",
    "files.pythonhosted.org:443",
    "registry.npmjs.org:443",
    "api.anthropic.com:443",
    "api.openai.com:443",
}

commands = artifact["commands"]["install"]
assert len(commands) == 1
install = commands[0]
assert install["user"] == "0"
command = install["command"]
assert "bf68ea9a4977e83d1c0f66cf1baaab05d055910d" in command
assert "b679950af38224bd21fa54e5a3f88496fcdf80e0c034082853619bba0c3db9dd" in command
assert "sha256sum -c -" in command
assert "curl -fsSL -o" in command
assert "curl |" not in command

context = artifact["agentContext"]
assert "T1" in context and "custody" in context
assert "owner/register Band key" in context
assert "Do not print either credential" in context
assert "do not select or install arbitrary packages" in context
assert "sbx policy log" in context
' <<EOF
$inspection
EOF

# The public artifact may contain credential field names and Docker's sentinel
# contract, but never a concrete Band secret or an unpinned runtime download.
if rg -n '(band_[A-Za-z0-9]{24,}|sk-[A-Za-z0-9_-]{20,})' "$kit" >/dev/null; then
  fail "kit contains a token-shaped value"
fi

printf 'band-mixin: ok\n'
