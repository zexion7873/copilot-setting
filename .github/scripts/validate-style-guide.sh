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

# Usage: fm_block "file" — print ONLY the leading YAML frontmatter block.
# Restricted to the first '---' (line 1) through the next '---', so body-level
# '---' horizontal rules cannot re-open the slice. The block is buffered and
# emitted ONLY if a closing '---' is found: an unterminated frontmatter (a
# common merge/truncation artifact) is not valid frontmatter to Copilot's
# parser, so we must not let body keys leak in and pass. The '\r?' tolerates
# CRLF line endings (a Windows contributor with autocrlf misset) — without it
# '---\r' fails /^---$/ and a perfectly valid file reports missing keys.
fm_block() {
  awk '
    NR==1 && /^---\r?$/ {f=1; next}
    f && /^---\r?$/ {closed=1; exit}
    f {buf = buf $0 ORS}
    END {if (closed) printf "%s", buf}
  ' "$1"
}

# Usage: fm_value "file" "key" — extract value from YAML frontmatter.
# '|| true': grep exits 1 when the key is absent and pipefail propagates it past
# the seds; without the guard, any bare assignment ($(fm_value ...)) kills the
# whole script under set -e with no diagnostic (same class as the cs_bullets
# guard below). A missing key legitimately yields an empty string.
# Strip order matters: drop CR and trailing whitespace BEFORE the quote strip,
# so a CRLF value ("plan'\r") or a trailing space ("plan ", legal YAML the
# parser ignores) does not defeat the closing-quote anchor or the name match.
fm_value() {
  local file="$1" key="$2"
  fm_block "$file" | grep -E "^${key}:" | head -1 \
    | sed "s/^${key}:[[:space:]]*//" \
    | tr -d '\r' \
    | sed 's/[[:space:]]*$//' \
    | sed "s/^['\"]//;s/['\"]$//" || true
}

# Usage: fm_scalar_multiline "file" "key" — exit 0 if KEY's scalar value spans
# more than one physical line. fm_value reads only the key's own line, so a
# multi-line plain/quoted scalar is measured by its first line alone and slips
# past the 1024-char cap. A YAML scalar continuation must be indented deeper
# than the key, so "the line after the key line is indented" detects it. Scoped
# to scalar keys only (NOT block keys like handoffs/tools, which are legitimately
# indented). Mirrors the existing block-scalar (|/>) rejection: multi-line values
# are not parsed by this validator, so they are an error, not a measurement.
fm_scalar_multiline() {
  fm_block "$1" | awk -v key="$2" '
    seen { if ($0 ~ /^[[:space:]]+[^[:space:]]/) ml = 1; exit }
    $0 ~ "^" key ":" { seen = 1 }
    END { exit (ml ? 0 : 1) }
  '
}

