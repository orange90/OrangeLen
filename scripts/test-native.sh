#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p build
xcodebuild -project OrangeLen.xcodeproj -scheme OrangeLenNativeTests -configuration Debug -derivedDataPath build/DerivedData -destination 'platform=macOS' -test-timeouts-enabled YES -default-test-execution-time-allowance 90 -maximum-test-execution-time-allowance 90 "$@" test 2>&1 | tee build/native-tests.log
