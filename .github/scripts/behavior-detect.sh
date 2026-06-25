#!/usr/bin/env bash
# Rung 3 behavioral detector — Spring 3.2 mapping-annotation rule.
#
# The format validator (Rung 1) and the floor↔instruction canary (Rung 2) prove
# the rule TEXT is well-formed and consistent. Neither proves the rule changes
# what an agent writes. This detector is the deterministic INSTRUMENT for that
# third rung: given Java source, it reports whether the source uses the Spring
# 4.3+ shorthand annotations (@GetMapping / @PostMapping / ...) banned on Spring
# 3.2 — the canonical rule in `instructions/spring-hibernate.instructions.md`,
# which prescribes `@RequestMapping(method = RequestMethod.GET)` instead.
#
# It is a lexical check, not a parser. The instrument is unit-tested (RED / GREEN
# / trap) by `test-behavior-detect.sh` BEFORE it is trusted to grade any model
# output — the same "test the grader first" discipline that keeps a substring
# matcher from passing on garbage.
#
# Usage:   behavior-detect.sh [FILE]      (reads stdin when FILE is omitted)
# Output:  "OK"        + exit 0  when clean
#          "VIOLATION" + the offending lines + exit 1 when a banned annotation is used
set -euo pipefail

src="$(cat "${1:-/dev/stdin}")"

# Match the banned shorthand while keeping ORIGINAL line numbers. Two guards
# keep the check honest:
#   - it anchors on '@' and requires a non-identifier char (or EOL) right after
#     "Mapping", so an identifier like `myGetMappingHelper` and a longer token
#     like `@GetMappingFoo` do NOT match — only the real annotation does;
#   - it drops lines whose content begins with `//`, so a commented-out mention
#     is not graded as a use. (A trailing `// @GetMapping` on a code line is a
#     documented bound — see TRAP cases in test-behavior-detect.sh.)
# The trailing-context class `([^A-Za-z0-9_]|$)` is used instead of `\b` so the
# pattern behaves identically under BSD grep (macOS) and GNU grep (CI).
hits="$(printf '%s\n' "$src" \
  | grep -nE '@(Get|Post|Put|Delete|Patch)Mapping([^A-Za-z0-9_]|$)' \
  | grep -vE '^[0-9]+:[[:space:]]*//' || true)"

if [ -n "$hits" ]; then
  printf 'VIOLATION\n%s\n' "$hits"
  exit 1
fi

echo "OK"
