#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
GH="$ROOT/.github"

errors=0
err() { echo "ERROR: $*" >&2; ((errors++)); }
info() { echo "  ✓ $*"; }

get_fm() {
  local file="$1" key="$2"
  awk -v key="$key" '
    /^---[[:space:]]*$/ { fm++; next }
    fm == 1 {
      pat = "^" key ":"
      if ($0 ~ pat) {
        val = $0
        sub("^" key ":[[:space:]]*", "", val)
        gsub(/^'\''|'\''$/, "", val)
        gsub(/^"|"$/, "", val)
        print val
        exit
      }
    }
    fm >= 2 { exit }
  ' "$file"
}

has_cjk() {
  printf '%s' "$1" | jq -Rse 'test("[\\u4e00-\\u9fff]")' > /dev/null 2>&1
}

echo "=== Frontmatter Schema Validation ==="
echo ""

# ---------------------------------------------------------------
#  Skills
# ---------------------------------------------------------------
echo "[Skills]"
for f in "$GH"/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  sname=$(basename "$(dirname "$f")")

  name=$(get_fm "$f" "name")
  desc=$(get_fm "$f" "description")

  if [[ -z "$name" ]]; then
    err "Skill '$sname': missing 'name' in frontmatter"
  fi

  if [[ -z "$desc" ]]; then
    err "Skill '$sname': missing 'description' in frontmatter"
    continue
  fi

  if ! echo "$desc" | grep -qi "Do NOT use"; then
    err "Skill '$sname': description missing 'Do NOT use for' clause"
  fi

  if echo "$desc" | grep -qi "MANUAL ONLY"; then
    continue
  fi

  if ! has_cjk "$desc"; then
    err "Skill '$sname': description has no Chinese trigger phrases"
  fi

  if ! echo "$desc" | grep -qi "Triggers\? on:"; then
    err "Skill '$sname': description missing 'Triggers on:' section"
  fi
done
info "Skills checked"

# ---------------------------------------------------------------
#  Agents
# ---------------------------------------------------------------
echo "[Agents]"
for f in "$GH"/agents/*.agent.md; do
  [[ -f "$f" ]] || continue
  aname=$(basename "$f" .agent.md)

  name=$(get_fm "$f" "name")
  model=$(get_fm "$f" "model")
  desc=$(get_fm "$f" "description")

  if [[ -z "$name" ]]; then
    err "Agent '$aname': missing 'name' in frontmatter"
  fi

  if [[ -z "$model" ]]; then
    err "Agent '$aname': missing 'model' in frontmatter"
  fi

  if [[ -z "$desc" ]]; then
    err "Agent '$aname': missing 'description' in frontmatter"
  fi
done
info "Agents checked"

# ---------------------------------------------------------------
#  Instructions
# ---------------------------------------------------------------
echo "[Instructions]"
for f in "$GH"/instructions/*.instructions.md; do
  [[ -f "$f" ]] || continue
  iname=$(basename "$f" .instructions.md)

  desc=$(get_fm "$f" "description")
  apply=$(get_fm "$f" "applyTo")

  if [[ -z "$desc" ]]; then
    err "Instruction '$iname': missing 'description' in frontmatter"
  fi

  if [[ -z "$apply" ]]; then
    err "Instruction '$iname': missing 'applyTo' in frontmatter"
  fi
done
info "Instructions checked"

# ---------------------------------------------------------------
#  Prompts (lightweight — no required fields beyond existence)
# ---------------------------------------------------------------
echo "[Prompts]"
for f in "$GH"/prompts/*.prompt.md; do
  [[ -f "$f" ]] || continue
  pname=$(basename "$f" .prompt.md)

  has_frontmatter=$(awk '/^---[[:space:]]*$/{c++} c==2{print "yes"; exit}' "$f")
  if [[ "$has_frontmatter" != "yes" ]]; then
    err "Prompt '$pname': no YAML frontmatter detected"
  fi
done
info "Prompts checked"

# ---------------------------------------------------------------
echo ""
if ((errors > 0)); then
  echo "FAILED: $errors error(s) found."
  exit 1
else
  echo "PASSED: All frontmatter schema checks passed."
fi
