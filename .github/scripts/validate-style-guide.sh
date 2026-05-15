#!/usr/bin/env bash
# Validate .github/ markdown files against STYLE-GUIDE.md conventions.
# Exit 0 = all pass, Exit 1 = failures found.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GITHUB_DIR="$REPO_ROOT/.github"
ERRORS=0

error() {
  echo "❌ $1"
  ERRORS=$((ERRORS + 1))
}

pass() {
  echo "✅ $1"
}

# Usage: fm_value "file" "key" — extract value from YAML frontmatter
fm_value() {
  local file="$1" key="$2"
  sed -n '/^---$/,/^---$/p' "$file" | grep -E "^${key}:" | head -1 | sed "s/^${key}:[[:space:]]*//" | sed "s/^['\"]//;s/['\"]$//"
}

fm_has_key() {
  local file="$1" key="$2"
  sed -n '/^---$/,/^---$/p' "$file" | grep -qE "^${key}:"
}

echo "========================================="
echo "  STYLE-GUIDE Validation"
echo "========================================="
echo ""

echo "📏 Instructions"
for file in "$GITHUB_DIR"/instructions/*.instructions.md; do
  [ -f "$file" ] || continue
  name="$(basename "$file")"

  if ! fm_has_key "$file" "description"; then
    error "$name: missing 'description' in frontmatter"
  fi

  if ! fm_has_key "$file" "applyTo"; then
    error "$name: missing 'applyTo' in frontmatter"
  fi

  if fm_has_key "$file" "description" && fm_has_key "$file" "applyTo"; then
    pass "$name"
  fi
done
echo ""

echo "⚡ Skills"
for file in "$GITHUB_DIR"/skills/*/SKILL.md; do
  [ -f "$file" ] || continue
  dir_name="$(basename "$(dirname "$file")")"

  if ! fm_has_key "$file" "name"; then
    error "skills/$dir_name/SKILL.md: missing 'name' in frontmatter"
    continue
  fi

  if ! fm_has_key "$file" "description"; then
    error "skills/$dir_name/SKILL.md: missing 'description' in frontmatter"
    continue
  fi

  skill_name="$(fm_value "$file" "name")"
  if [ "$skill_name" != "$dir_name" ]; then
    error "skills/$dir_name/SKILL.md: name='$skill_name' does not match directory '$dir_name'"
  fi

  desc="$(fm_value "$file" "description")"
  desc_len=${#desc}
  if [ "$desc_len" -gt 1024 ]; then
    error "skills/$dir_name/SKILL.md: description is $desc_len chars (max 1024)"
  fi

  if fm_has_key "$file" "tools"; then
    error "skills/$dir_name/SKILL.md: 'tools' field not allowed in skills (belongs on agents)"
  fi

  if [ "$skill_name" = "$dir_name" ] && [ "$desc_len" -le 1024 ] && ! fm_has_key "$file" "tools"; then
    pass "skills/$dir_name/SKILL.md ($desc_len chars)"
  fi
done
echo ""

echo "📋 Prompts"
for file in "$GITHUB_DIR"/prompts/*.prompt.md; do
  [ -f "$file" ] || continue
  name="$(basename "$file")"

  if ! fm_has_key "$file" "agent"; then
    error "$name: missing 'agent' in frontmatter"
  fi

  if ! fm_has_key "$file" "description"; then
    error "$name: missing 'description' in frontmatter"
  fi

  if fm_has_key "$file" "agent" && fm_has_key "$file" "description"; then
    pass "$name"
  fi
done
echo ""

echo "🤖 Agents"
for file in "$GITHUB_DIR"/agents/*.agent.md; do
  [ -f "$file" ] || continue
  name="$(basename "$file")"
  missing=""

  for key in name description model tools; do
    if ! fm_has_key "$file" "$key"; then
      missing="$missing $key"
    fi
  done

  if [ -n "$missing" ]; then
    error "$name: missing frontmatter fields:$missing"
  else
    pass "$name"
  fi
done
echo ""

echo "========================================="
if [ "$ERRORS" -gt 0 ]; then
  echo "  FAILED: $ERRORS error(s) found"
  echo "========================================="
  exit 1
else
  echo "  PASSED: all files valid"
  echo "========================================="
  exit 0
fi
