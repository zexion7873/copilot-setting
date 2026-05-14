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
#   - rm -rf /           root deletion
#   - sudo               privilege escalation
#   - DROP DATABASE       database destruction
#   - DROP SCHEMA         schema destruction
#   - TRUNCATE            data wipe without backup
#   - git push --force    force push to main/master
#   - chmod -R 777        world-writable permissions
#   - mkfs.               filesystem formatting
DENY_PATTERNS="rm -rf /[^a-zA-Z]|sudo |DROP DATABASE|DROP SCHEMA|TRUNCATE |git push.*--force.*(main|master)|chmod -R 777|mkfs\."

if echo "$TOOL_INPUT" | grep -qiE "$DENY_PATTERNS" 2>/dev/null; then
  echo "DENY: blocked by pre-tool policy" >&2
  exit 2
fi

exit 0
