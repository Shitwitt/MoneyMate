# Tink 1.3 reference batch 1 — delivered build evidence

**Version 1.3.0+4**, branch `arena/9ea2a134-moneymate`, verified 6 November 2026.
[The 1.2 build is historical](HISTORICAL_1_2_BUILD.md), not this delivery.
Earlier 1.3 candidates are superseded by the final OFL-compliant font-name build below.

> **Batch 2 build hold:** the current branch's Home/Accounts/Reports/Budgets UI is
> newer than the Batch 1 packages documented below. No Batch 2 APK has been
> compiled or published. Ordinary pushes skip both native jobs until the user
> explicitly requests “make APK.” [Batch 2 scope and verification](REFERENCE_BATCH_02.md).

## Downloads and identity

- **[Updated Android APK](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42153449531/Tink-Android-release.apk)**
- **[Current runnable source ZIP](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42153449531/Tink-source.zip)** · [source SHA-256](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42153449531/Tink-source.zip.sha256)
- [APK SHA-256 file](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42153449531/Tink-Android-release.apk.sha256) · [package/certificate metadata](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42153449531/Tink-APK-metadata.txt)

| Property | Verified value |
| --- | --- |
| Release tag | `apk-release-42153449531` |
| Native application / full SDK-browser verification revision | `6dac3439c7614755f7997c847b6602577dd44d75` |
| App/version | Tink 1.3.0, build 4 |
| Package ID | `com.example.paisaclone` — legacy ID preserved; displayed brand is Tink |
| APK bytes | `96,865,703` |
| APK SHA-256 | `2f60f5609b1477bc182f56ad07528e867151a61e7018b3e9d7154bef5b611e2a` |
| Signing certificate SHA-256 | `16af1e7195942500bae8068f3e8cc5dbc8d894bb1494fe80a8cbfae0dee3862f` |
| Signing certificate SHA-1 | `77e1f2ae7d31f054374c83db77d72e365d1c6030` |
| Android | Minimum API 24 (Android 7), compile SDK 36 |
| Native payload | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| Internet permission | Absent, checked in the built APK |
| Signing | Release-mode/AOT APK, **Android Debug test certificate**, not store signing |

The source ZIP may include later README/docs/CI updates. Its ZIP comment identifies
the exact source commit. The source-only publisher enforces no differences from
the APK revision in `lib`, `android`, `ios`, `web`, `assets`, `test`, `scripts`,
`pubspec.yaml`, `pubspec.lock` or `l10n.yaml`. It cannot replace/re-sign the APK.

## Checks actually passed

- [Full release workflow 42153449531](https://github.com/Shitwitt/MoneyMate/actions/runs/42153449531) — **all checks, browser and native jobs passed** on the same application revision. Includes strict non-mutating Dart format, gen-l10n, analyzer, complete Flutter unit/widget suite, calendar/DST reruns and Python packaging/retry/font tests. Flutter stable 3.47.9 is the pinned baseline.
- [Native build, package/branding/version/ABI/permission/signature inspection and publication](https://github.com/Shitwitt/MoneyMate/actions/runs/42153449531/job/127682426870) — **passed**.
- [Separate push-triggered direct Gradle debug APK 42153449674](https://github.com/Shitwitt/MoneyMate/actions/runs/42153449674) — **passed**, built using Gradle rather than `flutter build apk`.
- Browser: isolated editable demo and exit; real 14-step setup; live phone previews; full Home grid; accounts/reports; recurring calendar, help, history, process, skip and archive; light/dark persistence; offline reload; **zero external runtime requests**. All 12 fictional-data reference captures are in the web artifact.
- Layout regressions: full Home at 100%/160% text, saved/reversed ordering, safe deep-route demo exit with zero real-repository writes, plus 320×844 detail at 160% text in both LTR and RTL.
- Old JSON migration, recurrence anchors/atomicity/metadata, reporting-currency projections, actual recorded history/statistics, generated 36 core locales and offline fonts remain covered.
- Final font license audit: locally instanced Quicksand files renamed to **TinkRounded** under the OFL Reserved Font Name condition. Original notices are retained. Three new tests verify primary names, 400–700 registration and byte-identical glyph/metric/layout tables; **all 10 Python tests passed**. All 12 final browser thumbnails are byte-identical to the reviewed pre-rename evidence.

## Honest limits and installation safety

- **Export and verify a backup before uninstalling an older build.** This ephemeral CI test certificate differs from earlier delivered builds; Android will reject an in-place upgrade across different certificates. Uninstalling deletes local app data. Configure your own persistent signing key for future stable upgrades/Play distribution.
- Native compilation/inspection is not physical-device testing. Camera, biometrics, notification delivery/timing, widgets, OEM background restrictions and sideload/upgrade flows still need device QA. No iOS compilation, signing or device result is claimed.
- Data and portable backups are **unencrypted**. PIN/biometrics are interface locks, not database encryption. Pro is a persisted local simulation, never a payment.
- The 36 starter locales cover core navigation/actions, not every detailed finance form. Licensed Quicksand-derived TinkRounded approximates the unknown reference font. Unseen setup pages and static-image animation timing cannot be certified as exact copies. Original Tink identity and local-only backup behavior are intentional; see [batch scope/adaptations](REFERENCE_BATCH_01.md).
- Contrast pairs and large-type/RTL regressions are documented, not a blanket accessibility certification.
