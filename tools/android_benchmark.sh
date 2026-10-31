#!/usr/bin/env bash
# Builds the "Android Benchmark" preset, installs it on the connected device/emulator,
# runs the fixed benchmark scenario (scripts/tools/Benchmark.gd) and prints its PE_BENCH lines.
#
# Usage: tools/android_benchmark.sh [out_dir]
# Env:   GODOT_BIN (default: godot), ADB (default: $ANDROID_HOME/platform-tools/adb or adb on PATH),
#        ANDROID_SERIAL (pick a device when several are attached)
# Needs: Godot Android export templates, a Java SDK path and Android SDK path in Godot's editor
#        settings, and a debug keystore (see docs/audits/MOBILE_PERFORMANCE.md).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/build/benchmark}"
GODOT_BIN="${GODOT_BIN:-godot}"
if [ -z "${ADB:-}" ]; then
  if [ -n "${ANDROID_HOME:-}" ] && [ -x "$ANDROID_HOME/platform-tools/adb" ]; then ADB="$ANDROID_HOME/platform-tools/adb"; else ADB=adb; fi
fi
PKG=org.pocketempires.benchmark
mkdir -p "$OUT"
APK="$OUT/pe_benchmark.apk"

"$GODOT_BIN" --headless --path "$ROOT/sample_project" --export-debug "Android Benchmark" "$APK"
"$ADB" install -r "$APK"
"$ADB" logcat -c
"$ADB" shell am force-stop "$PKG" || true
"$ADB" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
LOG="$OUT/logcat_$(date +%Y%m%d_%H%M%S).txt"
# wait for the run to finish (or 10 minutes)
timeout 600 "$ADB" logcat -s godot:* | tee "$LOG" | grep --line-buffered -E "PE_BENCH|SCRIPT ERROR" | while read -r line; do
  echo "$line"
  case "$line" in *PE_BENCH_DONE*) pkill -P $$ -f "logcat -s godot" || true; break;; esac
done || true
"$ADB" exec-out run-as "$PKG" cat files/benchmark.json > "$OUT/benchmark.json" 2>/dev/null || true
echo "log: $LOG"
