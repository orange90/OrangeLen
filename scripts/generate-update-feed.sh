#!/bin/bash
# Run after notarization/stapling. Produces a Release asset, never publishes it.
set -euo pipefail
cd "$(dirname "$0")/.."
version="${1:?Usage: scripts/generate-update-feed.sh VERSION [release-notes.md]}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Stable version required.' >&2; exit 2; }
notes="${2:-docs/releases/V$version.md}"
tools="${ORANGELEN_SPARKLE_BIN:-build/SourcePackages/artifacts/sparkle/Sparkle/bin}"
if [[ -z "${ORANGELEN_SPARKLE_BIN:-}" && ! -x "$tools/generate_appcast" ]]; then
  tools=build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin
fi
app="build/notarized-$version/OrangeLen.app"
dmg="build/artifacts/OrangeLen-$version-universal.dmg"
test -x "$tools/generate_appcast"
test -f "$notes"
test -f "$dmg"
codesign --verify --deep --strict "$app"
xcrun stapler validate "$dmg"
public_key=$("$tools/generate_keys" --account local.OrangeLen -p)
test "$public_key" = "$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$app/Contents/Info.plist")" || { echo 'Sparkle signing key does not match the packaged app.' >&2; exit 1; }
test "$version" = "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
stage=$(mktemp -d "$PWD/build/update-feed.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto "$dmg" "$stage/$(basename "$dmg")"
cp "$notes" "$stage/OrangeLen-$version-universal.md"
"$tools/generate_appcast" --account local.OrangeLen --maximum-deltas 0 \
  --download-url-prefix "https://github.com/orange90/OrangeLen/releases/download/V$version/" \
  --embed-release-notes --link https://github.com/orange90/OrangeLen \
  "$stage"
python3 scripts/verify-update-feed.py "$stage/appcast.xml" --app "$app" --archive "$dmg"
"$tools/sign_update" --account local.OrangeLen --verify "$stage/appcast.xml"
signature=$(python3 -c 'import sys,xml.etree.ElementTree as E; print(E.parse(sys.argv[1]).find("channel/item/enclosure").get("{http://www.andymatuschak.org/xml-namespaces/sparkle}edSignature"))' "$stage/appcast.xml")
"$tools/sign_update" --account local.OrangeLen --verify "$dmg" "$signature"
cp "$stage/appcast.xml" build/artifacts/appcast.xml
echo 'Upload appcast.xml alongside the DMG in the same stable GitHub Release.'
