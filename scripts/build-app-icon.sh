#!/bin/bash
# Rebuild the native macOS icon from the checked-in Imagegen master.
set -euo pipefail
cd "$(dirname "$0")/.."
source_image="docs/branding/OrangeLen-icon.png"
output="App/Resources/OrangeLen.icns"
stage=$(mktemp -d "${TMPDIR:-/tmp}/orangelen-icon.XXXXXX")
trap 'rm -rf "$stage"' EXIT
iconset="$stage/OrangeLen.iconset"
mkdir -p "$iconset" "$(dirname "$output")"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$source_image" --out "$iconset/icon_${size}x${size}.png" >/dev/null
  retina=$((size * 2))
  sips -z "$retina" "$retina" "$source_image" --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$output"
echo "$output"
