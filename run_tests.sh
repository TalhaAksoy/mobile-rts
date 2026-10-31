#!/usr/bin/env bash
# Runs every headless test under sample_project/scripts/tests and prints a summary line per test.
# Usage: ./scripts_run_all_tests.sh [log_dir]   (GODOT_BIN env var overrides the binary)
set -u
cd "$(dirname "$0")/sample_project"
GODOT_BIN="${GODOT_BIN:-godot}"
LOG_DIR="${1:-/tmp/pocket_empires_test_logs}"
mkdir -p "$LOG_DIR"
"$GODOT_BIN" --headless --path . --import > "$LOG_DIR/_import.log" 2>&1
fail=0
for t in scripts/tests/test_*.gd; do
  name=$(basename "$t" .gd)
  timeout 1500 "$GODOT_BIN" --headless --path . --script "res://$t" > "$LOG_DIR/$name.log" 2>&1
  code=$?
  errs=$(grep -c "SCRIPT ERROR" "$LOG_DIR/$name.log")
  [ $code -ne 0 ] || [ "$errs" -ne 0 ] && fail=1
  printf "%-36s exit=%-3s script_errors=%s\n" "$name" "$code" "$errs"
done
exit $fail
