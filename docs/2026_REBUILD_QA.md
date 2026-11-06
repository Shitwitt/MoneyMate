# Tink 2026 rebuild — verification record

Date: **2026-11-06**. Version: **2026.11.6+6**. Package: `com.example.paisaclone`.

This is edited application source, not a renamed build-5 APK. The licensed legacy compatibility code, source pins and explicit product differences are documented in [the rebuild matrix](PAISA_2026_REBUILD.md). Build 5 is historical.

## Verified source baseline

At application revision `5eae8ae1c80cd40a66c67cec8dd0ee86a3d090d6`, [run 42219965783](https://github.com/Shitwitt/MoneyMate/actions/runs/42219965783), source job `127899266636` passed:

- Strict non-mutating Dart formatting and `flutter analyze --no-fatal-infos`.
- **293 Flutter tests**, including genuine multi-frame Home dragging, failed durable saves, import preview/cancel/save, profile/lock isolation, financial conversion, retained-original roundtrip, keyboard focus, account editing and 320px/160% LTR/RTL forms.
- **41 calendar regressions** rerun in `America/New_York` across DST-sensitive calculations.
- **24 Python regressions** covering offline packaging, licences/hashes, platform links, native opt-in/publication gates and exact source integrity diagnostics.
- Tracked source remained unchanged after the SDK/test commands. The SDK's four-line analyzer-exclusion migration was previously recovered as an exact patch and committed; the gate was not bypassed. Dependency versions were not guessed.

The browser run at that baseline correctly rejected a too-strict test locator for a merged privacy semantics label. The value-independent masks themselves rendered and the browser reported no app exceptions at that point. Later browser verification must pass; this source-only result is not APK publication.

## Browser acceptance

The dedicated 2026 journey runs six independent, disposable demos, collecting failures without skipping other cases. It must return to profile-less welcome before the original reference journeys and 14-step persistent setup run.

Required actual UI workflows:

1. Move a Home card inline and verify the resulting card geometry; keep the separate real-pointer Flutter drag/failed-save regressions.
2. Enable fixed-shape privacy, inspect merged accessible labels, disable privacy, copy a canonical page-only URL and read the actual clipboard.
3. Exclude a category in the filter UI, download the actual CSV, reconcile the declared full record count and inspect the exported category column. Descendant matching has separate ledger regressions.
4. Exercise real browser Enter/Next from Name to Amount to Notes, retain the expression/draft and cancel without using Save. Repository widget tests verify zero implicit writes.
5. Select and close an account panel at 800px portrait and 1280px landscape; no render exceptions.
6. Use the real file chooser with `test/fixtures/paisa_636.json`, explicitly choose currency and loan direction, inspect counts/notes, cancel confirmation, then create a separate temporary profile. Download the retained original through Backup and compare every byte; Exit Demo must discard the import.

The 12 required 2026 screenshots are verified and hashed by `.github/scripts/reference_2026_evidence.py`. All 27 Batch 3 and 39 Batch 4 frames, additional reference captures, CSV/PDF export/selection journeys, real chart holds/swipes, calculator metadata, persistent setup and offline reload remain required in the full browser run. Fictional sample records only; no private database or user screenshots are uploaded.

## Native acceptance and publication

Pending a successful fresh main build and direct-Gradle check. See [build status](BUILD_STATUS.md) for the current downloadable version; do not substitute the historical 1.3.0+5 APK.

The optimized APK may publish only after same-commit source, browser and every evidence gate pass. The publisher refuses a different build SHA or modified tracked source. It includes complete corresponding source from the exact build commit, original MIT/GPL/modification notices and checksums. APK inspection checks version/branding/package, all three native ABIs, signature, Android minimum, no Internet permission and the three bundled licence assets against their source hashes.

The separate direct `assembleDebug` workflow produces only an Actions artifact. It does not publish a competing debug APK release. Ordinary UI/source pushes do not opt into either native build.

## Still real-device work, not certified by CI

- Native file-provider/camera permissions, camera/gallery results and cancelled save/share flows on an actual phone.
- Native cold/resumed URI dispatch, queued pages while locked/in an editor and biometric behavior.
- Real Android/iOS keyboard insets, accessibility services, 200% OS fonts and OEM variations.
- Notification timing/background restrictions and launcher widgets; a compile does not prove delivery or refresh.
- Persistent-keystore upgrade with data retained, oldest/current Android installations and an iOS archive on a configured Mac.

Use fictional data first. Export **and verify** a backup before uninstalling a differently signed older Tink; uninstall deletes local data. Data, original legacy JSON and backups are unencrypted. A PIN is an app lock, not database encryption. Current official Paisa formats, complete translations, cloud-account integration and whole-app official tablet/feature parity are not claimed.
