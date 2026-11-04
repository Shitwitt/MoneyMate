# Build verification — 2026-11-04

Application revision: `8d5da45`, with its resolved dependency lock committed by CI as `e32a2eb`. Later documentation/CI-harness cleanup does not change the application Dart/native code.

| Check | Result / evidence |
|---|---|
| Flutter 3.47.9 dependency resolution and l10n generation | Passed |
| `flutter analyze --no-fatal-infos` | Passed |
| Full test suite | **38 tests passed** |
| Regression suite under `TZ=America/New_York` | **8 tests passed**, including DST-safe calendar boundaries |
| Direct Gradle debug APK | [Passed](https://github.com/Shitwitt/MoneyMate/actions/runs/41853657333) |
| Optimized release APK | [Android release job passed](https://github.com/Shitwitt/MoneyMate/actions/runs/41853657467/job/126657486956) |
| Self-hosted web release compilation | Passed in the same combined workflow |
| Browser onboarding/offline smoke test | Initial attempt failed in the **test harness** before opening the browser (CommonJS/ESM Chromium export mismatch). Harness fixed; check the subsequent run for its result. No successful end-to-end browser run is claimed here. |
| iOS/Xcode compile | Not verified: GitHub could not acquire a hosted macOS runner due to capacity. No successful iOS compilation or device installation is claimed. |

## Direct installable download

- [PaisaClone-Android-release.apk — 80,435,381 bytes](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-41853657467/PaisaClone-Android-release.apk)
- [SHA-256 checksum](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-41853657467/PaisaClone-Android-release.apk.sha256)
- [Release page](https://github.com/Shitwitt/MoneyMate/releases/tag/apk-release-41853657467)
- [Debug test APK — larger, 178,874,794 bytes](https://github.com/Shitwitt/MoneyMate/releases/download/apk-41853657333/PaisaClone-Android.apk)

The optimized APK is installable and **debug-key-signed**, not an unsigned APK or a Play Store production release. It uses `com.example.paisaclone`, version `1.0.0+1`, minimum Android API 24. It deliberately has no app Internet permission. Builds from different CI runners can have different certificates: **export and verify a backup before uninstalling an earlier build to resolve a signature conflict**.

No physical Android/iOS device was available in this coding workspace. Camera, biometrics, notification delivery, launcher widgets, signed upgrades and complex-script printing still require the [real-device QA checklist](QA.md). Hive and portable backups are not encrypted at rest; read the privacy section before entering important data.
