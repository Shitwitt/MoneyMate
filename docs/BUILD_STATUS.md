# Tink build verification — 2026-11-05

## GET YOUR APK NOW

**[Download Tink 1.1.0, build 2 — Android APK](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-41887240793/Tink-Android-release.apk)**

- [APK checksum](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-41887240793/Tink-Android-release.apk.sha256)
- [Embedded APK/signature metadata](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-41887240793/Tink-APK-metadata.txt)
- [Published source snapshot](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-41887240793/Tink-source.zip)
- [Current Tink source branch](https://github.com/Shitwitt/MoneyMate/tree/arena/9ea2a134-moneymate)

This is the redesigned **Tink** APK, not the historical PaisaClone 1.0 build.
The binary was built from application revision `ca5277b`, including the web-launch
URI guard and transaction/achievement-dialog fixes. The source ZIP also includes
subsequent CI/harness/documentation corrections. Application files in `lib/`,
`android/`, `ios/`, `assets/` and `pubspec*` are unchanged after `ca5277b`.
The source also includes later **web-only** CanvasKit font-fallback packaging fixes;
they do not change the native application or require relabelling an older APK.

## Verified Android artifact

| Property | Result |
|---|---|
| Public label | Tink |
| Version name / code | `1.1.0` / `2` |
| Build mode | Optimized Flutter release |
| File size | 82,598,086 bytes (82.6 MB / 78.77 MiB) |
| Android package | `com.example.paisaclone` (retained for data compatibility) |
| Minimum Android | Android 7 / API 24 |
| Compile SDK | 36 |
| Native app payloads | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| Internet permission | **Absent**, checked in the APK |
| APK signature | Verified with Android SDK `apksigner` |
| Certificate subject | `C=US, O=Android, CN=Android Debug` |
| APK SHA-256 | `5f0ca6fafde561bc801690b7e2719234dd689c03ea23656b887233a4e6b8c41a` |
| Certificate SHA-256 | `c11356ad369ee3cf90dee79b2354128dca12817849bd7b3c1e46477cf0d25c91` |

[Successful native build and binary verification steps; initial publication needed a separate retry](https://github.com/Shitwitt/MoneyMate/actions/runs/41887240793/job/126775731064).

[Successful publication and independent re-verification of the same signed APK](https://github.com/Shitwitt/MoneyMate/actions/runs/41893487516/job/126796714641). The release-asset SHA-256 digest matches the publisher’s checksum.

The package, label, version, API minimum, native payloads, signature and lack of
Internet permission were inspected in the built binary, not inferred only from
source. This is a **test/debug-key-signed release-mode APK**, not a production
store-signed release. “Release mode” describes optimization, not key provenance.

## Verification evidence

- [Formatting, analyzer, 56 tests and 8 DST regression reruns: passed](https://github.com/Shitwitt/MoneyMate/actions/runs/41893488078/job/126796717547).
- Tests include six introductory pages/swiping, bundled fonts/light/dark/contrast,
  reduced motion, narrow 160% text navigation, Arabic RTL, calculator-sheet save,
  ten Safe-to-Spend/preferences regressions, and existing finance/security/backup/
  import/editor/persistence regressions, ordinary web launch URL handling and saving
  beneath an achievement overlay. The eight DST cases are reruns of tests
  already included in the 56, not 64 unique tests.
- [Separate push-triggered direct Gradle debug build: passed](https://github.com/Shitwitt/MoneyMate/actions/runs/41888635901).
- **Four offline-web packaging tests passed**: local engine-font alias, unchanged
  bundled font bytes/cache inclusion, idempotent packaging, missing-font fail-closed
  behavior and a bundled local development fallback (covered by four test cases).
- [Self-hosted web build and full real-browser smoke: passed](https://github.com/Shitwitt/MoneyMate/actions/runs/41893488078/job/126797681353).
  Verified six intros, actual demo setup, Accounts, Reports, dark palette selection,
  persisted profile/theme reload, offline reload and **zero external runtime
  requests** in that scenario. Dark background pixels were checked before and
  after reload. Earlier incomplete browser runs are not counted as passes.
- CanvasKit's implicit default-Roboto CDN request was eliminated with a bundled
  Inter compatibility alias. Additional glyph fallbacks remain on the app origin.
  Unbundled scripts/emoji may show a missing glyph instead of fetching third-party
  fonts; the app's supported language scripts remain bundled.

## Installation and platform limits

No physical Android/iOS installation is claimed. Camera, biometrics, notification
delivery, launcher widgets and signed upgrade continuity need [device QA](QA.md).
iOS sources are included; Android success is not iOS compilation/signing proof.

**Export and verify a backup before uninstalling an older version.** An APK from
a different CI signing certificate cannot update an existing installation even
though the package ID is unchanged. Keep a verified backup, uninstall only if
necessary, install Tink, then restore. Configure a persistent private release key
for future signed upgrades; never commit the key or put it in chat.

Local storage and portable backups are not encrypted at rest. The app PIN is not
database encryption. Pro is a free local simulation; all transfers/assets/cards
are bookkeeping records, not banking, payments or investment trading.
