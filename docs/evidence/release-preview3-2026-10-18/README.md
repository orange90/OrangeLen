# Preview.3 notarized release verification

Date: 2026-10-18. Public release:
[0.1.0-preview.3](https://github.com/orange90/OrangeLen/releases/tag/v0.1.0-preview.3).

The universal Release application was built from commit
`21ff51c448911f7e99b24cb42b7b7095d1cd27aa` (the release tag target), including source
suffix expansion, developer/AI readers and the extended archive formats. Application
version is 0.1.0, bundle build 3, deployment target macOS 14.0.

- Developer ID Application: Zhe Huang, team C7J9CK5X87; hardened runtime and timestamps.
- All nested applications/extensions/XPC services signed; strict/deep verification passed.
- Application and seven Quick Look extensions contain arm64 and x86_64.
- SourceCodeFormats registry, Arrow/DOT/highlighting resources, new archive type
  declarations and dependency licenses were verified in the release staging app.
- Resource packaging tests: five passed. Feature regression evidence remains
  [313 tests / four skips / zero failures](../archive-expansion-2026-10-17/README.md).

## Apple notarization

| Artifact | Submission | Status |
| --- | --- | --- |
| Application ZIP | 16b708d5-dfd4-4c7a-9e48-1eb4aea57c45 | Accepted |
| Final DMG | c6d937ef-d3d7-4408-9ace-c814959814b2 | Accepted |

Both app and DMG were stapled and validated. Gatekeeper reports
`accepted / source=Notarized Developer ID` for both. Existing keychain credentials
were reused without exporting private keys or recording credentials in the repository.

## Published download verification

The DMG and SHA-256 file were downloaded again from the public GitHub release.
SHA-256 verification passed. The downloaded DMG was mounted read-only, and its
contained app passed strict signature, notarization-ticket and Gatekeeper checks.
The downloaded DMG itself also passed ticket and Gatekeeper checks. Main app and
all seven extensions were verified universal, bundle build 3; registry and archive
license were present. The verification mount was ejected afterward.

- File: `OrangeLen-0.1.0-preview.3-universal.dmg`
- Size: 116108260 bytes
- SHA-256: `fb9168c45fb3e5554936c90b87ebb5f7b76b179fdc9955c676ac0ed97db47d91`
- [Installer](https://github.com/orange90/OrangeLen/releases/download/v0.1.0-preview.3/OrangeLen-0.1.0-preview.3-universal.dmg)
- [Checksums](https://github.com/orange90/OrangeLen/releases/download/v0.1.0-preview.3/OrangeLen-0.1.0-preview.3-SHA256SUMS.txt)
- [Machine-readable verification](summary.json)

Intel was cross-built and its architecture verified; Intel hardware and other
macOS versions were not fully tested. Existing format/subset and Finder-dispatch
limits remain. Previous releases remain available. No local application installation
was replaced as part of this publication.
