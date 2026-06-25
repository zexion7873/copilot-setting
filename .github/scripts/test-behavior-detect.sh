#!/usr/bin/env bash
# Self-test for behavior-detect.sh — the "test the grader first" gate.
#
# Before the detector is trusted to grade model output, it must prove it can:
#   RED   — catch a real violation (an actual @GetMapping annotation),
#   GREEN — pass the prescribed Spring 3.2 form (@RequestMapping),
#   TRAP  — NOT be fooled by substring noise (an identifier containing the token)
#           or by a commented-out mention.
# The trap cases are the whole point: a detector that fires on any occurrence of
# the substring "GetMapping" would pass RED/GREEN yet rubber-stamp garbage.
#
# Run:  bash .github/scripts/test-behavior-detect.sh   (exit 0 = all pass)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DET="$SCRIPT_DIR/behavior-detect.sh"
PASS=0
FAIL=0

# assert LABEL EXPECTED_EXIT CODE
# Feed CODE to the detector via a here-string, NOT a pipe: `printf | assert`
# would run assert in a pipe subshell and the PASS/FAIL increments would
# evaporate, leaving a test that can never fail (PASS: 0 FAIL: 0 -> green).
assert() {
  local out rc=0
  out="$(bash "$DET" <<<"$3")" || rc=$?
  if [ "$rc" -eq "$2" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL [$1] expected exit $2, got $rc"
    printf '%s\n' "$out" | sed 's/^/        /'
  fi
}

# RED — a real banned annotation must trip (exit 1).
assert "RED: @GetMapping is a violation" 1 \
  $'@GetMapping("/users")\npublic List<User> users() { return svc.all(); }'

# RED — sibling shorthand annotations are banned too.
assert "RED: @PostMapping is a violation" 1 \
  $'@PostMapping("/users")\npublic void create(@RequestBody User u) {}'

# GREEN — the prescribed Spring 3.2 form must pass (exit 0).
assert "GREEN: @RequestMapping is the prescribed form" 0 \
  $'@RequestMapping(value = "/users", method = RequestMethod.GET)\npublic List<User> users() { return svc.all(); }'

# TRAP — the substring inside an identifier must NOT trip.
assert "TRAP: substring inside an identifier" 0 \
  'private Handler myGetMappingHelper() { return h; }'

# TRAP — a longer token like @GetMappingFoo must NOT trip.
assert "TRAP: longer token is not the banned annotation" 0 \
  $'@GetMappingFoo("/x")\npublic void x() {}'

# TRAP — a commented-out mention must NOT trip.
assert "TRAP: commented-out mention" 0 \
  $'// legacy note: do not use @GetMapping here\n@RequestMapping("/x")\npublic void x() {}'

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ] && [ "$PASS" -gt 0 ]; then
  echo "All behavior-detector self-tests passed."
else
  exit 1
fi
