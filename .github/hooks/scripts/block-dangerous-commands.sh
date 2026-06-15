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
# Output: allow = exit 0 with no stdout JSON.  Deny = exit 0 with
#         {"permissionDecision":"deny","permissionDecisionReason":"..."}
#         on stdout — Copilot parses stdout as hook output only on exit 0,
#         and exit 2 is reserved as a NON-BLOCKING warning (the run
#         continues), so a deny must exit 0.  Unexpected crashes exit
#         non-zero (not 2), which preToolUse treats as a fail-closed deny.
#         The stderr line is only for human log readability.
# Policy: FAIL-CLOSED — empty input, JSON parse errors, missing jq,
#         missing toolArgs/tool_input payload, or a grep error during
#         pattern matching → deny.

# Deny reasons must not contain double quotes or backslashes — they are
# embedded verbatim into the stdout JSON (jq may not be available here).
# Must exit 0: the decision JSON is only parsed on exit 0; exit 2 would
# downgrade the deny to a non-blocking warning and the command would run.
deny() {
  printf '{"permissionDecision":"deny","permissionDecisionReason":"%s"}\n' "$1"
  echo "DENY: $1" >&2
  exit 0
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
# insertion are neutralised before pattern matching.  Also squeeze runs
# of '/' to a single slash: the OS treats // as /, so doubled-slash forms
# (rm -rf //, //etc, /home//user) point at the same target but would
# otherwise shift it off the single-slash anchor the patterns match on.
NORM=$(tr -s '[:space:]' ' ' <<<"$TOOL_INPUT" | tr -s '/')

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
RM_TGT='(/(\.\.?)?/?|/\*/?|~/?|~/\*|\.\.?/?|\./\*|\*)'   # root/home-equivalent: / /. /./ /.. /../ /* /*/ ~ ~/ ~/* . .. ./ ../ ./* *
# System directories where recursive-force deletion is never a legitimate
# agent action — matched at any depth (/etc, /usr/lib, /var/lib/mysql).
RM_SYSDIR='/(etc|usr|s?bin|lib(32|64|x32)?|var|boot|dev|proc|sys|opt|srv|run|root|private|System|Library|Applications)(/[^ |;&]*)?'
# Home roots — block the bare root or a whole top-level home directory, with
# or without a trailing slash (/home, /home/user/, /Users, /Users/name/) but
# allow deeper project paths (/Users/name/repo/target) so routine cleanups
# still work.  The trailing /? matches the canonical "$HOME/" shape, which a
# slash-forbidding segment class would otherwise let escape the end anchor.
RM_HOME='(/home|/Users)(/[^/ |;&]+)?/?'
# Absolute path with a '..' segment.  tr -s '/' collapses // but never
# resolves '..', so an absolute path can climb a scratch/whitelisted root back
# onto a system dir the per-target anchors miss (/tmp/.. IS /, /tmp/../etc IS
# /etc, /Users/x/../../etc IS /etc).  Requires a leading '/', so a routine
# RELATIVE cleanup (../build, ../../dist) is exempt; '..' must be a whole path
# segment, so a filename like my..file is not matched.
RM_DOTDOT='/([^ |;&]*/)?\.\.(/[^ |;&]*)?'
RM_COMBO='-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*'
# A dangerous token is "ended" by whitespace, end-of-string, OR a command
# separator glued directly to it — a bare ( |$) anchor misses the glued
# case (rm -rf /;true, git push -f&&echo) and would false-allow.
END='( |$|[|;&])'

# Scratch-dir carve-out — MUST precede the rm block below.
#   RM_SYSDIR blocks recursive deletes under /var, /private, /run at ANY
#   depth: right for /var/lib/mysql, wrong for the platform scratch dirs
#   that also live there — macOS $TMPDIR (/var/folders/…, and its /private
#   firmlink route), /var/tmp, /private/tmp, and the Linux XDG runtime dir
#   (/run/user/<uid>/…).  Routine agent cleanups hit these every run.
#   Carve them back out, but ONLY when the whole command is a single simple
#   rm of the shape "rm <flags> [--] <one scratch path> <flags>", anchored end
#   to end.  A command separator or a second operand (rm -rf /var/tmp/x /etc)
#   breaks the anchor, so the command falls through to the block below and
#   the real target is still caught.  Requires a subpath (…/<x>): deleting a
#   scratch root itself (rm -rf /var/tmp) is not a routine cleanup, so it
#   stays blocked.  Only SHORT flags (-rf) qualify, plus an optional bare "--"
#   end-of-options marker (rm -rf -- /var/tmp/x); the long forms (--recursive
#   / --force / --no-preserve-root) are unconditionally blocked below
#   regardless of target, and the carve-out must not undo that.
SCRATCH='/(private/)?(var/(tmp|folders)|tmp)/[^ |;&]+|/run/user/[0-9]+/[^ |;&]+'
# Path-traversal guard: tr -s '/' collapses // but never resolves '..', so a
# scratch-prefixed traversal (/tmp/../etc, or /tmp/.. which IS /) would
# otherwise hit this early exit 0 before RM_SYSDIR runs, re-allowing exactly
# the system-dir deletes the rm block exists to stop.  If any '..' segment is
# present, skip the carve-out and let the rm block below decide — failing
# toward blocking, never carving a path that can climb out of the scratch root.
# (A single-dot name like /var/folders/…/T/.cache has no '..' and still carves.)
if ! grep -qE '(^|/)\.\.(/|$| |[|;&])' <<<"$NORM" \
   && grep -qiE '^ *rm( +-[a-z]+)*( +--)? +'"$Q"'('"$SCRATCH"')'"$Q"'( +-[a-z]+)* *$' <<<"$NORM"; then
  exit 0
fi

# rm — recursive forced deletion
#   Combined glued flags (-rf, -fr, -rfi, …) with a dangerous target in
#     either order (rm -rf /, rm "$DIR" -rf).  Dangerous targets are exact
#     tokens (optionally quoted), any $-prefixed variable, an OS system
#     directory (RM_SYSDIR), a bare home root (RM_HOME), or an absolute path
#     with a '..' segment (RM_DOTDOT) — subpaths like /tmp/x, .cache, ./build,
#     /Users/me/repo/build and relative ../build are NOT matched.
#   Split flags: a recursive token and a force token in either order in
#     the same simple command, tolerating intervening flags AND operands
#     (rm -r build -f) — blocked unconditionally (any target).
#   Long flags: --recursive / --force anywhere in the rm command,
#     including mixed short+long (rm -r --force) — blocked unconditionally.
RM_RULES='(^|[^a-z])rm( [^|;&]*)? ('"$RM_COMBO"')( [^|;&]*)? '"$Q"'(\$|('"$RM_TGT"'|'"$RM_SYSDIR"'|'"$RM_HOME"'|'"$RM_DOTDOT"')'"$Q$END"')'
RM_RULES="$RM_RULES"'|(^|[^a-z])rm( [^|;&]*)? '"$Q"'(\$[^ ]*|('"$RM_TGT"'|'"$RM_SYSDIR"'|'"$RM_HOME"'|'"$RM_DOTDOT"')'"$Q"') [^|;&]*('"$RM_COMBO"')'"$END"
RM_RULES="$RM_RULES"'|(^|[^a-z])rm( [^|;&]*)? -[a-z]*r[a-z]*( [^|;&]*)? -[a-z]*f[a-z]*'"$END"
RM_RULES="$RM_RULES"'|(^|[^a-z])rm( [^|;&]*)? -[a-z]*f[a-z]*( [^|;&]*)? -[a-z]*r[a-z]*'"$END"
RM_RULES="$RM_RULES"'|(^|[^a-z])rm( [^|;&]*)? --(recursive|force)'"$END"
RM_RULES="$RM_RULES"'|--no-preserve-root'
check "rm forced recursive deletion" "$RM_RULES"

# find — destructive actions.  Bounded to a single simple command ([^|;&]*
# never crosses a separator) and to real flag boundaries: -delete must be a
# standalone token (a leading space), so a "-delete" substring inside a
# filename (find . -name on-delete-cascade.sql) is not a false positive.
FIND_RULES='(^|[^a-z])find[^|;&]* -delete'"$END"
FIND_RULES="$FIND_RULES"'|(^|[^a-z])find[^|;&]* -exec(dir)? rm'
check "find destructive action" "$FIND_RULES"

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
GIT_RULES='git push[^|;&]* (--force'"$END"'|-f'"$END"'|\+[a-zA-Z])'
GIT_RULES="$GIT_RULES"'|git reset --hard'
GIT_RULES="$GIT_RULES"'|git clean[^|;&]* -[a-zA-Z]*f[a-zA-Z]*'"$END"'|git clean[^|;&]* --force'"$END"
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
