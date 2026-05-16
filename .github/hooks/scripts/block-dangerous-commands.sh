#!/usr/bin/env bash
set -euo pipefail

# Pre-tool policy hook: blocks dangerous shell commands before execution.
# Input:  JSON on stdin (tool name + arguments from Copilot agent)
# Output: exit 0 = allow, exit 2 = deny

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.toolInput // "" | if type == "object" then tostring else . end')

# Only inspect shell-like tool calls
case "$TOOL_NAME" in
  shell_command|terminal|bash|run_command) ;;
  *) exit 0 ;;
esac

# Blocked patterns (case-insensitive)
#   - rm -rf /              root deletion
#   - rm -rf . / rm -rf *   current-dir or glob wipe
#   - --no-preserve-root    explicit root deletion flag
#   - sudo                  privilege escalation
#   - DROP DATABASE/SCHEMA  database/schema destruction
#   - TRUNCATE              data wipe without backup
#   - git push --force      force push (any branch)
#   - git reset --hard      destructive history rewrite
#   - git clean -fd         delete untracked files
#   - chmod -R 777          world-writable permissions
#   - mkfs.                 filesystem formatting
#   - curl/wget | sh        piped remote execution
#   - dd if=                raw disk write
#   - kill -9 -1            kill all user processes
DENY_PATTERNS='rm -rf /([^a-zA-Z0-9]|$)|rm -rf \.( |$)|rm -rf \*|--no-preserve-root|sudo |DROP DATABASE|DROP SCHEMA|TRUNCATE |git push.*--force|git reset --hard|git clean -fd|chmod -R 777|mkfs\.|curl.*\|.*sh|wget.*\|.*sh|dd if=|kill -9 -1'

if echo "$TOOL_INPUT" | grep -qiE "$DENY_PATTERNS" 2>/dev/null; then
  echo "DENY: blocked by pre-tool policy" >&2
  exit 2
fi

exit 0
