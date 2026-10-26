#!/bin/bash
# Sign Sparkle from the inside out; never apply OrangeLen broker entitlements.
set -euo pipefail
app="${1:?App path required}"
identity="${2:?Signing identity required}"
framework="$app/Contents/Frameworks/Sparkle.framework"
test -d "$framework" || exit 0
options=(--force --sign "$identity" --options runtime)
if [[ "${3:-}" == --timestamp ]]; then options+=(--timestamp); fi
codesign "${options[@]}" "$framework/Versions/B/XPCServices/Installer.xpc"
codesign "${options[@]}" --preserve-metadata=entitlements "$framework/Versions/B/XPCServices/Downloader.xpc"
codesign "${options[@]}" "$framework/Versions/B/Autoupdate"
codesign "${options[@]}" "$framework/Versions/B/Updater.app"
codesign "${options[@]}" "$framework"
codesign --verify --deep --strict "$framework"
