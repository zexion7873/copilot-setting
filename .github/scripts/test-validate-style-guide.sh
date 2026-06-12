#!/usr/bin/env bash
# Regression tests for validate-style-guide.sh.
#
# Run from anywhere:
#   bash .github/scripts/test-validate-style-guide.sh
#
# The validator derives REPO_ROOT from its own location
# ("$(dirname "$0")/../.."), so each test builds a throwaway fixture — a copy
# of the real .github tree (which the validator passes) — mutates ONE file to
# introduce a single defect, and runs the COPIED validator against it. The
# fixture is the repo root, so no global state is touched.
#
# Two assertion directions:
#   expect_pass — a legitimate file the validator must NOT reject (guards
#                 against false-positives: CRLF, trailing space, digit names).
#   expect_fail — a defect the validator MUST catch (guards against silent
#                 false-negatives: 1024 bypass, unterminated frontmatter, …).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_GITHUB="$(cd "$SCRIPT_DIR/.." && pwd)"   # .../.github
PASS=0
FAIL=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# Build a fresh fixture = a copy of the real .github tree (guaranteed valid).
new_fixture() {
  local d
  d="$(mktemp -d "$TMPROOT/fx.XXXXXX")"
  mkdir -p "$d/.github"
  cp -R "$REAL_GITHUB/." "$d/.github/"
  printf '%s' "$d"
}

run_validator() { bash "$1/.github/scripts/validate-style-guide.sh" 2>&1; }

