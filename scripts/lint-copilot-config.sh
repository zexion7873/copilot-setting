#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
GH="$ROOT/.github"
META="$SCRIPT_DIR/readme-meta.json"

errors=0
err() { echo "ERROR: $*" >&2; ((errors++)); }
info() { echo "  ✓ $*"; }

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required. Install via: brew install jq" >&2
  exit 1
fi

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

echo "=== Cross-Reference Lint ==="
echo ""

# ---------------------------------------------------------------
#  1. Every skill on disk must exist in readme-meta.json
# ---------------------------------------------------------------
echo "[1] Skills on disk vs readme-meta.json"
for f in "$GH"/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  sname=$(basename "$(dirname "$f")")
  if ! jq -e ".skills[\"$sname\"]" "$META" > /dev/null 2>&1; then
    err "Skill '$sname' exists on disk but missing from readme-meta.json"
  fi
done

for name in $(jq -r '.skills | keys[]' "$META"); do
  if [[ ! -f "$GH/skills/$name/SKILL.md" ]]; then
    err "Skill '$name' in readme-meta.json but file missing: .github/skills/$name/SKILL.md"
  fi
done
info "Skills ↔ meta sync checked"

# ---------------------------------------------------------------
#  2. Every agent on disk must exist in readme-meta.json
# ---------------------------------------------------------------
echo "[2] Agents on disk vs readme-meta.json"
for f in "$GH"/agents/*.agent.md; do
  [[ -f "$f" ]] || continue
  aname=$(basename "$f" .agent.md)
  if ! jq -e ".agents[\"$aname\"]" "$META" > /dev/null 2>&1; then
    err "Agent '$aname' exists on disk but missing from readme-meta.json"
  fi
done

for name in $(jq -r '.agents | keys[]' "$META"); do
  if [[ ! -f "$GH/agents/$name.agent.md" ]]; then
    err "Agent '$name' in readme-meta.json but file missing: .github/agents/$name.agent.md"
  fi
done
info "Agents ↔ meta sync checked"

# ---------------------------------------------------------------
#  3. Every instruction on disk must exist in readme-meta.json
# ---------------------------------------------------------------
echo "[3] Instructions on disk vs readme-meta.json"
for f in "$GH"/instructions/*.instructions.md; do
  [[ -f "$f" ]] || continue
  iname=$(basename "$f" .instructions.md)
  if ! jq -e ".instructions[\"$iname\"]" "$META" > /dev/null 2>&1; then
    err "Instruction '$iname' exists on disk but missing from readme-meta.json"
  fi
done

for name in $(jq -r '.instructions | keys[]' "$META"); do
  if [[ ! -f "$GH/instructions/$name.instructions.md" ]]; then
    err "Instruction '$name' in readme-meta.json but file missing: .github/instructions/$name.instructions.md"
  fi
done
info "Instructions ↔ meta sync checked"

# ---------------------------------------------------------------
#  4. Every prompt on disk must exist in readme-meta.json
# ---------------------------------------------------------------
echo "[4] Prompts on disk vs readme-meta.json"
for f in "$GH"/prompts/*.prompt.md; do
  [[ -f "$f" ]] || continue
  pname=$(basename "$f" .prompt.md)
  if ! jq -e ".prompts[\"$pname\"]" "$META" > /dev/null 2>&1; then
    err "Prompt '$pname' exists on disk but missing from readme-meta.json"
  fi
done

for name in $(jq -r '.prompts | keys[]' "$META"); do
  if [[ ! -f "$GH/prompts/$name.prompt.md" ]]; then
    err "Prompt '$name' in readme-meta.json but file missing: .github/prompts/$name.prompt.md"
  fi
done
info "Prompts ↔ meta sync checked"

# ---------------------------------------------------------------
#  5. Every skill must be referenced by at least one agent description
# ---------------------------------------------------------------
echo "[5] Skill → Agent binding"
all_agent_descs=""
for f in "$GH"/agents/*.agent.md; do
  [[ -f "$f" ]] || continue
  all_agent_descs+=" $(get_fm "$f" "description")"
done

for f in "$GH"/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  sname=$(basename "$(dirname "$f")")
  trigger=$(jq -r ".skills[\"$sname\"].trigger // \"auto\"" "$META" 2>/dev/null)
  if [[ "$trigger" == "manual" ]]; then
    continue
  fi
  if ! echo "$all_agent_descs" | grep -qF "\`$sname\`"; then
    err "Skill '$sname' is not referenced in any agent's description"
  fi
done
info "Skill → Agent bindings checked"

# ---------------------------------------------------------------
#  6. Skills referenced in agent descriptions must exist on disk
# ---------------------------------------------------------------
echo "[6] Agent description → Skill existence"
for f in "$GH"/agents/*.agent.md; do
  [[ -f "$f" ]] || continue
  aname=$(basename "$f" .agent.md)
  desc=$(get_fm "$f" "description")
  referenced_skills=$(printf '%s' "$desc" | grep -oE '[`][a-z][a-z0-9-]+[`]' | tr -d '`' | sort -u || true)
  for skill in $referenced_skills; do
    if [[ -d "$GH/skills/$skill" ]]; then
      continue
    fi
    err "Agent '$aname' references skill '$skill' but .github/skills/$skill/ does not exist"
  done
done
info "Agent → Skill references checked"

# ---------------------------------------------------------------
#  7. Order arrays in meta must match actual entries
# ---------------------------------------------------------------
echo "[7] Meta order arrays completeness"
for section in agents skills instructions prompts; do
  order_count=$(jq -r ".order.$section | length" "$META")
  keys_count=$(jq -r ".$section | keys | length" "$META")
  if [[ "$order_count" != "$keys_count" ]]; then
    err "order.$section has $order_count entries but $section has $keys_count entries — they must match"
  fi

  for name in $(jq -r ".$section | keys[]" "$META"); do
    if ! jq -e ".order.$section | index(\"$name\")" "$META" > /dev/null 2>&1; then
      err "'$name' exists in $section but missing from order.$section array"
    fi
  done
done
info "Order arrays checked"

# ---------------------------------------------------------------
echo ""
if ((errors > 0)); then
  echo "FAILED: $errors error(s) found."
  exit 1
else
  echo "PASSED: All cross-reference checks passed."
fi
