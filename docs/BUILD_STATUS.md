# Tink 1.3 reference batch 1 — delivered build evidence

**Version 1.3.0+4**, branch `arena/9ea2a134-moneymate`, verified 6 November 2026.
[The 1.2 build is historical](HISTORICAL_1_2_BUILD.md), not this delivery.

## Downloads and identity

- **[Updated Android APK](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42151561328/Tink-Android-release.apk)**
- **[Current runnable source ZIP](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42151561328/Tink-source.zip)** · [source SHA-256](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42151561328/Tink-source.zip.sha256)
- [APK SHA-256 file](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42151561328/Tink-Android-release.apk.sha256) · [package/certificate metadata](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42151561328/Tink-APK-metadata.txt)

| Property | Verified value |
| --- | --- |
| Release tag | `apk-release-42151561328` |
| Native application revision | `578afb263a459a1195d14712b81d72e8c725b5c4` |
| Subsequent full browser/SDK verification | `9b5e84265265846e18299c20f02bf90fcedb23df` — only CI harness changes |
| App/version | Tink 1.3.0, build 4 |
| Package ID | `com.example.paisaclone` — legacy ID preserved; displayed brand is Tink |
| APK bytes | `96,865,291` |
| APK SHA-256 | `d89a2c055b9bc19ed72a86c339471028162033e09905e983c8fbc5a25eff6ed2` |
| Signing certificate SHA-256 | `a47ef423996924606e3bfc7211d30ac7fe0a166b9e73cd4929af7c982ccb2c49` |
| Signing certificate SHA-1 | `7d33b3b5d1ab51bca383d5a5efd370622166ffa5` |
| Android | Minimum API 24 (Android 7), compile SDK 36 |
| Native payload | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| Internet permission | Absent, checked in the built APK |
| Signing | Release-mode/AOT APK, **Android Debug test certificate**, not store signing |

The source ZIP may include later README/docs/CI updates. Its ZIP comment identifies
the exact source commit. The source-only publisher enforces no differences from
the APK revision in `lib`, `android`, `ios`, `web`, `assets`, `test`, `scripts`,
`pubspec.yaml`, `pubspec.lock` or `l10n.yaml`. It cannot replace/re-sign the APK.

## Checks actually passed

- [Native build, package/branding/version/ABI/permission/signature inspection and publication](https://github.com/Shitwitt/MoneyMate/actions/runs/42151561328/job/127676384122) — **passed**. That run's older browser harness hit Flutter DOM semantics interception; the follow-up below fixes only the harness, not application code.
- [Full strict SDK checks and real-browser/offline verification](https://github.com/Shitwitt/MoneyMate/actions/runs/42152170674) — **passed**: non-mutating Dart format, gen-l10n, analyzer, complete Flutter unit/widget suite, calendar/DST reruns and Python packaging/retry tests. Flutter stable 3.47.9 is the pinned baseline.
- [Separate push-triggered direct Gradle debug APK](https://github.com/Shitwitt/MoneyMate/actions/runs/42152170725) — **passed**, built using Gradle rather than `flutter build apk`.
- Browser: isolated editable demo and exit; real 14-step setup; live phone previews; full Home grid; accounts/reports; recurring calendar, help, history, process, skip and archive; light/dark persistence; offline reload; **zero external runtime requests**. All 12 fictional-data reference captures are in the web artifact.
- Layout regressions: full Home at 100%/160% text, saved/reversed ordering, safe deep-route demo exit with zero real-repository writes, plus 320×844 detail at 160% text in both LTR and RTL.
- Old JSON migration, recurrence anchors/atomicity/metadata, reporting-currency projections, actual recorded history/statistics, generated 36 core locales and offline fonts remain covered.

## Honest limits and installation safety

- **Export and verify a backup before uninstalling an older build.** This ephemeral CI test certificate differs from earlier delivered builds; Android will reject an in-place upgrade across different certificates. Uninstalling deletes local app data. Configure your own persistent signing key for future stable upgrades/Play distribution.
- Native compilation/inspection is not physical-device testing. Camera, biometrics, notification delivery/timing, widgets, OEM background restrictions and sideload/upgrade flows still need device QA. No iOS compilation, signing or device result is claimed.
- Data and portable backups are **unencrypted**. PIN/biometrics are interface locks, not database encryption. Pro is a persisted local simulation, never a payment.
- The 36 starter locales cover core navigation/actions, not every detailed finance form. Licensed Quicksand approximates the unknown reference font. Unseen setup pages and static-image animation timing cannot be certified as exact copies. Original Tink identity and local-only backup behavior are intentional; see [batch scope/adaptations](REFERENCE_BATCH_01.md).
- Contrast pairs and large-type/RTL regressions are documented, not a blanket accessibility certification.