# expect_pass LABEL FIXTURE_ROOT
expect_pass() {
  local out rc=0
  out="$(run_validator "$2")" || rc=$?
  if [ "$rc" -eq 0 ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL [$1] expected PASS (exit 0), got exit $rc"
    echo "$out" | grep '❌' | sed 's/^/        /'
  fi
}

# expect_fail LABEL FIXTURE_ROOT [REQUIRED_SUBSTRING]
expect_fail() {
  local out rc=0
  out="$(run_validator "$2")" || rc=$?
  if [ "$rc" -eq 0 ]; then
    FAIL=$((FAIL + 1))
    echo "FAIL [$1] expected FAIL (exit 1) but validator passed — defect not caught"
  elif [ "$#" -ge 3 ] && ! grep -qF "$3" <<<"$out"; then
    FAIL=$((FAIL + 1))
    echo "FAIL [$1] failed as expected but message missing substring: '$3'"
  else
    PASS=$((PASS + 1))
  fi
}

# ── Baseline: an unmodified copy of the real tree must pass ──────────
expect_pass "baseline: unmodified .github passes" "$(new_fixture)"

# ── A. Multi-line scalar must not bypass the 1024-char skill cap ─────
# A double-quoted description split across two lines: first line < 1024 (so the
# first-line-only reader measures it as passing) but the full value exceeds it.
fxa="$(new_fixture)"
pad1="$(printf '%480s' '' | tr ' ' a)"
pad2="$(printf '%560s' '' | tr ' ' b)"
awk -v p1="$pad1" -v p2="$pad2" '
  /^description:/ && !done {
    print "description: \"Use when planning a feature. Triggers on: plan, 規劃, design, 設計, roadmap. Produces a structured plan. Do NOT use for implementation (prefer implement), for review (prefer code-review). " p1
    print "  " p2 "\""
    done = 1; next
  }
  { print }
' "$fxa/.github/skills/plan/SKILL.md" > "$fxa/.github/skills/plan/SKILL.md.tmp" \
  && mv "$fxa/.github/skills/plan/SKILL.md.tmp" "$fxa/.github/skills/plan/SKILL.md"
expect_fail "A: multi-line skill description (1024 bypass) is rejected" "$fxa" "single-line scalar"

# ── B. Trailing whitespace in a value must not break the name match ──
fxb="$(new_fixture)"
perl -i -pe 's/^name: plan$/name: plan /' "$fxb/.github/skills/plan/SKILL.md"
expect_pass "B: trailing whitespace in 'name' still matches the directory" "$fxb"

# ── C. Unterminated frontmatter (no closing ---) must be rejected ────
fxc="$(new_fixture)"
mkdir -p "$fxc/.github/skills/ghostskill"
printf '%s\n' \
  '---' \
  'name: ghostskill' \
  'description: Use when nothing. Triggers on: a, b, c, d. Produces nothing. Do NOT use for anything (prefer plan).' \
  '# ghostskill — Workflow' \
  '' \
  'Body with no closing frontmatter delimiter.' \
  > "$fxc/.github/skills/ghostskill/SKILL.md"
expect_fail "C: unterminated frontmatter is rejected" "$fxc"

# ── D. CRLF line endings must still parse as frontmatter ─────────────
fxd="$(new_fixture)"
perl -i -pe 's/\n/\r\n/' "$fxd/.github/instructions/no-heredoc.instructions.md"
expect_pass "D: CRLF line endings still parse frontmatter" "$fxd"

# ── E. Empty description must be rejected (instruction + prompt) ─────
fxe1="$(new_fixture)"
perl -i -pe "s/^description:.*/description: ''/" "$fxe1/.github/instructions/sql.instructions.md"
expect_fail "E1: empty instruction description is rejected" "$fxe1" "empty"

fxe2="$(new_fixture)"
perl -i -pe "s/^description:.*/description: ''/" "$fxe2/.github/prompts/find-impact.prompt.md"
expect_fail "E2: empty prompt description is rejected" "$fxe2" "empty"

# ── F. Handoff in dash-line form must still validate the target ──────
fxf="$(new_fixture)"
printf '%s\n' \
  '---' \
  'name: GhostRouter' \
  "description: 'Test router for handoff parsing.'" \
  'model: Test' \
  "tools: ['read']" \
  'handoffs:' \
  '  - agent: NoSuchAgent' \
  '    label: Go' \
  '    prompt: 請 do it' \
  '    send: false' \
  '---' \
  '# GhostRouter — Test Router' \
  '' \
  'Body.' \
  > "$fxf/.github/agents/ghostrouter.agent.md"
expect_fail "F: dash-line handoff to a nonexistent agent is caught" "$fxf" "NoSuchAgent"

# ── G. Indented continuation in Coding Standards must be caught ──────
# A plain indented line under a bullet renders as part of that bullet (drifting
# the hard boundary) yet starts with no dash, so it escapes both the format
# guard and the byte-identical bullet comparison.
fxg="$(new_fixture)"
awk '
  /^## Coding Standards/{incs = 1}
  incs && /^## / && !/Coding Standards/{incs = 0}
  { print }
  incs && /^- \*\*Java 8\*\*/ && !done { print "  sneaky drift continuation line"; done = 1 }
' "$fxg/.github/agents/reviewer.agent.md" > "$fxg/.github/agents/reviewer.agent.md.tmp" \
  && mv "$fxg/.github/agents/reviewer.agent.md.tmp" "$fxg/.github/agents/reviewer.agent.md"
expect_fail "G: indented continuation in Coding Standards is caught" "$fxg" "top-level"

# ── H. A digit-containing instruction filename must be accepted ──────
fxh="$(new_fixture)"
printf '%s\n' \
  '---' \
  "description: 'SQL v2 rules.'" \
  "applyTo: '**/*.sql'" \
  '---' \
  '# SQL v2' \
  '' \
  '- rule' \
  > "$fxh/.github/instructions/sql2.instructions.md"
perl -i -pe 's{instructions/[a-z0-9-]+\.instructions\.md}{instructions/sql2.instructions.md}g' \
  "$fxh/.github/skills/sql-review/SKILL.md"
expect_pass "H: code-touching skill may name a digit-containing instruction file" "$fxh"

# ── Summary ─────────────────────────────────────────────────────────
echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All validator regression tests passed."
