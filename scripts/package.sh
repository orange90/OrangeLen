#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-dev}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p build/artifacts
case "$mode" in
  dev)
    ./scripts/build.sh
    input=build/DerivedData/Build/Products/Debug/OrangeLen.app
    ;;
  release)
    : "${ORANGELEN_SIGN_IDENTITY:?Set a Developer ID Application identity from your keychain}"
    : "${ORANGELEN_TEAM_ID:?Set the matching developer team ID}"
    # No automatic certificate creation, account login or provisioning changes.
    xcodebuild -project OrangeLen.xcodeproj -scheme OrangeLen -configuration Release -derivedDataPath build/Release CODE_SIGN_IDENTITY=- build 2>&1 | tee build/release-build.log
    input=build/Release/Build/Products/Release/OrangeLen.app
    ;;
  *) echo 'Usage: scripts/package.sh dev|release' >&2; exit 2;;
esac
stage=$(mktemp -d "$PWD/build/package.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto "$input" "$stage/OrangeLen.app"
app="$stage/OrangeLen.app"
mkdir -p "$app/Contents/Resources/Licenses"
ditto docs/licenses "$app/Contents/Resources/Licenses"
if [[ "$mode" == release ]]; then
  group="$ORANGELEN_TEAM_ID.local.OrangeLen.shared"
  cp App/OrangeLen.entitlements "$stage/app.plist"
  cp PreviewExtension/OrangeLenPreview.entitlements "$stage/preview.plist"
  for ent in "$stage/app.plist" "$stage/preview.plist"; do
    /usr/libexec/PlistBuddy -c 'Add :com.apple.security.application-groups array' "$ent"
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups:0 string $group" "$ent"
  done
  for info in "$app/Contents/Info.plist" "$app/Contents/PlugIns/OrangeLenPreview.appex/Contents/Info.plist"; do
    /usr/libexec/PlistBuddy -c "Add :OrangeLenAppGroup string $group" "$info"
  done
  while IFS= read -r -d '' library; do codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp "$library"; done < <(find "$app/Contents" -name '*.dylib' -print0)
  while IFS= read -r -d '' service; do codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp --entitlements ImageBroker/ImageBroker.entitlements "$service"; done < <(find "$app/Contents" -name '*.xpc' -print0)
  codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp --entitlements "$stage/preview.plist" "$app/Contents/PlugIns/OrangeLenPreview.appex"
  codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp --entitlements "$stage/app.plist" "$app"
else
  codesign --force --sign - --entitlements App/OrangeLen.entitlements "$app"
fi
codesign --verify --deep --strict "$app"
zip="$PWD/build/artifacts/OrangeLen-$mode.zip"
ditto -c -k --keepParent "$app" "$zip"
if [[ "$mode" == release && -n "${ORANGELEN_NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$zip" --keychain-profile "$ORANGELEN_NOTARY_PROFILE" --wait
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  spctl --assess --type execute --verbose "$app"
  ditto -c -k --keepParent "$app" "$zip"
else
  echo 'Notarization: NOT EXECUTED (requires release mode and a configured keychain profile).'
fi
shasum -a 256 "$zip" > "$zip.sha256"
echo "$zip"
