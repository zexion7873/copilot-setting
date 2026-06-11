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
# Input:  JSON on stdin.  camelCase surfaces (Copilot CLI, cloud agent)
#         send { toolName, toolArgs } where toolArgs may be an object or a
#         JSON-encoded string; the VS Code PascalCase payload sends
#         { tool_name, tool_input }.  Both shapes are handled.
# Output: exit 0 = allow.  exit 2 = deny, with
#         {"permissionDecision":"deny","permissionDecisionReason":"..."}
#         on stdout (the documented merge channel) and a human-readable
#         line on stderr for logs.
# Policy: FAIL-CLOSED — empty input, JSON parse errors, missing jq,
#         missing toolArgs/tool_input payload, or a grep error during
#         pattern matching → deny.

# Deny reasons must not contain double quotes or backslashes — they are
# embedded verbatim into the stdout JSON (jq may not be available here).
deny() {
  printf '{"permissionDecision":"deny","permissionDecisionReason":"%s"}\n' "$1"
  echo "DENY: $1" >&2
  exit 2
}

INPUT=$(cat)

# Empty / whitespace-only stdin → deny (honor the documented fail-closed contract).
if [ -z "${INPUT//[[:space:]]/}" ]; then
  deny "empty input (fail-closed)"
fi

if ! command -v jq >/dev/null 2>&1; then
  deny "jq not found (fail-closed)"
fi

TOOL_NAME=$(jq -r '.toolName // .tool_name // ""' <<<"$INPUT") \
  || deny "failed to parse tool name (fail-closed)"

# ── Only inspect shell-like tool calls ──────────────────────────────
case "$TOOL_NAME" in
  read_file|list_dir|list_directory|search|grep|codebase|read|find_files) exit 0 ;;
  *) ;;
esac

# The args payload must exist under one of the documented keys; its absence
# means the hook schema changed under us → deny rather than inspect nothing.
HAS_ARGS=$(jq 'has("toolArgs") or has("tool_input")' <<<"$INPUT") \
  || deny "failed to parse input JSON (fail-closed)"
if [ "$HAS_ARGS" != "true" ]; then
  deny "missing toolArgs/tool_input payload (fail-closed)"
fi

