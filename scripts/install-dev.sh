#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app="${1:-build/DerivedData/Build/Products/Debug/OrangeLen.app}"
if [[ $# == 0 && "${ORANGELEN_SKIP_BUILD:-0}" != 1 ]]; then ./scripts/build.sh; fi
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
    while IFS= read -r -d "" info; do
      /usr/libexec/PlistBuddy -c "Add :OrangeLenAppGroup string $group" "$info"
    done < <(find "$destination/Contents" -name Info.plist -not -path "*/XPCServices/*" -not -path "*/Resources/*" -print0)
  fi
  while IFS= read -r -d '' library; do
    codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime "$library"
  done < <(find "$destination/Contents" -name '*.dylib' -print0)
  while IFS= read -r -d '' service; do
    service_entitlements=ImageBroker/ImageBroker.entitlements
    if [[ "$service" == *OrangeLenDocumentBroker.xpc ]]; then service_entitlements=DocumentBroker/DocumentBroker.entitlements; fi
    codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --entitlements "$service_entitlements" "$service"
  done < <(find "$destination/Contents" -name '*.xpc' -print0)
  while IFS= read -r -d "" preview; do
    codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --entitlements build/signing/preview.plist "$preview"
  done < <(find "$destination/Contents/PlugIns" -name "*.appex" -print0)
  codesign --force --sign "$ORANGELEN_SIGN_IDENTITY" --options runtime --entitlements build/signing/app.plist "$destination"
fi
codesign --verify --deep --strict "$destination"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$destination"
while IFS= read -r -d '' preview; do
  pluginkit -a "$preview"
  identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$preview/Contents/Info.plist")
  selection=$(pluginkit -m -i "$identifier" 2>/dev/null || true)
  if ! printf '%s\n' "$selection" | rg -q '^-' ; then
    pluginkit -e use -i "$identifier"
  fi
done < <(find "$destination/Contents/PlugIns" -name '*.appex' -print0)
qlmanage -r
pluginkit -m -v -i local.OrangeLen.Preview
