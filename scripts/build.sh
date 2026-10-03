#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p build
xcodebuild -project OrangeLen.xcodeproj -scheme OrangeLen -configuration Debug -derivedDataPath build/DerivedData "$@" build 2>&1 | tee build/build.log
