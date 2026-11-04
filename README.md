# PaisaClone 🌱

**Your money. Your device.** An independent Material 3 / Material You Flutter expense tracker inspired by the privacy-first spirit of Paisa. Original source and branding; not affiliated with Hemanth Savarala, `dev.hemanths.paisa`, or paisa-tracker.app.

No accounts, backend, ads, analytics, payment service, or automatic network calls. The Android release deliberately has **no Internet permission**. All finance data and receipt images are local. Plus is a free, persisted simulation.

> This is a substantial, runnable implementation, not a claim of byte-for-byte or certified feature parity with Paisa. See [platform support and known limits](#platform-support-and-known-limits), [architecture](docs/ARCHITECTURE.md), and [device QA](docs/QA.md). Native biometrics, camera, notification delivery and widgets require real-device verification before distributing your own release.

## Project structure (start here)

```text
PaisaClone/
├── pubspec.yaml                 # Complete dependencies, bundled art/fonts, version
├── l10n.yaml                    # Flutter gen-l10n configuration
├── lib/
│   ├── main.dart                # Bootstrap, recovery, themes, links, app-wide lock
│   ├── core/
│   │   ├── models/models.dart   # Explicit typed JSON models; no build_runner
│   │   ├── data/                # Hive repository, atomic controller, ledger, seeds
│   │   ├── services/            # Backups, CSV/PDF, receipts, notifications, widgets
│   │   ├── theme/               # Material 3 light/dark/Just Black/dynamic color
│   │   └── utils/               # Fixed-point money, arithmetic, calendar rules
│   ├── features/
│   │   ├── onboarding/          # Wizard, first account, demo/restore
│   │   ├── home/                # Dashboard, navigation, net worth, More
│   │   ├── transactions/        # Entry, calculator, filters, history, templates
│   │   ├── accounts/            # Grouping, account images, transfers, tablet pane
│   │   ├── budgets/ goals/ loans/ bills/ assets/ recurring/
│   │   ├── catalog/             # Categories, labels, people, places
│   │   ├── reports/ achievements/
│   │   └── settings/            # Preferences, PIN/biometrics, layouts, import, help
│   ├── shared/                 # Reusable forms, charts, progress painter, states
│   └── l10n/                   # 13 ARB starter translations + generated output
├── android/
│   ├── gradlew / gradlew.bat / gradle/wrapper/   # Actual Gradle wrapper included
│   ├── settings.gradle / build.gradle / gradle.properties
│   └── app/
│       ├── build.gradle         # applicationId, minSdk 23, optional signing
│       └── src/main/
│           ├── AndroidManifest.xml
│           ├── java/com/example/paisaclone/     # Kotlin Activity + 3 native widgets
│           └── res/             # Icons, themes, widget layouts and definitions
├── ios/                         # Xcode runner, Podfile, privacy manifest
│   └── PaisaWidgets/            # Real WidgetKit extension target, 3 widgets
├── web/                         # Offline-capable PWA shell, manifest, icons
├── assets/branding/ fonts/ templates/
├── test/                        # Finance, persistence, import, security, widget tests
├── scripts/create_web_cache.py  # Self-hosted post-build offline cache
├── docs/                        # Architecture, feature matrix, QA and signing
└── .github/workflows/
    ├── build.yml                # Gradle assembleDebug → downloadable debug APK
    └── build-apk.yml            # Analyze/test → release APK + Web + source ZIP
```

## GET YOUR APK NOW

**Here is how you get the APK ready to download and install** — fastest methods first:

### 1. GitHub Actions — no local Flutter or Android SDK needed

1. Put **the contents of this project at the root of a GitHub repository**, including the hidden `.github` folder. Do not put it inside another `app/` directory. In this checkout the actual connected repository is **Shitwitt/MoneyMate**, not the example `yourusername/moneymate-app`.
2. Push the files, then open the repository’s **Actions** tab. Both workflows run on every push. If needed, choose a workflow → **Run workflow** → select your branch → Run.
3. For the quickest sideloadable build, open **Debug APK (Gradle)**. For optimized code choose **Release APK + Web + Tests**.
4. Wait for a **green completed run**. Open the run and scroll to **Artifacts**.
5. Download **PaisaClone-debug-APK** or **PaisaClone-release-APK**. GitHub wraps artifacts in a ZIP: **extract it** to get `app-debug.apk` / `app-release.apk`.
6. Send that `.apk` to your Android device, tap it, allow **Install unknown apps** for your browser/files app, then tap **Install**.

GitHub requires you to be signed in to download workflow artifacts. Workflows cannot run if Actions are disabled, the account has exhausted its Actions quota, or the repository’s policy blocks the actions used here. Enable Actions in repository Settings and rerun; never paste tokens or signing secrets into source files.

**Signing default:** debug builds and the default release fallback are **debug-key-signed and installable**, not unsigned. Without a persistent key, a new CI runner may generate a different certificate. Updating an old install then requires uninstalling it first (which deletes local data). **Export and verify a backup first.** For stable upgrade identity or Play Store publication configure your own signing key below.

### 2. Local Flutter — exact commands

Install **Flutter stable 3.47.9** (the workflow’s reproducible stable baseline), Android Studio / Android SDK, and **JDK 17**. Newer stable Flutter versions may work; re-run tests and update Android Gradle/Kotlin tooling together when upgrading.

```bash
cd PaisaClone                    # or cd MoneyMate
flutter --version
flutter doctor -v
flutter doctor --android-licenses
flutter pub get                  # resolves packages and generates project metadata
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --release
```

The installable universal APK is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For a debug APK / smaller per-ABI APKs / a store bundle:

```bash
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release --split-per-abi
# app-arm64-v8a-release.apk for most current phones
flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab (not directly sideloadable)
```

Install from a connected computer:

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
# Or: flutter install --release
```

Do not uninstall an existing install to fix a signature mismatch until you have exported and verified its backup. An `.aab` is for store distribution; use an `.apk` to sideload.

### 3. Android Studio — or a hosted Flutter builder

* Open **this project root** in Android Studio, install the Flutter/Dart plugins, choose your Flutter SDK, and run **Pub get**. Run on an Android device with the toolbar. The IDE terminal command `flutter build apk --release` is the simplest reliable way to get the same APK as CI. Android’s **Build → Generate Signed Bundle / APK** also works after opening the `android/` module and supplying your key.
* **Codemagic:** connect your repository, select a Flutter workflow, set Flutter 3.47.9 / Java 17, run `flutter pub get`, `flutter gen-l10n`, `flutter test`, and `flutter build apk --release`, then publish `build/app/outputs/flutter-apk/*.apk`. Check its current pricing/quota before relying on a free tier; no free allowance is guaranteed here. Configure signing in the builder’s secret store, not Git.
* **App Center is not a viable new-build recommendation:** its build service has been retired. Generic online Flutter builders vary widely; only upload code you trust and never give an unknown builder your private finance backups or production keystore. GitHub Actions is the included supported hosted path.

## Quick start / run

```bash
flutter pub get
flutter gen-l10n
flutter run                      # select Android / iOS device
flutter run -d chrome            # development web build
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

No `.env`, API keys, Firebase project, backend, schema generator, or login is required. On first launch choose a name, currency and first account. Enable sample data to seed fictional activity in that new profile, or restore a JSON/ZIP backup. More → Settings → Profiles can create separate personal/business/demo spaces without touching your existing records.

## Release signing (recommended before your first long-term install)

Generate a private keystore once and **keep a safe offline copy**:

```bash
keytool -genkeypair -v -keystore "$HOME/paisaclone-upload.jks" \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Copy it to `android/upload-keystore.jks`, then create **untracked** `android/key.properties`:

```properties
storeFile=upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
```

`storeFile` is resolved relative to `android/`. You can also use an absolute path. The release build automatically selects this key; no code changes are needed. Without the file it explicitly falls back to the debug key for easy sideloading. This fallback is **not** a Play Store production signing configuration.

For **GitHub Actions** add these repository **Actions secrets**:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded bytes of your JKS |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | `upload` (or your alias) |

Encode on Linux with `base64 -w 0 "$HOME/paisaclone-upload.jks"` (macOS: `base64 -i "$HOME/paisaclone-upload.jks" | tr -d '\n'`). Store the result **only in the GitHub secret UI**. The workflow reconstructs it in its disposable runner. Never commit keys/passwords, paste them into chat, or include them in your source ZIP. Preserve this key across upgrades; Android uses the certificate plus `applicationId` as app identity.

## Web build & genuine offline use

```bash
flutter build web --release --no-web-resources-cdn
python3 scripts/create_web_cache.py
python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web
```

Deploy `build/web` to an HTTPS static host. For a subdirectory add `--base-href /your-path/`. The included post-build script precaches **local app files only** (renderer, JS/Wasm, bundled fonts, icons); no runtime font or renderer CDN is needed. First visit must finish loading online before offline reload works. A browser’s HTTPS/localhost secure context is required for service workers. Financial data lives separately in Hive/IndexedDB per browser origin. Clearing site data, private browsing, storage eviction or changing hostnames can erase it. **A PWA cache is not a data backup.**

Camera/gallery and download/share behavior depend on the browser. Biometrics, native local notifications and OS home widgets are mobile-only; the web UI states this instead of pretending they work.

## iOS

macOS + current Xcode + CocoaPods and an iOS 15+ device are required:

```bash
flutter pub get
flutter gen-l10n
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
flutter run
# Distribution requires your Apple signing/provisioning setup:
flutter build ipa --release
```

The runner includes camera/photo/Face ID usage descriptions, a custom URL scheme, privacy manifest, and a real **PaisaWidgets WidgetKit extension target** (balance, budget, quick add). In Xcode set **your development team for Runner AND PaisaWidgets**, use unique bundle IDs, and register the same **App Group** in both entitlements and `WidgetService` (`group.com.example.paisaclone` is the example). App Groups may require a paid Apple developer team. If you only want the iOS app without widgets, remove the PaisaWidgets target dependency/embed phase and App Group entitlements in Xcode. Actual distribution requires provisioning; no iOS signing identity is included or requested.

The project opts for CocoaPods; if your Flutter installation enables experimental/default Swift Package Manager migration, disable it for this checkout with `flutter config --no-enable-swift-package-manager` before `pod install`.

## What works

* **Local profiles and onboarding:** separate financial records, first account, currencies, default income/expense categories, deterministic six-month demo, restore preview.
* **Customizable dashboard:** saved card order/visibility, reorder handles, net worth details, income/expense, account carousel, six-month chart, budgets/goals, daily-grouped recents, one-tap templates, subscriptions, assets, loans, reports, achievements and Plus.
* **Activity:** expense/income/atomic two-account transfer, integer money, arithmetic keypad, history-name suggestions, account/category/date/time, notes, labels/people/place, goal/loan tags, up to five photo receipts, sequential entry, edit/delete swipes and bulk deletion. Search plus date/account/category/tag/person/place/type/min/max filters, sticky daily headers, paging, sorting, totals, filtered CSV.
* **Accounts/catalog:** currency per account, signed opening balances, types/icons/photos/colors, exclusion/archiving, grouping, account detail/transfers, tablet list/detail; category CRUD/reorder/hide and charts; label/person/place CRUD, photos/notes, counts, linked activity and report breakdowns.
* **Plans:** recurring/custom budgets, category scope, signed rollover, 50/80/100% alerts; goals with deadlines, allocations or linked-account progress, tagged income, milestones; earned badges and confetti.
* **Debts/bills/assets:** lent/borrowed with optional flat interest, partial/full repayments, optional atomic disbursement/repayment account entries, due reminders; equal/percentage/exact/weighted bill splits with exact rounding, net settlement suggestions, settled history and optional loan creation; manual asset values/purchase information and full value history.
* **Recurring entries:** daily/weekly/monthly/yearly/custom intervals, start/end, pause/resume/skip, auto-post vs remind-only, idempotent catch-up, monthly burn normalization.
* **Reports:** touch-enabled bar/line/category donut, filters/custom dates, category/account/name/tag/person/place breakdowns; Plus daily pace/projection, preceding equal-duration and prior-year comparisons, weekday seasonality, daily heatmap; CSV, multi-page PDF and printing with bundled Noto font fallbacks.
* **Preferences:** Material 3 system/light/dark/Just Black, dynamic Android colors/accent palettes, text size, 13 navigation/action language starters + RTL, international/Indian numbering, financial month and week starts, PBKDF2 PIN/biometrics, hidden amounts, notification preferences, JSON/ZIP export with embedded receipts/checksum/restore preview, CSV mapper/validation/deduplication, home/nav customization/live nav preview, rates, widgets, links, help and licenses.
* **Plus simulation:** repository-enforced free creation limits (3 budgets, 3 goals, 3 bills, 10 of each tag/entity), advanced-report/PDF/theme gates, persisted free unlock/restore/test-free controls. Downgrading never deletes existing data.

## Privacy & backup details

* Hive snapshots are **not encrypted at rest**. The device sandbox/device encryption protect native storage. PIN/biometrics protect the UI, above the whole Navigator. The PIN is a salted PBKDF2-HMAC-SHA256 derivation (120,000 iterations), never a plaintext saved PIN. Five incorrect attempts trigger a 30-second in-process delay. This is not protection against rooted devices, hostile browser extensions or offline database attacks.
* Background/lock obscures the UI; widgets omit amounts if app lock or hide-amounts is enabled. PIN derivations are omitted from portable backups. Restores preserve the current installation’s lock and disable silent automation/notifications for review.
* ZIP/JSON exports include **all profiles and full amounts**, not just the current search or hidden UI values. Files are **unencrypted**. ZIP embeds the JSON with receipt base64; paths are never extracted. Import verifies format/schema/checksum, IDs, currencies, amounts and references before one durable commit. The checksum detects corruption, not malicious tampering/authenticity.
* CSV supports income/expense rows, ISO dates, positive decimal amounts, mapped columns, validation preview, duplicate-ID/fingerprint skips, then atomic batch import. It is not a full-fidelity backup: transfers, attachments and all metadata use JSON/ZIP. CSV export neutralizes spreadsheet formula injection in text fields.
* Scoped Android/iOS system pickers and app-private files mean **no broad storage or all-files permission is needed**. Camera/biometric/notification permissions are declared and requested only as appropriate. Debug/profile builds alone include Internet permission for the development VM service.

## Links / Tasker automation

```text
paisa://quick_add
paisa://add?amount=180&type=expense&name=Coffee&account=Everyday&category=Food%20%26%20Dining
paisa://silent_add?amount=180&type=expense&name=Coffee&account=Everyday&category=Food%20%26%20Dining
```

Optional parameters: `date` (ISO 8601) and `notes`; account/category accept an existing ID or case-insensitive name. Missing type defaults to expense, missing account/category uses the first valid match. Unknown names, negative/nonfinite amounts and transfer requests are rejected. The default path always asks for confirmation; `silent_add` posts only after unlock and after enabling its explicit security warning/toggle in Help. Any installed app can invoke a custom URI, so enable silence only on a trusted device. Pending requests wait for onboarding/unlock.

```bash
adb shell am start -a android.intent.action.VIEW \
  -d 'paisa://quick_add' com.example.paisaclone
```

`https://paisaclone.example/add?...` in the manifest is a **deliberately unverified placeholder**, not a hosted fallback. To distribute verified HTTPS links, replace it with a domain you own; host a fallback page plus `.well-known/assetlinks.json` with your package/signing certificate and `apple-app-site-association`; set Android `autoVerify` and iOS Associated Domains. Do not claim ownership of paisa-tracker.app or use the original app’s package ID.

## Customization

* App identity: `pubspec.yaml`, `constants.dart`, Android namespace/application ID and Kotlin package/path, iOS bundle IDs, widget App Group/entitlements, display names and web manifest. Change them consistently.
* App art/icons: replace bundled original PNGs in `assets/branding`, Android mipmaps, iOS `AppIcon.appiconset`, and `web/icons`. No remote fonts are loaded.
* Categories/demo: `lib/core/data/seed.dart`. Rates there are illustrative **2026-01-01 reference values**, not quotes. Manual edits update their own timestamps; there is deliberately no fake “live refresh”.
* Add a language: copy `lib/l10n/app_en.arb`, translate keys, add its label to `languageNames`, run `flutter gen-l10n`. Generated Dart is intentionally not committed; `flutter pub get`/gen-l10n produces it. The 13 included ARBs cover the app shell and primary actions; detailed form/help text remains English.
* Version: increment `version: 1.0.0+1` in `pubspec.yaml` before shipping an update; change the iOS extension version too. Commit `pubspec.lock` after resolving to keep application dependencies reproducible.

## Platform support and known limits

| Capability | Android | iOS | Web |
|---|---|---|---|
| Local finance CRUD / reports / backups / CSV / Plus | Yes | Yes | Yes |
| Receipts via picker / camera | Yes | Yes, permission strings included | Browser-dependent |
| PIN interface lock | Yes | Yes | Yes, not browser-storage encryption |
| Biometrics | Device setup needed | Face ID / Touch ID setup needed | Not exposed |
| Local reminders | OS permission / battery policy | OS permission / pending cap | Not supported |
| 3 home widgets | Native providers included | WidgetKit target + your team/App Group | Not supported |
| Deep-link entry | Custom scheme included | Custom scheme included | Query prefill / manual URI handling |
| Offline relaunch | Native | Native | After complete HTTPS app-shell caching |

Other deliberate boundaries:

* Recurring ledger writes happen on launch/resume, not a background service. Inexact reminders do not guarantee a specific minute or execute finance writes. Up to 1,000 missed occurrences per rule are caught up per pass.
* No exchange-rate provider, bank sync, geocoding, receipt OCR, real purchase validation, Drive SDK or server. Assets are manual and loan interest is flat, not amortized/APR. Split bills have one payer; net suggestions are computed across outstanding bills. “Mark settled” is a tracker action, not a payment; use Activity/Loans for actual account movement.
* Manual goal contributions do not move funds. Avoid counting the same allocation twice by manually contributing and tagging the same income; avoid double-counting an asset also represented in an included account.
* Whole-state Hive snapshots intentionally make financial edits atomic and backups portable. Writes/filters/analytics are O(n), suitable for personal ledgers; a very large ledger or many photos increases memory/serialization cost. Lists page visible history in batches of 80. Import safety caps are 50 MB, 200,000 stored transactions per profile, 50,000 CSV rows, five receipts per entry and 2 MB per photo. This is not a benchmarked enterprise ledger.
* PDF includes a summary, category bars/interpretation and paginated tables, not raster screenshots of Flutter charts. Noto fallback fonts are bundled; complex-script shaping/printing still needs platform/device QA.
* Plus is intentionally bypassable local state, not purchase security. Forgotten PIN recovery requires a verified export and reinstall/reset; there is no secret backdoor.
* Home dashboard is a responsive centered feed; accounts have a true tablet list/detail split. Not every feature is a two-pane editor. Native mobile features are not emulated on web.
* No exhaustive original-app compatibility, imported Paisa backup compatibility, exact visual clone, security audit, store approval or production certification is claimed. Review [QA](docs/QA.md) and test signed upgrades, restoration and native integrations before entrusting important data to any release.

## Source ZIP

Download **Code → Download ZIP** for your branch, or the **PaisaClone-source** workflow artifact. The archive contains the complete source tree, native wrappers and all bundled assets; SDKs, build outputs, private data, keystores and generated caches are intentionally excluded. Unzip, enter the folder containing `pubspec.yaml`, then run the commands above. You do **not** need to run `flutter create` or hand-copy files into a native `app/src` project.

## Checks

```bash
dart format lib test
flutter gen-l10n
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release
flutter build web --release --no-web-resources-cdn
python3 scripts/create_web_cache.py
```

Tests cover fixed-point currencies, expressions, serialized writes and failure rollback, transfers and reversal, profile isolation, free limits, calendar edges/rollover, recurring idempotency, debt/account consistency, exact bill allocation, currency rebasing, filters, backup/checksum/receipts, real Hive reopen persistence, CSV validation/deduplication, deep links, PBKDF2 verification and basic widget navigation. See Actions for the result of the specific commit you build; instructions are not a claim that an unrun workflow succeeded.

MIT licensed; package/font licenses remain their own. Improvements welcome: full-string translations, encrypted-at-rest migration with recoverable key design, larger-ledger indexing, Android background reconciliation with explicit battery/consent tradeoffs, optional verified-link hosting, and broader device integration tests.
