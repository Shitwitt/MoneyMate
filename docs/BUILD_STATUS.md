# Tink 1.3 — current source verification and historical Batch 1 binaries

**Version 1.3.0+4**, branch `arena/9ea2a134-moneymate`, verified 6 November 2026.
[The 1.2 build is historical](HISTORICAL_1_2_BUILD.md), not this delivery.
The historical Batch 1 binaries below and the newer source/browser revisions are deliberately distinguished.

## Batch 4 and whole-app reference review — complete source/browser verification

Application/source revision **`4f018d40e9193e8cd916c90a5d0e6b0d3333b5ae`**,
[run 42203316290](https://github.com/Shitwitt/MoneyMate/actions/runs/42203316290), **SUCCESS**.

| Check | Result |
|---|---|
| Strict SDK format, analyzer, complete Flutter suite, localization, DST/calendar, all 15 Python regressions, source archive | PASS — `127843696973` |
| Connected Batch 1–4 Chromium journeys, real holds/swipes, scoped PDF/CSV downloads, $2.50 calculator save/notes, context edits, unsaved recurring cancellation, setup/persistence/offline/zero external requests | PASS — `127844476713` |
| All 39 Batch 4 full-frame gates / bounded review copies | PASS — catalog `127846782379`, entry `127846782257`, context `127846783557`, health `127846782523`, recurring `127846782241` |
| All 27 refreshed Batch 3 frame gates / bounded review copies | PASS — loans `127846782305`, goals `127846782409`, labels `127846782921`, Analytics `127846783099` |
| Additional existing-reference captures | PASS — `127846782520` |
| Release APK | SKIPPED — `127844479187` |
| Separate direct-Gradle debug APK | SKIPPED — run `42203316348` |

All 66 current review copies were reviewed: 44 byte-identical to already opened
frames and 22 new/changed copies reopened. Full-size presence/JPEG integrity is
checked in CI; bounded review is not pixel/font/motion/device certification.
[Frame hashes and provenance](REFERENCE_REVIEW_04.json).

Newer source retains Batch 1–3 features and adds connected Categories, complete
transaction metadata/calculator, People/Places and a disclosed local Spending
Health review. The whole-app reference audit adds full-filtered/selected CSV/PDF
choices, initialized search and Tink/legacy automation compatibility without
importing unavailable proprietary app source. Selected records survive later
search changes; insight/habit pages survive lazy vertical-list recycling.

[Download this verified application source](https://github.com/Shitwitt/MoneyMate/archive/4f018d40e9193e8cd916c90a5d0e6b0d3333b5ae.zip)
or the run's `Tink-source` artifact. `Tink-Batch-4-source.zip` can include later
README/docs-only updates; its ZIP comment identifies the exact source commit and
verified application revision. There are no subsequent application/build/test
changes in that handoff. It contains no APK.

**No new native build. The historical APK below does not contain these source
changes.** Device/iOS and native widget/link behavior remain unverified; the three
Python platform-contract tests are static only. See [Batch 4 scope and checks](REFERENCE_BATCH_04.md)
and [whole-app provenance, feature mapping and limits](PAISA_REFERENCE_AUDIT.md).
Both native paths remain opt-in until the user explicitly says **“make APK.”**

## Batch 3 — historical completed baseline

[Run 42189659642](https://github.com/Shitwitt/MoneyMate/actions/runs/42189659642)
at `244c9b62bdc7a7adbf60a81525e6ff647f8aa631` passed source, browser/offline
and all 25 historical review-frame gates. Partial posted repayment, loan/goal/
label updates, goal archive/restore, transaction-copy draft and a genuine
Analytics swipe were verified. Release job `127799062289` and direct-Gradle run
`42189659815` were skipped. [Detailed Batch 3 verification](REFERENCE_BATCH_03.md).

## Batch 2 — historical completed source/browser evidence, no new APK

All 20 supplied Batch 2 references are implemented at application revision
**`133f36c8b72bc0039f6051bd3d7483d1634340b0`**.
[Run 42171659295](https://github.com/Shitwitt/MoneyMate/actions/runs/42171659295)
is **SUCCESS**:

| Check | Result |
| --- | --- |
| SDK formatting, localization, analyzer, full Flutter suite, DST/calendar, Python regressions, source archive | PASS — job `127740674393` |
| Chromium walkthrough, both chart modes, all five financial reports, offline reload and zero external runtime requests | PASS — job `127741236539` |
| 28 fictional-data review frames across both evidence jobs | Captured and reviewed; supplemental job `127742275702` PASS |
| Release Android APK | SKIPPED — job `127741238094` |
| Separate direct Gradle debug APK | SKIPPED — run `42171659300` |

[Download the verified Batch 2 application source ZIP](https://github.com/Shitwitt/MoneyMate/archive/133f36c8b72bc0039f6051bd3d7483d1634340b0.zip)
or the run's `Tink-source` artifact. The source-only handoff
`Tink-Batch-2-source.zip` may add README/docs updates, with its exact commit in the
ZIP comment and its checksum in the companion file. No application/build/test
changes are made after the verified revision. It is not an APK and is not the
older source ZIP paired with the Batch 1 release below.

See [all 20 references, financial rules, coverage and limits](REFERENCE_BATCH_02.md).
This verifies source and browser behavior, not Android installation/device QA or
iOS. No new APK has been compiled or published during the hold.

## Batch 1 — existing downloads and identity

- **[Updated Android APK](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42153449531/Tink-Android-release.apk)**
- **[Batch 1 runnable source ZIP](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42153449531/Tink-source.zip)** · [source SHA-256](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42153449531/Tink-source.zip.sha256)
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

The Batch 1 source ZIP may include later README/docs/CI updates. Its ZIP comment identifies
the exact source commit. The source-only publisher enforces no differences from
the APK revision in `lib`, `android`, `ios`, `web`, `assets`, `test`, `scripts`,
`pubspec.yaml`, `pubspec.lock` or `l10n.yaml`. It cannot replace/re-sign the APK.

## Batch 1 — checks actually passed

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