fm_has_key() {
  local file="$1" key="$2"
  fm_block "$file" | grep -qE "^${key}:"
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
  elif [ -z "$(fm_value "$file" "description")" ]; then
    # Empty like applyTo: on-demand semantic loading matches against the
    # description, so a blank one silently disables that channel.
    error "$name: 'description' is empty (on-demand loading will never match)"
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

  # Same single-line-scalar rule as agents: a block scalar would be measured as
  # the literal '>-'/'|' (2 chars) and silently pass every downstream check.
  if fm_block "$file" | grep -qE '^description:[[:space:]]*[|>]'; then
    error "skills/$dir_name/SKILL.md: description must be a single-line scalar (YAML block scalars |/> are not parsed by the validator)"
    continue
  fi

  # A multi-line plain/quoted scalar is not a block scalar, so the guard above
  # misses it — yet fm_value measures only its first line, letting it slip past
  # the 1024-char cap below. Reject it for the same reason: not parsed here.
  if fm_scalar_multiline "$file" "description"; then
    error "skills/$dir_name/SKILL.md: description must be a single-line scalar (multi-line YAML values are not parsed by the validator and bypass the 1024-char cap)"
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
INSTRUCTION_REF_SKILLS="implement refactor code-review sql-review security-audit debug"
ref_errors_start=$ERRORS
for skill in $INSTRUCTION_REF_SKILLS; do
  file="$GITHUB_DIR/skills/$skill/SKILL.md"
  if [ ! -f "$file" ]; then
    error "instruction reference check: skills/$skill/SKILL.md not found"
    continue
  fi
  # Must name at least one specific instruction file (not just the *.glob).
  # Digits allowed in the stem ([a-z][a-z0-9-]*) so a name like java8 resolves
  # — the xref check already accepts digits, and the two must agree.
  if ! grep -qE '`instructions/[a-z][a-z0-9-]*\.instructions\.md`' "$file"; then
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
  # Coding Standards may contain ONLY a column-0 intro paragraph, blank lines,
  # and top-level '- ' bullets. Reject any indented line (a plain indented
  # continuation renders as part of the bullet above it, drifting the hard
  # boundary, yet has no leading dash so cs_bullets never compares it) and any
  # column-0 '*'/'+'/numbered item (which would also escape the '- ' compare).
  if awk '/^## Coding Standards/{f=1; next} f && /^## /{exit} f' "$file" | grep -qE '^[[:space:]]+[^[:space:]]|^([*+]|[0-9]+\.)([[:space:]]|$)'; then
    error "agents/$a.agent.md: Coding Standards must use only top-level '- ' bullets (indented lines, */+ bullets, or numbered items escape the drift guard)"
  fi
done

# Drift guard: the hard-boundary bullets (lines starting with '- ') must be
# byte-identical across all code-touching agents. Only the intro sentence may
# differ per-agent voice ("Code you write" vs "Any fix you propose" vs "Flag
# any violation"). This is the sanctioned duplication from CLAUDE.md — a machine
# check so a version-lock edit to one agent cannot silently skip the others.
cs_bullets() {
  awk '/^## Coding Standards/{f=1; next} f && /^## /{exit} f' "$1" | grep -E '^- '
}
# grep exits 1 when the section has zero '- ' bullets; without '|| true' the
# bare assignment kills the whole script under set -e with no diagnostic.
ref_bullets="$(cs_bullets "$GITHUB_DIR/agents/implementer.agent.md" || true)"
if [ -z "$ref_bullets" ]; then
  error "agents/implementer.agent.md: '## Coding Standards' has no top-level '- ' bullets (drift guard has no reference to compare)"
fi
for a in $CODE_AGENTS; do
  [ "$a" = "implementer" ] && continue
  file="$GITHUB_DIR/agents/$a.agent.md"
  [ -f "$file" ] || continue
  if [ "$(cs_bullets "$file")" != "$ref_bullets" ]; then
    error "agents/$a.agent.md: Coding Standards hard-boundary bullets drifted from implementer (must be byte-identical — only the intro sentence may differ)"
  fi
done

if [ "$ERRORS" -eq "$ca_errors_start" ]; then
  pass "all code-touching agents embed Coding Standards (and hard-boundary bullets match)"
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
    elif [ -z "$(fm_value "$file" "description")" ]; then
      error "$name: 'description' is empty"
    fi

    if fm_block "$file" | grep -qE '^(description|agent):[[:space:]]*[|>]'; then
      error "$name: frontmatter values must be single-line scalars (YAML block scalars |/> are not parsed by the validator)"
    elif fm_has_key "$file" "agent" && fm_has_key "$file" "description" && [ -n "$(fm_value "$file" "description")" ]; then
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
  elif fm_block "$file" | grep -qE '^description:[[:space:]]*[|>]'; then
    error "$name: description must be a single-line scalar (YAML block scalars |/> are not parsed by the validator)"
  else
    pass "$name"
  fi

  # Match both the standalone form ('    agent: X') and the list-item form
  # ('  - agent: X', the most common YAML list-of-mappings style) — the bare
  # '^\s+agent:' missed the dash-line form, so a broken handoff ref written
  # that way was invisible and passed.
  handoff_agents=$(fm_block "$file" | grep -E '^[[:space:]]*-?[[:space:]]*agent:' | sed 's/.*agent:[[:space:]]*//' | tr -d '\r' | sed 's/[[:space:]]*$//' | sed "s/^['\"]//;s/['\"]$//" || true)
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

  # Consistency: declaring subagents (agents:) requires the 'agent' tool to invoke them
  # (VS Code: "If you specify agents, ensure the agent tool is included in tools").
  if fm_has_key "$file" "agents"; then
    # Capture the tools: line plus any following YAML block-list items, so both
    # inline (tools: ['agent']) and block-list (tools: then '  - agent') forms are seen.
    # Quotes are stripped before matching so unquoted, single- and double-quoted
    # 'agent' all count; the boundary classes reject near-misses (vscode/agent,
    # agent-foo, useragent).
    tools_block=$(fm_block "$file" | awk '/^tools:/{f=1; print; next} f && /^[[:space:]]*-/{print; next} f{exit}')
    if ! printf '%s\n' "$tools_block" | tr -d "'\"" | grep -qE "(^|[][,[:space:]])agent([][,[:space:]]|$)"; then
      error "$name: declares 'agents:' but 'tools' lacks 'agent' — subagent delegation will not work"
    fi
  fi
done
echo ""

echo "📊 Anti-Patterns Tables (instructions only)"
ap_errors_start=$ERRORS
for file in "$GITHUB_DIR"/instructions/*.instructions.md; do
  [ -f "$file" ] || continue
  name="$(basename "$file")"
  if grep -q "^## Anti-Patterns" "$file"; then
    # Scope to the Anti-Patterns section and anchor at end-of-line, so a matching
    # header elsewhere in the file does not satisfy the check and a 4+-column
    # header (| Pattern | Problem | Fix | Extra |) is rejected.
    if ! awk '/^## Anti-Patterns/{f=1; next} f && /^## /{exit} f' "$file" | grep -qE '^\|\s*Pattern\s*\|\s*Problem\s*\|\s*Fix\s*\|\s*$'; then
      error "$name: '## Anti-Patterns' section missing exact 3-column header (Pattern | Problem | Fix)"
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
#   `prompts/<name>.prompt.md`         (path-style prompt refs, if ever introduced)
# Paths containing * (glob) or < > (illustrative placeholders) are skipped.
# Name-style prompt mentions (a skill or agent naming a prompt, e.g. the
# `find-impact` prompt) are also checked to resolve to prompts/<name>.prompt.md.
xref_errors_start=$ERRORS
while IFS= read -r file; do
  rel_file="${file#$REPO_ROOT/}"
  refs=$(grep -oE '`(instructions/[^`*<>]+\.instructions\.md|skills/[^`*<>]+/SKILL\.md|agents/[^`*<>]+\.agent\.md|prompts/[^`*<>]+\.prompt\.md)`' "$file" 2>/dev/null | tr -d '`' | sort -u || true)
  [ -z "$refs" ] && continue
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    target="$GITHUB_DIR/$ref"
    if [ ! -f "$target" ]; then
      error "$rel_file: references '$ref' but file does not exist"
    fi
  done <<< "$refs"
done < <(find "$GITHUB_DIR" -name "*.md" -type f)

# Name-style prompt mentions: a skill or agent may name a prompt as a suggested
# shortcut (e.g. the `find-impact` prompt). The form used in this repo is a
# backtick-wrapped lowercase name immediately followed by the word "prompt".
# Verify each such mention resolves to a real prompts/<name>.prompt.md.
while IFS= read -r file; do
  rel_file="${file#$REPO_ROOT/}"
  mentions=$(grep -oE '`[a-z][a-z0-9-]*` +prompt' "$file" 2>/dev/null | sed -E 's/^`([a-z][a-z0-9-]*)` +prompt$/\1/' | sort -u || true)
  [ -z "$mentions" ] && continue
  while IFS= read -r pname; do
    [ -z "$pname" ] && continue
    if [ ! -f "$GITHUB_DIR/prompts/$pname.prompt.md" ]; then
      error "$rel_file: references prompt '$pname' but prompts/$pname.prompt.md does not exist"
    fi
  done <<< "$mentions"
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
