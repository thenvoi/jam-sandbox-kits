#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
kit="$repo_root/mixins/jam-managed-workspace"
skill="$kit/files/home/.agents/skills/jam-managed-workspace/SKILL.md"
release="$repo_root/releases/jam-managed-workspace-1.0.1.json"

fail() {
  printf 'managed-workspace-skill: %s\n' "$1" >&2
  exit 1
}

test -f "$kit/spec.yaml" || fail "missing mixin spec"
test -f "$skill" || fail "missing native Codex skill"
test -f "$release" || fail "missing immutable release manifest"

git -C "$repo_root" diff --quiet --cached --diff-filter=D -- "$kit" \
  || fail "reviewed kit files may not be deleted from the release tree"
git -C "$repo_root" diff --quiet -- "$kit" \
  || fail "stage kit changes before validating release metadata"
expected_tree=$(git -C "$repo_root" write-tree --prefix=mixins/jam-managed-workspace/)
actual_tree=$(jq -r '.sourceTree' "$release")
test "$actual_tree" = "$expected_tree" || fail "release source tree does not match the reviewed kit"
jq -e '
  .schemaVersion == 1 and
  .name == "jam-managed-workspace" and
  .contract == "jam-managed-workspace-v1" and
  .ociTag == "docker.io/vladthenvoi/jam-managed-workspace:1.0.1" and
  (.ociDigest | test("^docker.io/vladthenvoi/jam-managed-workspace@sha256:[0-9a-f]{64}$"))
' "$release" >/dev/null || fail "invalid immutable release manifest"

command -v sbx >/dev/null 2>&1 || fail "sbx is required for canonical kit validation"
sbx kit validate "$kit" >/dev/null

inspection=$(sbx kit inspect "$kit" --json)
python3 -c '
import json, sys
artifact = json.load(sys.stdin)
manifest = artifact["manifest"]
assert manifest["schemaVersion"] == "2"
assert manifest["kind"] == "mixin"
assert manifest["name"] == "jam-managed-workspace"
assert "Codex" in manifest["description"]
for forbidden in ("requires", "credentials", "caps", "environment", "commands", "agentContext"):
    assert not manifest.get(forbidden), forbidden
files = artifact["files"]
assert {f["relativePath"] for f in files} == {
    ".agents/skills/jam-managed-workspace/SKILL.md",
    ".agents/skills/jam-managed-workspace/agents/openai.yaml",
}
assert all(f["target"] == "home" for f in files)
' <<EOF
$inspection
EOF

first_line=$(sed -n '1p' "$skill")
test "$first_line" = "---" || fail "SKILL.md must start with YAML frontmatter"
test "$(rg -n '^name:' "$skill" | wc -l | tr -d ' ')" = "1" || fail "skill must declare one name"
test "$(rg -n '^description:' "$skill" | wc -l | tr -d ' ')" = "1" || fail "skill must declare one description"
rg -q '^name: jam-managed-workspace$' "$skill" || fail "unexpected skill name"

for required in \
  jam-managed-workspace-v1 \
  WorkspaceRepositories \
  WorkspaceGitHubReadiness \
  WorkspaceClone \
  WorkspaceBranch \
  WorkspaceOperation \
  'zero, one, or many' \
  'Band board' \
  'task tools' \
  'dirty or unpushed' \
  'local platform bridge' \
  'Guest `localhost`'; do
  rg -Fq "$required" "$skill" || fail "missing required contract text: $required"
done

for forbidden in \
  --runtime-session \
  'jam runtime workspace-' \
  BAND_API_KEY \
  BAND_AGENT_API_KEY \
  GH_TOKEN \
  GITHUB_TOKEN \
  OPENAI_API_KEY; do
  if rg -Fq -- "$forbidden" "$skill"; then
    fail "skill contains forbidden selector, guest CLI path, or secret name: $forbidden"
  fi
done

printf 'managed-workspace-skill: ok\n'
