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

  if fm_has_key "$file" "applyTo"; then
    apply_to="$(fm_value "$file" "applyTo")"
    if [ -z "$apply_to" ]; then
      error "$name: 'applyTo' is empty (instruction will never load)"
    fi
  fi

  if fm_has_key "$file" "description" && fm_has_key "$file" "applyTo"; then
    apply_to="$(fm_value "$file" "applyTo")"
    if [ -n "$apply_to" ]; then
      pass "$name"
    fi
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

echo "🔗 Instruction Reference (code-touching skills)"
# Skills that modify or review Java code must name the canonical instruction
# file(s) they map to, so the agent can open them on demand when the skill is
# triggered. The condensed floor was removed — hard-boundary rules now live in
# the code-touching agent bodies (## Coding Standards), which load
# deterministically on agent selection.
INSTRUCTION_REF_SKILLS="implement refactor code-review sql-review security-audit debug performance schema-migration-review pom-review"
ref_errors_start=$ERRORS
for skill in $INSTRUCTION_REF_SKILLS; do
  file="$GITHUB_DIR/skills/$skill/SKILL.md"
  if [ ! -f "$file" ]; then
    error "instruction reference check: skills/$skill/SKILL.md not found"
    continue
  fi
  # Must name at least one specific instruction file (not just the *.glob)
  if ! grep -qE '`instructions/[a-z][a-z-]*\.instructions\.md`' "$file"; then
    error "skills/$skill/SKILL.md: must name a specific instruction file (e.g. \`instructions/sql.instructions.md\`)"
  fi
done

if [ "$ERRORS" -eq "$ref_errors_start" ]; then
  pass "all code-touching skills reference their instruction files"
fi
echo ""

echo "🤖 Agent Coding Standards (code-touching agents)"
# Hard-boundary rules are embedded in code-touching agent bodies so they load
# deterministically when the agent is selected (independent of attached files).
CODE_AGENTS="implementer reviewer debugger"
ca_errors_start=$ERRORS
for a in $CODE_AGENTS; do
  file="$GITHUB_DIR/agents/$a.agent.md"
  if [ ! -f "$file" ]; then
    error "agent coding standards check: agents/$a.agent.md not found"
    continue
  fi
  if ! grep -q "^## Coding Standards" "$file"; then
    error "agents/$a.agent.md: missing '## Coding Standards' section (hard-boundary rules must be embedded)"
  fi
done
if [ "$ERRORS" -eq "$ca_errors_start" ]; then
  pass "all code-touching agents embed Coding Standards"
fi
echo ""

echo "📋 Prompts"
if [ -d "$GITHUB_DIR/prompts" ]; then
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
else
  pass "no prompt files"
fi
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

  handoff_agents=$(sed -n '/^---$/,/^---$/p' "$file" | grep -E '^\s+agent:' | sed 's/.*agent:[[:space:]]*//' | sed "s/^['\"]//;s/['\"]$//" || true)
  if [ -n "$handoff_agents" ]; then
    while IFS= read -r target_agent; do
      [ -z "$target_agent" ] && continue
      # Case-sensitive match — VS Code handoff buttons require exact agent name (see STYLE-GUIDE rule 6).
      found=false
      for agent_file in "$GITHUB_DIR"/agents/*.agent.md; do
        [ -f "$agent_file" ] || continue
        agent_name="$(fm_value "$agent_file" "name")"
        if [ "$target_agent" = "$agent_name" ]; then
          found=true
          break
        fi
      done
      if [ "$found" = "false" ]; then
        error "$name: handoff references agent '$target_agent' but no matching agent name found (case-sensitive)"
      fi
    done <<< "$handoff_agents"
  fi
done
echo ""

echo "📊 Anti-Patterns Tables (instructions only)"
ap_errors_start=$ERRORS
for file in "$GITHUB_DIR"/instructions/*.instructions.md; do
  [ -f "$file" ] || continue
  name="$(basename "$file")"
  if grep -q "^## Anti-Patterns" "$file"; then
    if ! grep -qE '^\|\s*Pattern\s*\|\s*Problem\s*\|\s*Fix\s*\|' "$file"; then
      error "$name: has '## Anti-Patterns' section but missing 3-column header (Pattern | Problem | Fix)"
    fi
  fi
done

if [ "$ERRORS" -eq "$ap_errors_start" ]; then
  pass "all instruction Anti-Patterns tables use 3-column format"
fi
echo ""

echo "🔗 Cross-References"
# Canonical reference patterns checked here:
#   `instructions/<name>.instructions.md`
#   `skills/<name>/SKILL.md`
#   `agents/<name>.agent.md`
# Paths containing * (glob) or < > (illustrative placeholders) are skipped.
xref_errors_start=$ERRORS
while IFS= read -r file; do
  rel_file="${file#$REPO_ROOT/}"
  refs=$(grep -oE '`(instructions/[^`*<>]+\.instructions\.md|skills/[^`*<>]+/SKILL\.md|agents/[^`*<>]+\.agent\.md)`' "$file" 2>/dev/null | tr -d '`' | sort -u || true)
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
