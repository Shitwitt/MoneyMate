# Screenshot rebuild — batch 01 (20 supplied images)

Status: **batch 1 implemented and CI-verified** — SDK/analyzer/regressions, real-browser/offline flow, fresh native APK verification and direct Gradle debug build passed.
This is the **1.3.0+4** source and rebuilt APK, not the historical 1.2 binary. See [exact evidence and download integrity](BUILD_STATUS.md).

## Reference boundaries

- Setup 1/14; welcome 2; budgets 3; loans 4; goals 5; recurring 6;
  categories 7; languages 8; notifications 10.
- Recurring help (two captures), overview/due cards, calendar, active cards,
  detail hero, detail statistics/history.
- Home across four successive scroll positions.
- Pages 9 and 11–14 were **not supplied**. Appearance, privacy, currency,
  profile/account entry and final review are original working continuations,
  clearly not asserted to be exact reconstructions of unseen pages.
- Tink identity and original mark remain. No copied Paisa logo, phone OS bars,
  private chat-head photo, or proprietary wallpaper is bundled.
- Static pictures do not reveal animation timing. Motion is implemented as
  finite, reduced-motion-aware Flutter transitions rather than claimed observed timing.

## Implementation

- Coffee surfaces, peach pills, rounded bundled TinkRounded (Quicksand-derived) typography, original
  vector icons, tabular money, all existing offline multilingual fallbacks.
- Real feature screens in decorative phone previews (isolated in-memory data,
  not screenshot backgrounds); no phone status bar imitation.
- 12 tour steps + profile/account entry + review = 14. Language selector,
  local/provider file restore, isolated demo, notification permission, theme and currency choices work.
- 36 starter locales with matching message keys and bundled CJK/Thai fonts.
  Translated scope is navigation and primary actions, **not every finance form**.
  Arabic, Persian and Urdu are right-to-left. No runtime font fetch.
- Demo has an independent in-memory repository. Edits and settings cannot save
  to the real repository; exit or relaunch returns to real finances. Platform
  widgets, incoming finance links and notification synchronization do not apply demo records.
- Home: balance/comparisons, two-column feature cards, real-record charts,
  profile/settings/toolkit access, templates, real achievement earned notice,
  Home/Accounts/Reports/Search navigation. Existing custom navigation is supported.
- Recurring: estimates in reporting currency, active/due/archived filters,
  list/calendar modes, Monday-first month navigation, real recorded markers,
  pending projections, sorting, help, rule details, metadata, end dates,
  history and real statistics. Monthly and yearly figures are labeled projections.
- Processing and skipping are queued atomic operations checked against the
  displayed occurrence date. Double/stale taps cannot debit or skip another
  occurrence. Archive stops catch-up/reminders without deleting transactions.
- New optional budget/labels/people/place/reminder/archive fields read old JSON
  safely. Linked-budget expenses count in the matching budget period; deleting
  a budget or entity clears its links without deleting monetary history.
- Daily, weekly, fortnightly, monthly, quarterly, half-yearly, yearly and custom
  day intervals retain calendar-day/DST and month-end anchors.
- Budgets, goals, loans and category lists have real reference-style cards,
  totals, sorting/filters, wavy progress and existing working detail/edit actions.
  Goal archive is reversible; transfer categories can be created and used.

## Deliberate truthful differences

- Licensed bundled TinkRounded (Quicksand-derived) approximates the rounded typography; the exact screenshot font is unknown.

- The locked Google Drive item is replaced by **Restore a provider backup**.
  Both restore choices use the OS file picker. Tink neither signs into Google
  nor uploads to a server; external providers can appear only if supplied by
  the user's operating system. There is no fake Google integration/paywall.
- The screenshot's financial indicator is not a credit/health/AI score.
  Tink displays its existing transparent record-derived planning indicators,
  with unknown values left unavailable and an explicit limitation.
- The app-owned Exit Demo control uses a separate top strip rather than obscuring the Back/profile toolbar, and reference OS/status/private-chat overlays are not copied.
- No screenshot sample figure is substituted for the user's own ledger.
- Budget custom periods do not auto-renew; allocations and loan records are
  bookkeeping, never payments, bank feeds, issued cards, or real lending.
- Backups/data are unencrypted. PIN/biometrics protect app access, not the database.

## Verification executed

- Full existing finance, backup, security, lifecycle, large-money, chart and
  accessibility regression suite plus batch-specific demo/recurrence/calendar/
  locale/RTL tests.
- Strict non-mutating Dart format gate. On a mismatch, diagnostics format only
  a temporary copy; the check still fails. No CI source auto-rewrite.
- Browser: isolated demo edit/process/archive/exit, calendar/help/history,
  14-step setup, accounts/reports, theme persistence, offline reload and no
  external runtime requests, with fictional-data screenshots.
- A newly compiled 1.3 Android release-mode APK is published with native metadata and SHA-256; matching source is refreshed only after enforcing unchanged application files. Bounded transient-only retry and direct Gradle builds passed. Ordinary compile errors are not retried.
- Physical-device and iOS verification remain unproven unless reported separately.

### Evidence and limits

[Full SDK, browser and native run 42153449531](https://github.com/Shitwitt/MoneyMate/actions/runs/42153449531) passed on application revision `6dac3439c7614755f7997c847b6602577dd44d75`.
[Separate direct Gradle run 42153449674](https://github.com/Shitwitt/MoneyMate/actions/runs/42153449674) also passed.
Source publication enforces unchanged application/platform/asset/test/dependency files from that exact APK revision; only later README/docs/CI updates are allowed.

Coverage includes the complete populated Home feed at 100% and 160% text,
saved/reversed layouts, 320-pixel detail at 160% text in LTR and RTL,
atomic recurrence, deep demo exit with no real-repository writes,
calendar/history/help/process/skip/archive, all 14 setup steps,
theme persistence, offline reload and zero external runtime requests.
All 12 fictional-data browser captures are retained in the web artifact;
thumbnail evidence was reviewed for setup, tour, Home and recurring flows.

The final license audit renamed the locally instantiated Quicksand derivatives
to **TinkRounded**, retaining upstream copyright/OFL notices. Three new stdlib
regressions enforce primary-name compliance, weight registration and unchanged
glyph/metric/layout tables. All 10 Python packaging/retry/font tests passed.
The 12 final browser evidence thumbnails are byte-identical to the reviewed
pre-rename captures; letter shapes and layouts did not change.

Native launcher/widget and web-shell colors follow the warm palette.
Native widgets use system sans/rounded faces, not the Flutter TinkRounded asset.
WidgetKit extension metadata is 1.3.0 build 4; this is not iOS/device proof.
Native biometrics, notification timing, camera, widgets and installation still
need physical-device testing. No blanket accessibility certification is made.
