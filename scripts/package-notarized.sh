#!/bin/bash
# Prepare a Developer ID signed universal app. Public artifacts require notarization.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
: "${ORANGELEN_SIGN_IDENTITY:?Developer ID identity required}"
: "${ORANGELEN_TEAM_ID:?Team ID required}"
input="${ORANGELEN_INPUT_APP:-build/ReleasePreview/Build/Products/Release/OrangeLen.app}"
stage="$PWD/build/notarized-preview.2"
app="$stage/OrangeLen.app"
if [[ "${1:-prepare}" == prepare ]]; then
  test ! -e "$app" || { echo 'Signed staging app already exists; inspect before replacing.' >&2; exit 1; }
  python3 scripts/deduplicate-resources.py "$input" --verify-only
  mkdir -p "$stage"
  ditto "$input" "$app"
  ditto docs/licenses "$app/Contents/Resources/Licenses"
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
  while IFS= read -r -d '' framework; do codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --timestamp "$framework"; done < <(find "$app/Contents" -name '*.framework' -print0)
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
  codesign --verify --deep --strict "$app"
  echo "Prepared: $app"
elif [[ "${1:-}" == notarize || "${1:-}" == resume ]]; then
  : "${ORANGELEN_NOTARY_PROFILE:?Configured notarytool profile required}"
  codesign --verify --deep --strict "$app"
  test "$(codesign -dv "$app" 2>&1 | sed -n 's/^TeamIdentifier=//p')" = "$ORANGELEN_TEAM_ID"
  if [[ "${1:-}" == resume ]]; then
    : "${ORANGELEN_NOTARY_SUBMISSION:?Existing Apple submission ID required}"
    xcrun notarytool wait "$ORANGELEN_NOTARY_SUBMISSION" --keychain-profile "$ORANGELEN_NOTARY_PROFILE" --output-format json > "$stage/app-notary.json"
  else
    ditto -c -k --keepParent "$app" "$stage/submission.zip"
    xcrun notarytool submit "$stage/submission.zip" --keychain-profile "$ORANGELEN_NOTARY_PROFILE" --wait --output-format json > "$stage/app-notary.json"
  fi
  python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["status"] == "Accepted"' "$stage/app-notary.json"
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  spctl --assess --type execute --verbose=2 "$app"
  mkdir -p "$stage/image"
  ditto "$app" "$stage/image/OrangeLen.app"
  ln -s /Applications "$stage/image/Applications"
  cat > "$stage/image/INSTALL.txt" <<'EOF'
OrangeLen 0.1.0 preview.2 · macOS 14+
Drag OrangeLen.app to Applications, then open it.
Developer ID signed and Apple notarized.
Enable OrangeLen Quick Look extensions in System Settings if needed.
Universal binary: Apple Silicon and Intel. Intel hardware not fully verified.

将 OrangeLen.app 拖入 Applications 后打开。
已使用 Developer ID 签名并通过 Apple 公证。
如 Finder 预览未生效，请检查系统设置中的 Quick Look 扩展。
包含 Apple Silicon 与 Intel 架构；Intel 实机尚未完整验收。
EOF
  dmg="$stage/OrangeLen-0.1.0-preview.2-universal.dmg"
  hdiutil create -volname 'OrangeLen' -srcfolder "$stage/image" -format UDZO "$dmg"
  codesign --sign "$ORANGELEN_SIGN_IDENTITY" --timestamp "$dmg"
  xcrun notarytool submit "$dmg" --keychain-profile "$ORANGELEN_NOTARY_PROFILE" --wait --output-format json > "$stage/dmg-notary.json"
  python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["status"] == "Accepted"' "$stage/dmg-notary.json"
  xcrun stapler staple "$dmg"
  xcrun stapler validate "$dmg"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg"
  hdiutil verify "$dmg"
  mkdir -p build/artifacts
  ditto "$dmg" "build/artifacts/$(basename "$dmg")"
  (cd build/artifacts && shasum -a 256 "$(basename "$dmg")" > OrangeLen-0.1.0-preview.2-SHA256SUMS.txt)
else
  echo 'Usage: scripts/package-notarized.sh prepare|notarize|resume' >&2; exit 2
fi
