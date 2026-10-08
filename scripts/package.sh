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
    : "${ORANGELEN_NOTARY_PROFILE:?Release requires an existing notarytool keychain profile}"
    if ! security find-identity -v -p codesigning | rg 'Developer ID Application:' | grep -F -- "$ORANGELEN_SIGN_IDENTITY" >/dev/null; then
      echo 'Release requires an available Developer ID Application identity; Apple Development is not a release identity.' >&2
      exit 1
    fi
    # No automatic certificate creation, account login or provisioning changes.
    xcodebuild -project OrangeLen.xcodeproj -scheme OrangeLen -configuration Release -derivedDataPath build/Release ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY=- build 2>&1 | tee build/release-build.log
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
  while IFS= read -r -d "" info; do
    /usr/libexec/PlistBuddy -c "Add :OrangeLenAppGroup string $group" "$info"
  done < <(find "$app/Contents" -name Info.plist -not -path "*/XPCServices/*" -not -path "*/Resources/*" -print0)
  while IFS= read -r -d '' library; do codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp "$library"; done < <(find "$app/Contents" -name '*.dylib' -print0)
  while IFS= read -r -d '' service; do service_entitlements=ImageBroker/ImageBroker.entitlements; if [[ "$service" == *OrangeLenDocumentBroker.xpc ]]; then service_entitlements=DocumentBroker/DocumentBroker.entitlements; fi; codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp --entitlements "$service_entitlements" "$service"; done < <(find "$app/Contents" -name '*.xpc' -print0)
  while IFS= read -r -d "" preview; do
    codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp --entitlements "$stage/preview.plist" "$preview"
  done < <(find "$app/Contents/PlugIns" -name "*.appex" -print0)
  codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp --entitlements "$stage/app.plist" "$app"
  signed_team=$(codesign -dv "$app" 2>&1 | sed -n 's/^TeamIdentifier=//p')
  if [[ "$signed_team" != "$ORANGELEN_TEAM_ID" ]]; then
    echo 'Signed certificate team does not match ORANGELEN_TEAM_ID.' >&2; exit 1
  fi
  while IFS= read -r -d '' executable; do lipo "$executable" -verify_arch arm64 x86_64; done < <(find "$app/Contents" -type f -perm -111 -path '*/MacOS/*' -print0)
else
  codesign --force --sign - --entitlements App/OrangeLen.entitlements "$app"
fi
codesign --verify --deep --strict "$app"
zip="$PWD/build/artifacts/OrangeLen-$mode.zip"
# An unsuccessful notarization must never leave a new apparent release artifact.
candidate="$stage/OrangeLen-$mode.zip"
ditto -c -k --keepParent "$app" "$candidate"
if [[ "$mode" == release && -n "${ORANGELEN_NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$candidate" --keychain-profile "$ORANGELEN_NOTARY_PROFILE" --wait
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  spctl --assess --type execute --verbose "$app"
  ditto -c -k --keepParent "$app" "$candidate"
else
  echo 'Notarization: NOT EXECUTED (requires release mode and a configured keychain profile).'
fi
shasum -a 256 "$candidate" | sed "s|$candidate|$zip|" > "$stage/checksum"
mv "$candidate" "$zip"
mv "$stage/checksum" "$zip.sha256"
echo "$zip"
