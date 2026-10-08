#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
evidence="$PWD/docs/evidence/boundary-review-2026-10-08"
target="$PWD/Packages/OrangeLen/Tests/OrangeLenUITests/BoundaryAuditTests.swift"
if [[ -e "$target" ]]; then
  echo 'Audit test target already exists; refusing to overwrite it.' >&2
  exit 1
fi
scratch=$(mktemp -d "${TMPDIR:-/tmp}/orangelen-review.XXXXXX")
trap 'rm -f "$target"; rm -rf "$scratch"' EXIT
python3 "$evidence/generate-fixtures.py" "$scratch"
cp "$evidence/BoundaryAuditTests.swift" "$target"
export ORANGELEN_AUDIT_FIXTURES="$scratch"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun swift test --package-path Packages/OrangeLen --filter BoundaryAuditTests
