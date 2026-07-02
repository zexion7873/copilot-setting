#!/usr/bin/env bash
# Validates .github/ markdown against STYLE-GUIDE.md machine-checked rules:
#   - instructions: frontmatter has non-empty description + applyTo
#   - skills: name + description present; name matches directory; no tools
#     field; description <= 1024 chars; trigger markers on auto-invocable skills
#   - prompts: frontmatter has agent + non-empty description
#   - agents: frontmatter has name, description, model, tools; handoff
#     targets resolve to existing agent names
#   - cross-references: backtick-wrapped instructions/skills/agents/prompts
#     paths resolve to existing files
# Run: bash .github/scripts/validate-style-guide.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GH="$REPO_ROOT/.github"
ERRORS=0

err() { echo "ERROR: $1"; ERRORS=$((ERRORS + 1)); }

# Frontmatter block: line-1 '---' through the next '---' (tolerates CRLF);
# emitted only if the closing '---' exists, so unterminated frontmatter
# reports as missing keys instead of leaking body lines in.
fm_block() {
  awk '
    NR==1 && /^---\r?$/ {f=1; next}
    f && /^---\r?$/ {closed=1; exit}
    f {buf = buf $0 ORS}
    END {if (closed) printf "%s", buf}
  ' "$1"
}

# First-line scalar value of a frontmatter key, quotes/CR stripped.
fm_value() {
  fm_block "$1" | grep -m1 -E "^$2:" | sed -E "s/^$2:[[:space:]]*//" \
    | tr -d '\r' | sed -E "s/[[:space:]]+$//; s/^['\"]//; s/['\"]$//" || true
}

fm_has_key() { fm_block "$1" | grep -qE "^$2:"; }

# ── Instructions ─────────────────────────────────────────────────────
for f in "$GH"/instructions/*.instructions.md; do
  [ -e "$f" ] || continue
  rel="${f#"$REPO_ROOT"/}"
  [ -n "$(fm_value "$f" description)" ] || err "$rel: missing or empty 'description' (disables on-demand loading)"
  [ -n "$(fm_value "$f" applyTo)" ] || err "$rel: missing or empty 'applyTo' (file never loads)"
done

# ── Skills ───────────────────────────────────────────────────────────
for f in "$GH"/skills/*/SKILL.md; do
  [ -e "$f" ] || continue
  rel="${f#"$REPO_ROOT"/}"
  dir="$(basename "$(dirname "$f")")"
  name="$(fm_value "$f" name)"
  desc="$(fm_value "$f" description)"
  [ -n "$name" ] || err "$rel: missing 'name'"
  [ -n "$desc" ] || err "$rel: missing or empty 'description'"
  [ "$name" = "$dir" ] || err "$rel: name '$name' does not match directory '$dir'"
  [ "${#desc}" -le 1024 ] || err "$rel: description exceeds 1024 chars (${#desc})"
  if fm_has_key "$f" tools; then
    err "$rel: skills must not declare 'tools' (tools belong on agents)"
  fi
  if ! fm_block "$f" | grep -qE '^disable-model-invocation:[[:space:]]*true'; then
    for marker in 'Use when ' 'Triggers on:' 'Do NOT use'; do
      grep -qF "$marker" <<<"$desc" || err "$rel: description missing required marker '$marker'"
    done
  fi
done

# ── Prompts ──────────────────────────────────────────────────────────
for f in "$GH"/prompts/*.prompt.md; do
  [ -e "$f" ] || continue
  rel="${f#"$REPO_ROOT"/}"
  [ -n "$(fm_value "$f" agent)" ] || err "$rel: missing 'agent'"
  [ -n "$(fm_value "$f" description)" ] || err "$rel: missing or empty 'description'"
done

# ── Agents ───────────────────────────────────────────────────────────
AGENT_NAMES=""
for f in "$GH"/agents/*.agent.md; do
  [ -e "$f" ] || continue
  AGENT_NAMES="$AGENT_NAMES $(fm_value "$f" name)"
done

for f in "$GH"/agents/*.agent.md; do
  [ -e "$f" ] || continue
  rel="${f#"$REPO_ROOT"/}"
  for key in name description model tools; do
    fm_has_key "$f" "$key" || err "$rel: missing frontmatter key '$key'"
  done
  # Handoff targets (both "agent: X" and "- agent: X" forms) must match an
  # existing agent name case-sensitively.
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    grep -qw "$target" <<<"$AGENT_NAMES" || err "$rel: handoff target '$target' does not match any agent name"
  done < <(fm_block "$f" | grep -E '^[[:space:]]+(- )?agent:' \
    | sed -E "s/^[[:space:]]+(- )?agent:[[:space:]]*//; s/[[:space:]]+$//; s/^['\"]//; s/['\"]$//" | tr -d '\r')
done

# ── Cross-references ─────────────────────────────────────────────────
# Backtick-wrapped relative paths must resolve; globs (*) and placeholders
# (<>) are skipped by the regex character set.
while IFS=: read -r file ref; do
  [ -n "$ref" ] || continue
  [ -e "$GH/$ref" ] || err "${file#"$REPO_ROOT"/}: broken cross-reference \`$ref\`"
done < <(grep -rn -oE '`(instructions/[a-z0-9-]+\.instructions\.md|skills/[a-z0-9-]+/SKILL\.md|agents/[a-z0-9-]+\.agent\.md|prompts/[a-z0-9-]+\.prompt\.md)`' \
  "$GH" --include='*.md' 2>/dev/null | tr -d '`' | sed -E 's/:[0-9]+:/:/')

# ── Result ───────────────────────────────────────────────────────────
if [ "$ERRORS" -gt 0 ]; then
  echo "----------------------------------------"
  echo "$ERRORS error(s) found."
  exit 1
fi
echo "All style-guide checks passed."
