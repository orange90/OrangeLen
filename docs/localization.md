# Interface localization

OrangeLen supports English (`en`) and Simplified Chinese (`zh-Hans`). The app, seven Quick Look extensions, and both XPC services declare these languages. `L10n` selects the first supported localization in `Locale.preferredLanguages`, using Foundation's language matching (including regional variants) and English fallback. The selection is cached per process: quit/reopen the app and close/reopen Finder previews after a language change. Already displayed views are not translated live. No language preference is written to macOS or application settings.

## Resources and coverage

- `Packages/OrangeLen/Sources/OrangeLenCore/Resources/{en,zh-Hans}.lproj/Localizable.strings`: 574 shared translations for menus, settings, preview controls, status/error messages, accessibility labels, generated document annotations, and helper-service errors.
- `PreviewExtension/Localization/<category>/{en,zh-Hans}.lproj/InfoPlist.strings`: localized names for the seven Finder extensions. `project.yml` is the source of the Xcode target/resource configuration.
- AppKit and SwiftUI call the same `L10n.text` API. The SwiftPM resource bundle is embedded in each executable that uses it; resources are not looked up in the Finder host's main bundle.
- SwiftPM and Xcode differ in localization-directory capitalization. Bundle selection uses the actual packaged directory name.
- The Chinese source phrase is the lookup key. Interpolation stores arguments separately and inserts them once into numbered `{0}` placeholders; paths, percent signs, braces, emoji, and user text are never interpreted as format directives. Translators can reorder placeholders. Keep the same placeholder set in both languages.
- Document content, file names, paths, code, SQL identifiers, format identifiers, stored settings, and folder-category raw values retain their original values. Folder categories expose a separate `localizedName`.

The Markdown metadata header now calculates source-map offsets from its localized UTF-16 length. Sentence tokenization detects the document's language rather than inheriting the interface language. Translated popup titles and hidden image/page bars are constrained so longer English text does not force the reader wider at narrow sizes.

## Validation (2026-10-08)

- English and Simplified Chinese test processes each ran 133 SwiftPM tests: 131 passed, 2 document-XPC tests skipped because they require the dedicated native test host.
- Localization tests check preferred-language order, regional matching, English fallback, every packaged translation, placeholder parity, and preservation of interpolated user content. After the final “Contents”/sidebar wording adjustment, all 4 localization tests and the 360 pt reader regression passed again (5 total).
- Existing document-copy, Markdown, Notebook, archive, database, folder and UI regressions use localized expected interface text while preserving source-content assertions. Narrow reader validation includes 360 pt; long-heading/source mapping checks cover 760–1,200 pt.
- Debug app build and Apple Development installation succeed; `codesign --verify --deep --strict` passes. Both resources are present in the installed app, all seven extensions, and every embedded XPC service. The dedicated native test host ran all 5 tests successfully, including document XPC.
- Actual English settings, Finder folder overview and its README reader were inspected through accessibility trees and screenshots. Chinese text and code in the README remain unchanged.
- Chinese was tested in a separate process using `-AppleLanguages '(zh-Hans)'`, without modifying global system preferences. This is not a claim that a live macOS language change or all Finder extension UIs have been manually exercised.

Logs for this session: `/tmp/orangelen-i18n-tests-en.log`, `/tmp/orangelen-i18n-tests-zh.log`, `/tmp/orangelen-i18n-build.log`, `/tmp/orangelen-i18n-install.log`. Dedicated native-test results are recorded in `/tmp/orangelen-i18n-native.log`.

To run the language-specific XCTest suite after building it (on the tested Apple Silicon machine):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
ORANGELEN_TEST_LANGUAGE=zh-Hans \
xcrun xctest -AppleLanguages '(zh-Hans)' -XCTest All \
  Packages/OrangeLen/.build/arm64-apple-macosx/debug/OrangeLenPackageTests.xctest
```

Use `en` / `'(en)'` for the English run. `ORANGELEN_TEST_LANGUAGE` is a test assertion, not an application language override.
