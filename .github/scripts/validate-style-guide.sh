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

  manual_only=false
  if fm_has_key "$file" "disable-model-invocation"; then
    if [ "$(fm_value "$file" "disable-model-invocation")" = "true" ]; then
      manual_only=true
    fi
  fi

  format_ok=true
  if [ "$manual_only" = "false" ]; then
    missing_markers=""
    echo "$desc" | grep -q "Use when " || missing_markers="$missing_markers 'Use when'"
    echo "$desc" | grep -q "Triggers on:" || missing_markers="$missing_markers 'Triggers on:'"
    echo "$desc" | grep -q "Do NOT use" || missing_markers="$missing_markers 'Do NOT use'"
    if [ -n "$missing_markers" ]; then
      error "skills/$dir_name/SKILL.md: description missing required markers:$missing_markers"
      format_ok=false
    fi
  fi

  if [ "$skill_name" = "$dir_name" ] && [ "$desc_len" -le 1024 ] && ! fm_has_key "$file" "tools" && [ "$format_ok" = "true" ]; then
    if [ "$manual_only" = "true" ]; then
      pass "skills/$dir_name/SKILL.md ($desc_len chars, manual-only)"
    else
      pass "skills/$dir_name/SKILL.md ($desc_len chars)"
    fi
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

echo "🔗 Cross-References"
# Canonical reference patterns checked here:
#   `instructions/<name>.instructions.md`
#   `skills/<name>/SKILL.md`
#   `prompts/<name>.prompt.md`
#   `agents/<name>.agent.md`
# Paths containing * (glob) or < > (illustrative placeholders) are skipped.
xref_errors_start=$ERRORS
while IFS= read -r file; do
  rel_file="${file#$REPO_ROOT/}"
  refs=$(grep -oE '`(instructions/[^`*<>]+\.instructions\.md|skills/[^`*<>]+/SKILL\.md|prompts/[^`*<>]+\.prompt\.md|agents/[^`*<>]+\.agent\.md)`' "$file" 2>/dev/null | tr -d '`' | sort -u || true)
  [ -z "$refs" ] && continue
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    target="$GITHUB_DIR/$ref"
    if [ ! -f "$target" ]; then
      error "$rel_file: references '$ref' but file does not exist"
    fi
  done <<< "$refs"
done < <(find "$GITHUB_DIR" -name "*.md" -type f)

if [ "$ERRORS" -eq "$xref_errors_start" ]; then
  pass "all canonical references resolve to existing files"
fi
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
