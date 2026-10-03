#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p build
xcrun swift test --package-path Packages/OrangeLen "$@" 2>&1 | tee build/tests.log