# Extract the command text: unwrap a JSON-encoded string, pull the
# command-ish key out of an object, join argv arrays.  An object with no
# command-ish key is a non-shell tool call — nothing to inspect.
TOOL_INPUT=$(jq -r '
  (.toolArgs // .tool_input // "")
  | if type == "string" then (fromjson? // .) else . end
  | if type == "object" then (.command // .cmd // .script // "") else . end
  | if type == "array" then join(" ") else tostring end' <<<"$INPUT") \
  || deny "failed to parse toolArgs (fail-closed)"

if [ -z "${TOOL_INPUT//[[:space:]]/}" ]; then
  exit 0
fi

# ── Normalize input ─────────────────────────────────────────────────
# Collapse all consecutive whitespace to a single space so that
# split-flag tricks (rm -r -f), multi-space evasion, and tab
# insertion are neutralised before pattern matching.
NORM=$(tr -s '[:space:]' ' ' <<<"$TOOL_INPUT")

# check <category> <pattern> — deny on match, AND deny on grep error
# (rc >= 2): a broken pattern must fail closed, not fall through to allow.
# Patterns are case-insensitive POSIX ERE matched against the normalised
# command, so a literal ' ' is a safe token separator.
check() {
  local rc=0
  grep -qiE "$2" <<<"$NORM" || rc=$?
  if [ "$rc" -eq 0 ]; then
    deny "blocked by pre-tool policy: $1"
  elif [ "$rc" -ge 2 ]; then
    deny "pattern match error during $1 check (fail-closed)"
  fi
}

# ── Blocked patterns (case-insensitive POSIX ERE) ──────────────────
#
# Building blocks: matching never crosses a command separator (| ; &),
# so one command's flags cannot satisfy another command's pattern.
Q='["'"'"']?'                       # optional opening/closing quote
RM_TGT='(/|~/?|\.\.?/?|\./\*|\*)'   # exact dangerous targets: / ~ ~/ . .. ./ ../ ./* *
RM_COMBO='-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*'

# rm — recursive forced deletion
#   Combined glued flags (-rf, -fr, -rfi, …) with a dangerous target in
#     either order (rm -rf /, rm "$DIR" -rf).  Targets are exact tokens
#     (optionally quoted) or any $-prefixed variable — subpaths like
#     /tmp/x, .cache, ./build are NOT matched.
#   Split flags: a recursive token and a force token in either order in
#     the same simple command, tolerating intervening flags AND operands
#     (rm -r build -f) — blocked unconditionally (any target).
#   Long flags: --recursive / --force anywhere in the rm command,
#     including mixed short+long (rm -r --force) — blocked unconditionally.
RM_RULES='(^|[^a-z])rm( [^|;&]*)? ('"$RM_COMBO"')( [^|;&]*)? '"$Q"'(\$|'"$RM_TGT$Q"'( |$))'
RM_RULES="$RM_RULES"'|(^|[^a-z])rm( [^|;&]*)? '"$Q"'(\$[^ ]*|'"$RM_TGT$Q"') [^|;&]*('"$RM_COMBO"')( |$)'
RM_RULES="$RM_RULES"'|(^|[^a-z])rm( [^|;&]*)? -[a-z]*r[a-z]*( [^|;&]*)? -[a-z]*f[a-z]*( |$)'
RM_RULES="$RM_RULES"'|(^|[^a-z])rm( [^|;&]*)? -[a-z]*f[a-z]*( [^|;&]*)? -[a-z]*r[a-z]*( |$)'
RM_RULES="$RM_RULES"'|(^|[^a-z])rm( [^|;&]*)? --(recursive|force)( |$)'
RM_RULES="$RM_RULES"'|--no-preserve-root'
check "rm forced recursive deletion" "$RM_RULES"

# find — destructive actions
check "find destructive action" 'find .*-delete|find .*-exec(dir)? rm'

# Privilege escalation — token-anchored so glued separators (&&sudo, ;doas,
# |pkexec) are still caught while visudo/sudoku are not.
check "privilege escalation" '(^|[^a-z])(sudo|doas|pkexec)( |$)'

# SQL destruction (DDL + unqualified DML).  TRUNCATE requires the TABLE
# keyword so the coreutils truncate(1) binary is not a false positive.
SQL_RULES='DROP (DATABASE|SCHEMA|TABLE|INDEX|VIEW|FUNCTION|PROCEDURE)'
SQL_RULES="$SQL_RULES"'|(^|[^a-z])TRUNCATE TABLE( |$)'
SQL_RULES="$SQL_RULES"'|DELETE FROM'
check "destructive SQL" "$SQL_RULES"

# Git destructive operations.  --force requires a token boundary so
# --force-with-lease stays allowed; patterns stop at command separators
# so a following command's -f flag cannot bleed in.
GIT_RULES='git push[^|;&]* (--force( |$)|-f( |$)|\+[a-zA-Z])'
GIT_RULES="$GIT_RULES"'|git reset --hard'
GIT_RULES="$GIT_RULES"'|git clean[^|;&]* -[a-zA-Z]*f[a-zA-Z]*( |$)|git clean[^|;&]* --force( |$)'
check "destructive git operation" "$GIT_RULES"

# Filesystem permissions and formatting
#   chmod 777 — tolerates preceding flags (-v -R, --recursive) and the
#   glued -R777 form; mode must be the exact token 0?777 (1777 is fine).
FS_RULES='(^|[^a-z])chmod( --?[a-zA-Z][a-zA-Z-]*)* (-[a-zA-Z]*)?0?777( |$)'
FS_RULES="$FS_RULES"'|mkfs( |\.)'
FS_RULES="$FS_RULES"'|shred '
FS_RULES="$FS_RULES"'|wipefs '
check "filesystem permission or format destruction" "$FS_RULES"

# Remote code execution / encoded pipes.  The shell must be the piped
# command word (sh/bash/zsh/dash/ash/ksh) — piping a download into
# sha256sum, jq, or grep is allowed; pipe chains still match.
RCE_RULES='(curl|wget)[^;&]*\|&? ?(ba|da|z|a|k)?sh( |$|;)'
RCE_RULES="$RCE_RULES"'|base64 (-d|--decode).*\|'
check "remote code execution pipe" "$RCE_RULES"

# Raw disk write / mass process kill.  dd operands are order-free, so
# if=/of=/dev/ is matched anywhere in the dd command.
DISK_RULES='(^|[^a-z])dd [^|;&]*(if=|of=/dev/)'
DISK_RULES="$DISK_RULES"'|kill -9 -1'
check "raw disk write or mass process kill" "$DISK_RULES"

# Fork bomb
check "fork bomb" ':\(\) *\{'

exit 0
