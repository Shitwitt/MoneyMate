# Whole-app Paisa reference audit

Reviewed **2026-11-06**. This extends the supplied screenshot batches; it does not replace Tink's existing data, finance engine, branding, features or offline constraints.

## Reference provenance and reuse boundary

- [Public website](https://paisa-tracker.app/): feature overview and linked layouts.
- [FAQ / feature guide](https://paisa-tracker.app/faq): advertised workflows, including budgets/rollover, subscriptions, loans, bill splitting, assets, filters, exports, customization, backup and widgets.
- [Automation guide](https://paisa-tracker.app/automation): documented custom-URI parameters and examples.
- [Supplied GitHub releases](https://github.com/h4h13/paisa-app/releases): the newest public release returned by GitHub at review time was [v2025.08.21](https://github.com/h4h13/paisa-app/releases/tag/v2025.08.21), published 2025-08-21. A public release date is not proof of the version currently distributed by app stores or of the website's current implementation.

**The supplied repository is not the full Flutter app source.** Its recursively inspected current tree contains release documentation, translations, screenshots and paywall data, but no `lib/` app or `pubspec.yaml`. The release tag above also has no Flutter app source. Inspected tree IDs: main `c2ebfc0356141b6e161dfa9b3e9617205e3fae16`; release tag `55dd6d180e3e1353f6e1c90e338e1d75051786e7`. GitHub's automatic “Source code” archives package those trees; they are not a hidden app-source distribution.

The [repository README](https://github.com/h4h13/paisa-app#readme) states **“Copyright (c) 2022, Hemanth Savarala — All rights reserved.”** It points to `RetroMusicPlayer/Paisa`, which did not resolve as a publicly accessible repository during this review. Public visibility is not a reuse licence. No app code, translation files, proprietary fonts, screenshots, logos, paywall data or APK binaries from Paisa have been imported into Tink. The website, documentation and release notes are behavioral/visual references for independent implementation. Tink's existing licence and third-party notices remain unchanged.

The README also warns that switching between store and GitHub APKs can cause signing mismatch and data loss. Tink retains its own explicit backup/signing warnings; original Paisa binaries are not Tink upgrades and must not be relabeled as such.

## Feature mapping

“Implemented” below describes inspectable Tink source and working connections, **not certification of every platform, a byte-for-byte clone, or complete Paisa parity**. Native checks remain subject to the APK hold and device QA.

| Reference area | Existing Tink implementation and preserved behavior | Boundary / follow-up |
|---|---|---|
| Getting started | `features/onboarding/`: 14-step setup, feature previews, first account, restore, isolated editable demo and clean exit | Missing original stills remain original Tink designs; no invented reference screens |
| Accounts and balances | `features/accounts/`, `core/data/ledger.dart`: account kinds/finishes, grouping, signed opening balances, manual FX, linked transfers, summaries and account history | Bookkeeping only; no bank connection, issued cards, real payments or live market quotes |
| Add/search transactions | `features/transactions/`: income/expense/transfer, calculator, templates/autocomplete, dates/times, descriptions, links, receipts, filters, sort and bulk actions | Full-page fixed save footer and retained collapsed metadata from Batch 4; no silent overwrite of unrelated fields |
| Categories | `features/catalog/categories_screen.dart`, `category_detail_screen.dart`: type tabs, ID hierarchy, colors/icons/order, counts, scopes, subtree allocation, donut, monthly line/weekly bars, held values and exact record routes | Referenced categories hide instead of destroying history; editor can restore hidden categories |
| Labels | `features/catalog/labels_screen.dart`: many-to-many tags, colors, scopes, signed totals, detail/edit/filter | A record may belong to several labels; totals are not additive across overlapping labels |
| People / Places | `features/catalog/context_screen.dart`: manual local contexts, list/grid/sort/scopes/help, linked history, add/edit and non-destructive deletion | No contacts upload, location tracking or network map service |
| Budgets / rollover | `features/budgets/`, `core/data/ledger.dart`: several simultaneous plans, category trees/manual links, daily/weekly/monthly/yearly/custom windows, active/upcoming/past, rollover/overspend, allowance history | Notifications depend on permission/OS delivery; custom one-off budgets do not pretend to recur |
| Goals | `features/goals/`: contributions, deadlines, linked-account option, raw signed progress, statuses/sorting/edit/archive | Planning allocations do not move real money; linked goals use the whole saved account balance rather than deposits only |
| Simple loans | `features/loans/`: lent/borrowed, people/dates/notes, partial/full repayments, optional account links, manual closure, history and retained FX agreements | Flat lifetime interest, not APR. Closing manually does not invent a repayment. Ordinary tags are not implicit payments |
| Subscriptions / recurring | `features/recurring/`: overview, All/Calendar, statuses/help, multiple frequencies, reminders/end/budget/tags, process/archive/history | Catch-up on launch/resume, not guaranteed background ledger writes. Repeating-purchase suggestions are unconfirmed and unsaved; explicit Save, retained next due and automatic posting off prevent historical replay |
| Bill splitter | `features/bills/`: participants/payer, equal/exact/percentage/weighted shares, integer reconciliation, settlements and net suggestions | A recorded settlement is bookkeeping, not a real payment |
| Assets / net worth | `features/assets/`, `features/home/net_worth_screen.dart`: manually valued assets/history, account/debt-aware worth and disclosed safe-to-spend calculation | No custody, automatic stock prices or guaranteed investment forecast |
| Reports / analytics | `features/reports/`: five reports, bar/line charts, period/filter selection, CSV/PDF/print, trends, six-month baselines, unusual records, projections and scoped drilldowns | Current manual reference rates, explicit partial periods, estimates and undefined baselines; not fabricated AI |
| Filtered search exports | `core/services/transaction_export_service.dart`, `shared/transaction_export_sheet.dart`: CSV/PDF for all matching records or explicit selection, not just the rendered page, with scope/privacy warning | Exports include full amounts even when UI privacy is on. CSV carries private notes; files are unencrypted. Not a full-fidelity backup |
| Home / layout customization | `features/home/`, `features/settings/layout_screen.dart`: dashboard cards, summaries, trends, heatmap, templates, upcoming, destination configuration and persisted ordering/visibility | Reordering is in Layout settings; direct long-press reordering of grouped Home cards is **not** claimed as implemented |
| Appearance | `core/theme/`, `features/settings/appearance_screen.dart`: system/light/dark/Just Black, dynamic/accent color, original Tink art, rounded licensed fonts, finite reduced-motion-safe effects | Exact proprietary font/timing unavailable; no blanket accessibility or pixel-parity claim |
| Languages / regional | `l10n/`, `features/settings/regional_screen.dart`: 36 starter core locales, RTL, date/week/financial-month/number/currency options | Detailed forms/help are predominantly English. Do not call this 36 completely translated apps or copy unlicensed upstream ARBs |
| Backup / transfer / CSV import | `core/services/backup_service.dart`, `csv_service.dart`, settings backup/import pages: local JSON/ZIP, validation/checksum, all profiles/receipts, guided CSV mapping/preview/deduplication | No automatic Google Drive/iCloud account integration. Users can choose an OS storage/share provider. Restores disable automation/notifications for review |
| Widgets | Android native `BalanceWidget`, `BudgetWidget`, `QuickAddWidget`; iOS WidgetKit target; masked values under lock/privacy | Tink public labels and launch scheme; native component/App Group IDs kept stable. Physical launcher, App Group/signing and OS behavior still require verification |
| Automation | `core/services/deep_link_service.dart`, platform URI registration, Help: canonical `tink://quick_add`, `add`, `silent_add`; legacy `paisa://` accepted, amount/type/account/category/date/notes validation | `description` is a notes alias. Default confirmation/unlock and explicit opt-in silent mode remain. No claim to own `paisa-tracker.app` or its universal links |
| Notifications / security | Local notification service/settings; app-wide PIN/biometric lock, recovery limits, multiple isolated profiles | No backend/account/tracking. Data/backups are unencrypted; PIN is not database encryption. Platform permission/delivery needs device QA |
| Tink additions | Achievements, local Pro simulation, transparent Spending Health review, manual splits/assets, signed goal/loan/FX invariants | Preserve these rather than replacing the app with a smaller reference demo. No real purchases, health/credit verdicts or server AI |

## Changes driven by this review

1. Added **filtered and selected CSV/PDF export choices** to Activity/Search. Both use a captured full selection, so pagination or a later filter change cannot silently truncate an export. The chooser discloses private full amounts and unencrypted files. Search now initializes its text controller from an incoming query filter.
2. Added the public automation guide's **`description` alias**, with existing `notes` taking precedence, and canonical **`tink://`** launch links while preserving old `paisa://` compatibility. Android/iOS registration and widget sources use Tink without changing existing component IDs. The Android widget-picker labels are corrected to Tink.
3. Made a no-income PDF savings rate **unavailable**, not a fabricated zero percent. A filtered PDF states its exact selected-record scope and includes its complete transaction table.
4. Completed the existing Batch 4 source/browser gates, including real chart holds and swipes, saved transaction name, **$2.50 native amount and notes**, context rename, accurate health values and unsaved recurring cancellation. Existing Batch 1–3 coverage is retained.

5. Keep explicit selections across later search changes and preserve the horizontal insight/habit page when vertical list recycling rebuilds it. Source/widget regressions cover both cases. Normal category/People/Places rows leave names their remaining width instead of dividing the row into equal flexible columns.

## Verification status

Authoritative revision **`4f018d40e9193e8cd916c90a5d0e6b0d3333b5ae`** passed [run 42203316290](https://github.com/Shitwitt/MoneyMate/actions/runs/42203316290), **SUCCESS**:

- Source `127843696973`: strict canonical SDK format, analyzer, complete Flutter suite, calendar/DST reruns and all **15 Python packaging/platform-contract tests**. Includes automation/export tests, the selected-record-after-search regression and recycled-carousel state. No local Flutter SDK result is implied.
- Browser `127844476713`: actual scoped PDF/CSV downloads, exact saved calculator record/name/**$2.50**/notes, real touch swipes and chart/calendar holds, context updates, health methods/projection and unsaved reminder cancellation. Existing journeys/setup/persistence/offline checks passed with zero external runtime requests and an empty browser/layout error collection. The held calendar's demo values reconciled with its scoped records: 4 records, $1.00 income, $115.44 expense and −$114.44 net.
- All **39 Batch 4** and **27 refreshed Batch 3** full-frame evidence gates passed. Their bounded copies were reviewed: 44 byte-identical to already opened copies and 22 new/changed copies reopened. [Frame hashes/provenance](REFERENCE_REVIEW_04.json), [scope, job IDs and limits](REFERENCE_BATCH_04.md). Bounded review is not full-resolution or pixel-perfect certification.
- The calendar test stays a physical pointer press through both the web semantics debounce and Flutter long-press deadline; it does not dispatch a synthetic long-press action, click through to the records view instead, or weaken the exact-value assertion.
- Native URI/widget contracts have static Python checks only. Native dispatch, Android installation, physical widgets/notifications/biometrics/camera and iOS compilation/device behavior are not certified by the source/browser run.

**No new APK/AAB/native compilation.** Release and direct-Gradle workflows remain opt-in until the user explicitly says **“make APK.”**
