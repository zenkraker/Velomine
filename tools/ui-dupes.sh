#!/usr/bin/env bash
# The duplicated UI patterns the shared-widget rule keeps down, and their budget in `tools/ui-dupes.baseline`.
#
# `--write` prints the current counts, to be saved as the baseline; without it the counts are compared with
# the baseline and a count that rose fails. Run from anywhere: the paths are relative to this file, and the
# recipe in `justfile` and the CI job both call this script, so the patterns are written once.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
baseline="$root/tools/ui-dupes.baseline"
cd "$root/app/lib"

# The name as it is written in the baseline, and the pattern its count is made of.
patterns() {
  printf '%s\t%s\n' \
    "private widgets" 'class _.*extends \(Stateless\|Stateful\)Widget' \
    "Card(" '\(^\|[^A-Za-z_]\)Card(' \
    "TextField(" '\(^\|[^A-Za-z_]\)TextField(\|TextFormField(' \
    "showSnackBar" 'showSnackBar' \
    "SegmentedButton" 'SegmentedButton' \
    "TextStyle(" 'TextStyle(' \
    "Color(0x" 'Color(0x' \
    "EdgeInsets.all(n)" 'EdgeInsets.all([0-9]' \
    "SizedBox(height: n)" 'SizedBox(height: [0-9]' \
    "SizedBox(width: n)" 'SizedBox(width: [0-9]' \
    "spacing: n" 'spacing: [0-9]'
}

count() { printf '%-22s %s\n' "$1" "$(grep -rn "$2" features core --include=*.dart | wc -l || true)"; }

if [ "${1:-}" = "--write" ]; then
  while IFS=$'\t' read -r name pattern; do count "$name" "$pattern"; done < <(patterns)
  exit 0
fi

[ -f "$baseline" ] || { echo "missing $baseline: run 'tools/ui-dupes.sh --write > tools/ui-dupes.baseline'"; exit 1; }
fail=0
lower=0
check() {
  local name="$1" now was
  now=$(grep -rn "$2" features core --include=*.dart | wc -l || true)
  # The name may hold spaces and brackets, so compare it as text, not as a pattern.
  was=$(awk -v n="$name" '{ line=$0; value=$NF; sub(/[ \t]+[0-9]+$/, "", line); sub(/[ \t]+$/, "", line); if (line == n) print value }' "$baseline")
  [ -n "$was" ] || { echo "  $name: not in the baseline"; fail=1; return; }
  if [ "$now" -gt "$was" ]; then
    echo "  $name: $was -> $now  (raised)"; fail=1
  elif [ "$now" -lt "$was" ]; then
    echo "  $name: $was -> $now  (lower: take the new number into the baseline)"; lower=1
  fi
}
while IFS=$'\t' read -r name pattern; do check "$name" "$pattern"; done < <(patterns)

if [ "$fail" = 1 ]; then
  echo "ui-dupes: a duplicate pattern grew. Use the shared widget instead."
  exit 1
fi
if [ "$lower" = 1 ]; then echo "ui-dupes: no pattern grew, and one fell."; fi
