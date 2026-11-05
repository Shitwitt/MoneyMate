# Tink 1.2 build verification — 2026-11-05

## GET YOUR APK NOW

**[Download Tink 1.2.0, build 3 — Android APK](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42087198603/Tink-Android-release.apk)**

- [APK checksum](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42087198603/Tink-Android-release.apk.sha256)
- [Embedded APK / public certificate metadata](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42087198603/Tink-APK-metadata.txt)
- [Release and source download](https://github.com/Shitwitt/MoneyMate/releases/tag/apk-release-42087198603)
- [Current source branch](https://github.com/Shitwitt/MoneyMate/tree/arena/9ea2a134-moneymate)
- [Historical 1.1 evidence](HISTORICAL_1_1_BUILD.md) — not the new binary

This is a **freshly rebuilt 1.2 APK**, not a renamed 1.1 file. It includes the
editorial-serif UI, horizontal glowing glass navigation, original account finishes,
live account preview, pulse radar/gauge, activity calendar, cumulative cashflow and
petal/segmented allocations. All values come from local records; the pulse is a
transparent planning estimate, not a credit score or bank assessment.

The Android binary was built from full revision
`f8cc6c86a745bc3ff7df727dd45c5351d754c6c8`. Subsequent source-archive updates are
release documentation only: application, platform, assets, dependencies and tests
remain identical to that tested native revision. The ZIP's Git archive comment
records its own revision. Source code identity is separate from a ZIP file hash.

## Verified Android artifact

| Property | Result |
|---|---|
| Public label | Tink |
| Version name / code | `1.2.0` / `3` |
| Build mode | Optimized Flutter release |
| File size | 82,319,404 bytes (82.3 MB) |
| Android package | `com.example.paisaclone`, retained for compatibility |
| Minimum Android | Android 7 / API 24 |
| Compile SDK | 36 |
| Native payloads | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| Internet permission | **Absent**, inspected in the built APK |
| APK signature | Verified by Android SDK `apksigner` |
| Certificate subject | `C=US, O=Android, CN=Android Debug` |
| APK SHA-256 | `18ff486dd8e7955218afff05e96be57521bbec712953d3ece76c192c7ddc449e` |
| Certificate SHA-256 | `5e09e1b8601682fcba52d8297f60df88d481222e03ccf5201ef1f83872abd9b4` |

[Successful fresh native build, APK inspection and publication](https://github.com/Shitwitt/MoneyMate/actions/runs/42087198603/job/127456181725).
The publisher's computed APK checksum matches the release asset's independent
SHA-256 digest. The 654-byte public signature report recovered from check
annotations also matches its release asset's SHA-256 digest. The sandbox cannot
follow GitHub's separate release-asset storage host, so a local APK re-download is
not claimed; the public direct download is the actual uploaded CI artifact.

The release tag was reserved with the authorized maintainer connection before
upload. All build, verification, artifact and publication steps subsequently
passed in the same native job; this is not a link to an unbuilt reservation.

## Verification evidence

- [Strict read-only formatter gate, analyzer, 65 Flutter unit/widget tests, 9 DST/calendar reruns and 4 Python offline-packaging tests: passed](https://github.com/Shitwitt/MoneyMate/actions/runs/42087198603/job/127455390021).
- The temporary SDK formatter synchronization helper has been removed. The final
  workflow does not normalize source before passing the formatting check.
- New coverage includes legacy account-style JSON compatibility, seven account
  types × six finishes at 160% text, future-date/unknown pulse handling,
  configurable RTL navigation, reduced-motion gauge/radar/calendar, spring-DST
  coverage and untruncated compact-card/radial totals. Existing finance,
  persistence, import/export, security, editor disposal and save-under-achievement
  regressions remain. The nine DST cases are reruns, not nine additional unique
  tests beyond 65.
- [Separate push-triggered direct Gradle debug build and artifact: passed](https://github.com/Shitwitt/MoneyMate/actions/runs/42087198593/job/127455389781).
- [Self-hosted web build and real-browser smoke: passed](https://github.com/Shitwitt/MoneyMate/actions/runs/42087198603/job/127456181871).
  Checked six introductions, actual demo setup, Accounts, Reports, lower cashflow
  and category charts, dark theme, persisted profile/theme reload, offline reload
  and **zero external runtime requests** in this scenario. Light/dark home,
  account, radar/gauge, cashflow and category screenshots were reviewed during
  development. CI diagnostic JPEGs are compressed; native/vector UI is not.
- Licensed local Instrument Serif / Source Serif 4 fonts were parsed independently:
  valid Latin/numeric glyphs, Source Serif 4 weights 400/500/600/700 and rupee glyph
  coverage. The local CanvasKit fallback and all eight Noto script families remain.

## Installation and platform limits

**This test certificate differs from the previous delivered 1.1 APK.** Android
will not update an install signed with that older certificate. **Export and verify
a backup first.** Uninstall only when ready, install the new APK, then restore.
The finance schema/IDs are compatible; an uninstall still removes app-private
files. Configure a persistent private release keystore for future in-place
upgrades and store submission. Never commit a key or put it in chat.

This is **test/debug-key-signed release-mode code**, not a production store-signed
release. Optimization and signing identity are different properties.

No physical Android/iOS installation is claimed. Camera, biometrics, notification
delivery, launcher widgets and signed upgrade continuity need [device QA](QA.md).
iOS sources are included; the queued unsigned iOS workflow is not a successful
iOS build/signing result. Android success does not establish iOS compilation.

Local storage and portable backups are not encrypted at rest. The PIN is not
database encryption. Pro is a free local simulation; transfers/assets/cards are
bookkeeping records, not banking, payments, custody or card issuance.
