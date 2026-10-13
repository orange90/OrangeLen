#!/bin/bash
# Public preview packaging. Ad-hoc signed; never claims Apple notarization.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p build/artifacts
if [[ "${1:-}" != --skip-build ]]; then
  xcodebuild -project OrangeLen.xcodeproj -scheme OrangeLen -configuration Release \
    -derivedDataPath build/ReleasePreview ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY=- build > build/release-preview-build.log 2>&1
fi
input=build/ReleasePreview/Build/Products/Release/OrangeLen.app
python3 scripts/deduplicate-resources.py "$input" --verify-only
stage=$(mktemp -d "$PWD/build/preview-package.XXXXXX")
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/image"
ditto "$input" "$stage/image/OrangeLen.app"
app="$stage/image/OrangeLen.app"
ditto docs/licenses "$app/Contents/Resources/Licenses"
icon=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$app/Contents/Info.plist")
test "$icon" = OrangeLen.icns
test -s "$app/Contents/Resources/$icon"
while IFS= read -r -d '' executable; do
  lipo "$executable" -verify_arch arm64 x86_64
done < <(find "$app/Contents" -type f -perm -111 -path '*/MacOS/*' -print0)
codesign --force --sign - --preserve-metadata=identifier,entitlements,flags "$app"
codesign --verify --deep --strict "$app"
ln -s /Applications "$stage/image/Applications"
cat > "$stage/image/INSTALL.txt" <<'EOF'
OrangeLen 0.1.0 preview / 预览版
macOS 14+ · Apple Silicon and Intel

Drag OrangeLen.app to Applications, then open it.
This preview is ad-hoc signed and is NOT Apple-notarized.
If macOS blocks opening, attempt to open once, then use
System Settings > Privacy & Security > Open Anyway, if offered.
Enable OrangeLen's Quick Look extensions in System Settings if needed.
Intel hardware and other macOS versions are not fully verified.

将 OrangeLen.app 拖入 Applications 后打开。
本预览版使用 ad-hoc 签名，尚未通过 Apple 公证。
如系统阻止打开，先尝试打开一次，再到“系统设置 > 隐私与安全性”
中选择“仍要打开”（若系统提供此选项）。
如 Finder 预览未生效，请检查系统设置中的 Quick Look 扩展。
Intel 实机与其他 macOS 版本尚未完整验收。
EOF
artifact=build/artifacts/OrangeLen-0.1.0-preview.1-universal.dmg
hdiutil create -volname 'OrangeLen Preview' -srcfolder "$stage/image" -format UDZO "$stage/OrangeLen.dmg"
hdiutil verify "$stage/OrangeLen.dmg"
mv "$stage/OrangeLen.dmg" "$artifact"
(cd build/artifacts && shasum -a 256 "$(basename "$artifact")" > OrangeLen-0.1.0-preview.1-SHA256SUMS.txt)
echo "$artifact"
