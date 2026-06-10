#!/usr/bin/env bash
set -euo pipefail

# Pre-tool policy hook: blocks dangerous shell commands before execution.
#
# WARNING — LAST-RESORT SAFETY NET, NOT A SANDBOX.
# Blocklists are inherently bypassable (encoding, aliases, variable
# indirection, etc.).  Downstream repos should run agents inside
# restricted-permission environments.  This hook catches common
# accidental destruction; it cannot stop a determined adversary.
#
# Input:  JSON on stdin  (tool name + arguments from Copilot agent)
# Output: exit 0 = allow,  exit 2 = deny
# Policy: FAIL-CLOSED — any parse or match failure → deny.

INPUT=$(cat)

# ── Fail-closed guards ──────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  echo "DENY: jq not found (fail-closed)" >&2
  exit 2
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // ""') || {
  echo "DENY: failed to parse toolName (fail-closed)" >&2
  exit 2
}

TOOL_INPUT=$(echo "$INPUT" | jq -r '
  .toolInput // "" |
  if type == "object" then
    (.command // .cmd // .script // tostring) |
    if type == "array" then join(" ") else . end
  elif type == "array" then join(" ")
  else . end') || {
  echo "DENY: failed to parse toolInput (fail-closed)" >&2
  exit 2
}

# ── Only inspect shell-like tool calls ──────────────────────────────
case "$TOOL_NAME" in
  read_file|list_dir|list_directory|search|grep|codebase|read|find_files) exit 0 ;;
  *) ;;
esac

# ── Normalize input ─────────────────────────────────────────────────
# Collapse all consecutive whitespace to a single space so that
# split-flag tricks (rm -r -f), multi-space evasion, and tab
# insertion are neutralised before pattern matching.
NORM=$(echo "$TOOL_INPUT" | tr -s '[:space:]' ' ')

# ── Blocked patterns (case-insensitive POSIX ERE) ──────────────────
#
# After normalisation every whitespace sequence is a single space,
# so patterns can use literal ' ' safely.
#
# rm — recursive forced deletion
#   Combined glued flags in any order (-rf, -fr, -rfi, …), optionally preceded
#     by unrelated flags (rm -v -rf), targeting a dangerous path.
#   Split flags: a recursive token and a force token in either order, tolerating
#     intervening flags (rm -r -v -f) — blocked unconditionally (any target).
#   Long flags: --recursive, --force — blocked unconditionally.
#   Targets (combined form): /, ~, any $-variable, ., .., *, ./*
DENY_PATTERNS='rm( -[a-z]+)* (-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*)( --)?( -[a-z]+)* ["'"'"']?(/|~|\.|\.\.|\*|\./\*|\$)'
DENY_PATTERNS="$DENY_PATTERNS"'|rm( -[a-z]+)*( -[a-z]*r[a-z]*)( -[a-z]+)*( -[a-z]*f[a-z]*)'
DENY_PATTERNS="$DENY_PATTERNS"'|rm( -[a-z]+)*( -[a-z]*f[a-z]*)( -[a-z]+)*( -[a-z]*r[a-z]*)'
DENY_PATTERNS="$DENY_PATTERNS"'|rm --recursive|rm --force'
DENY_PATTERNS="$DENY_PATTERNS"'|--no-preserve-root'

# find — destructive actions
DENY_PATTERNS="$DENY_PATTERNS"'|find .*-delete'
DENY_PATTERNS="$DENY_PATTERNS"'|find .*-exec(dir)? rm'

# Privilege escalation
DENY_PATTERNS="$DENY_PATTERNS"'|(^| )(sudo|doas|pkexec)( |$)'

# SQL destruction (DDL + unqualified DML)
DENY_PATTERNS="$DENY_PATTERNS"'|DROP (DATABASE|SCHEMA|TABLE|INDEX|VIEW|FUNCTION|PROCEDURE)'
DENY_PATTERNS="$DENY_PATTERNS"'|TRUNCATE( |$)'
DENY_PATTERNS="$DENY_PATTERNS"'|DELETE FROM'

# Git destructive operations
#   --force / -f flag, or refspec + prefix (git push origin +main)
DENY_PATTERNS="$DENY_PATTERNS"'|git push .*(--force|-f( |$)|\+[a-zA-Z])'
DENY_PATTERNS="$DENY_PATTERNS"'|git reset --hard'
DENY_PATTERNS="$DENY_PATTERNS"'|git clean -[a-zA-Z]*f|git clean .*--force'

# Filesystem permissions and formatting
#   chmod 777 — with or without -R, handles -R777 (flag glued to value)
DENY_PATTERNS="$DENY_PATTERNS"'|chmod (-[a-zA-Z]+ |-[a-zA-Z]*)?0?777'
DENY_PATTERNS="$DENY_PATTERNS"'|mkfs( |\.)'
DENY_PATTERNS="$DENY_PATTERNS"'|shred '
DENY_PATTERNS="$DENY_PATTERNS"'|wipefs '

# Remote code execution / encoded pipes
DENY_PATTERNS="$DENY_PATTERNS"'|curl.*\|.*(sh|bash)'
DENY_PATTERNS="$DENY_PATTERNS"'|wget.*\|.*(sh|bash)'
DENY_PATTERNS="$DENY_PATTERNS"'|base64 (-d|--decode).*\|'

# Raw disk write / mass process kill
DENY_PATTERNS="$DENY_PATTERNS"'|dd (if=|of=/dev/)'
DENY_PATTERNS="$DENY_PATTERNS"'|kill -9 -1'

# Fork bomb
DENY_PATTERNS="$DENY_PATTERNS"'|:\(\) *\{'

if echo "$NORM" | grep -qiE "$DENY_PATTERNS"; then
  echo "DENY: blocked by pre-tool policy" >&2
  exit 2
fi

exit 0
