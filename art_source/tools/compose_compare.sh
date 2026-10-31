#!/usr/bin/env bash
# Build "gallery reference | Blender preview | Godot gameplay" comparison sheets (Review B evidence).
# Usage: art_source/tools/compose_compare.sh <civ> <asset> <godot_capture.png> [crop_geometry]
# Output: docs/audits/evidence/slice/compare_<civ>_<asset>.png
set -euo pipefail
cd "$(dirname "$0")/../.."
civ=$1; asset=$2; cap=$3; crop=${4:-460x520+40+160}
tmp=$(mktemp -d)
magick "sample_project/art/buildings/$civ/$asset.png" -filter point -resize x420 -background '#e8d8b0' -gravity center -extent 330x440 "$tmp/r.png"
magick "docs/art/previews/${civ}_${asset}.png" -background '#3a4a3a' -flatten -resize x440 -gravity center -extent 440x440 "$tmp/b.png"
magick "$cap" -crop "$crop" +repage -resize x440 "$tmp/g.png"
magick "$tmp/r.png" "$tmp/b.png" "$tmp/g.png" -background '#222' -splice 6x0 +append \
  -gravity north -background '#222' -splice 0x34 -font DejaVu-Sans -fill white -pointsize 14 \
  -annotate +0+7 "$civ/$asset: reference | Blender | Godot" \
  "docs/audits/evidence/slice/compare_${civ}_${asset}.png"
rm -rf "$tmp"
echo "docs/audits/evidence/slice/compare_${civ}_${asset}.png"
