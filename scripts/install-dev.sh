#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app="${1:-build/DerivedData/Build/Products/Debug/OrangeLen.app}"
destination="$HOME/Applications/OrangeLen.app"
mkdir -p "$HOME/Applications"
ditto "$app" "$destination"
# Optional local development identity, never export keys or request a password.
if [[ -n "${ORANGELEN_SIGN_IDENTITY:-}" ]]; then
  mkdir -p build/signing
  cp PreviewExtension/OrangeLenPreview.entitlements build/signing/preview.plist
  cp App/OrangeLen.entitlements build/signing/app.plist
  if [[ -n "${ORANGELEN_TEAM_ID:-}" ]]; then
    group="$ORANGELEN_TEAM_ID.local.OrangeLen.shared"
    for ent in build/signing/app.plist build/signing/preview.plist; do
      /usr/libexec/PlistBuddy -c 'Add :com.apple.security.application-groups array' "$ent"
      /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups:0 string $group" "$ent"
    done
    for info in "$destination/Contents/Info.plist" "$destination/Contents/PlugIns/OrangeLenPreview.appex/Contents/Info.plist"; do
      /usr/libexec/PlistBuddy -c "Add :OrangeLenAppGroup string $group" "$info"
    done
  fi
  while IFS= read -r -d '' library; do
    codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime "$library"
  done < <(find "$destination/Contents" -name '*.dylib' -print0)
  while IFS= read -r -d '' service; do
    codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --entitlements ImageBroker/ImageBroker.entitlements "$service"
  done < <(find "$destination/Contents" -name '*.xpc' -print0)
  codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --entitlements build/signing/preview.plist "$destination/Contents/PlugIns/OrangeLenPreview.appex"
  codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --entitlements build/signing/app.plist "$destination"
fi
codesign --verify --deep --strict "$destination"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$destination"
pluginkit -a "$destination/Contents/PlugIns/OrangeLenPreview.appex"
pluginkit -e use -i local.OrangeLen.Preview
qlmanage -r
pluginkit -m -v -i local.OrangeLen.Preview
