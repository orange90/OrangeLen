#!/bin/bash
set -uo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p build
python3 -m unittest discover -s scripts/tests || exit 1
python3 scripts/create-source-parity-fixtures.py || exit 1
xcrun swift build --package-path Packages/OrangeLen --build-tests 2>&1 | tee build/tests.log
status=("${PIPESTATUS[@]}")
[ "${status[0]}" -eq 0 ] && [ "${status[1]}" -eq 0 ] || exit 1
xcrun swift test --package-path Packages/OrangeLen --skip-build list > build/test-list.txt 2>build/test-list-errors.log || exit 1
sed -nE 's#^([A-Za-z0-9_]+\.[A-Za-z0-9_]+)/.*#\1#p' build/test-list.txt | sort -u > build/test-suites.txt
[ -s build/test-suites.txt ] || { echo 'No test suites discovered' | tee -a build/tests.log; exit 1; }
printf 'suite\texit\tseconds\n' > build/test-suite-summary.tsv
failed=0
while IFS= read -r suite; do
  echo "=== SUITE $suite start $(date -u '+%FT%TZ')" | tee -a build/tests.log
  start=$SECONDS
  pattern=$(printf '%s' "$suite" | sed 's/\./[.]/g')
  xcrun swift test --package-path Packages/OrangeLen --skip-build --filter "^${pattern}/" 2>&1 | tee -a build/tests.log
  status=("${PIPESTATUS[@]}")
  rc=${status[0]}
  [ "${status[1]}" -eq 0 ] || rc=1
  printf '%s\t%s\t%s\n' "$suite" "$rc" "$((SECONDS-start))" >> build/test-suite-summary.tsv
  [ "$rc" -eq 0 ] || failed=1
done < build/test-suites.txt
cat build/test-suite-summary.tsv | tee -a build/tests.log
exit "$failed"
