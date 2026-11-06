#!/bin/bash
# Runs device_benchmark.gd under emulated phone CPUs: one core of this machine, capped to a share of it
# (Linux cgroups via systemd-run --user). The share approximates a phone's single-thread speed against this
# desktop core (Geekbench-style single-core ratios): mid-range ~40 %, budget ~15 %, very low end ~7 %.
# The GPU is not limited (the desktop iGPU renders); its load is reported as draw calls and primitives.
#   scripts/tools/device_tiers.sh <out_dir> [seconds]
OUT=${1:?out dir}; SEC=${2:-6}
mkdir -p "$OUT"
cd "$(dirname "$0")/../.."
run() {  # tier quota
  if [ "$2" = "none" ]; then
    timeout 1800 godot --path . --resolution 720x1280 --script res://scripts/tools/device_benchmark.gd -- \
      --out="$OUT/$1.csv" --tier="$1" --seconds="$SEC" 2>&1 | grep -E "\[device\]|SCRIPT ERROR"
  else
    systemd-run --user --scope -q -p AllowedCPUs=3 -p CPUQuota="$2" -p CPUQuotaPeriodSec=10ms \
      timeout 1800 godot --path . --resolution 720x1280 --script res://scripts/tools/device_benchmark.gd -- \
      --out="$OUT/$1.csv" --tier="$1" --seconds="$SEC" 2>&1 | grep -E "\[device\]|SCRIPT ERROR"
  fi
}
run desktop none
run mid 40%
run budget 15%
run low 7%
