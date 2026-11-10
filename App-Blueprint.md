# Money Manager — Android App Blueprint
### A feature-complete, offline-first Paisa-style expense manager
**Stack:** Flutter (Dart) · Material 3 / Material You · Drift (SQLite) · Riverpod · go_router · fl_chart
**Target:** Android 8.0+ (minSdk 26) → Play Store-ready **APK + AAB**, built by GitHub Actions
**Data:** 100% local (no server, no login) + manual JSON backup/restore + CSV/PDF export
**Currency:** multi-currency with base currency + FX rates (default INR ₹, switchable)

---

## 1. Product thesis

> Open the app → in under 3 seconds you should know *how much money you have* and *how much you can still spend*. Adding an expense must take under 5 seconds with one thumb.

Three pillars, in priority order:

1. **Speed of entry** — big numeric keypad, smart defaults (last account/category), templates, quick-add widget, deep links.
2. **Trust** — everything on-device, no ads, no accounts. Backup is explicit, not hidden behind a paywall.
3. **Clarity** — budgets and balance are the first thing on screen; charts support decisions, never decoration.

**Non-goals for v1:** bank sync/aggregators (Plaid-style), cloud accounts, social features, ads, iOS.

---

## 2. Competitive teardown — what "just like Paisa" actually contains

From paisa-tracker.app, its FAQ hub and the Play Store listing, the reference app ships these modules. All of them are in scope.

| # | Module | Reference behaviour | Our v1 |
|---|--------|--------------------|--------|
| 1 | **Home dashboard** | Balance card + trend graph + draggable summary cards (balance, budgets, goals, loans, subscriptions, analytics) | ✅ card grid, long-press drag reorder, show/hide cards |
| 2 | **Accounts** | Bank / cash / credit card / wallet, reorder, default account, merge, per-account monthly in/out | ✅ + per-account currency + archived accounts |
| 3 | **Transactions** | Expense / income / transfer, name, amount, date-time, account, category, note, labels, people, places, receipts | ✅ + attachments (photo), split into multiple categories |
| 4 | **Categories** | Unlimited, custom icon + colour, expense/income typed, reorder | ✅ + archive, "Uncategorised" fallback that never deletes data |
| 5 | **Budgets** | Per category/group, daily-weekly-monthly-yearly, rollover, notifications | ✅ + progress rings, safe-to-spend/day |
| 6 | **Subscriptions** | Recurring charges, cycle, monthly-cost total, pre-renewal reminder | ✅ + pause/cancel flag, price-change flag |
| 7 | **Recurring transactions** | Auto-post EMI/rent/salary on schedule | ✅ + catch-up on missed occurrences |
| 8 | **Goals** | Target amount + deadline + contributions + progress bar | ✅ + "required/month" hint |
| 9 | **Simple Loans** | Lend/borrow, due date, partial payments, outstanding dashboard | ✅ + reminders |
| 10 | **Bill splitter** | Participants, equal / % / custom split, who-owes-whom, settle | ✅ + link to People |
| 11 | **Labels** | Free-form tags on transactions, filter + analyse | ✅ |
| 12 | **People** | Link transactions to a person, money flow per person | ✅ |
| 13 | **Places** | Location tag per transaction, spend by place | ✅ + optional GPS capture |
| 14 | **Assets** | Investments, stocks, property, gold; update values; net worth | ✅ net-worth = assets + account balances − liabilities |
| 15 | **Reports & Analytics** | Trends, category breakdown, income vs expense, custom ranges, filters, PDF/CSV export | ✅ |
| 16 | **Search & filters** | Amount, date, category, account, label, person, place, type | ✅ + saved filters |
| 17 | **Templates** | Pre-filled frequent transactions, one-tap add | ✅ |
| 18 | **Home-screen widgets** | Total balance, budget progress, quick-add | ✅ Glance-style Flutter widget (balance + budgets + quick add) |
| 19 | **Automation / deep links** | `paisa://add?...` from Tasker/Siri Shortcuts | ✅ `moneymanager://add?amount=..&category=..` |
| 20 | **Notifications** | Budget alerts, loan due, subscription renewal, recurring posted — all local | ✅ local notifications only |
| 21 | **Customisation** | Material You dynamic colour, light/dark/AMOLED, accent colours, icon packs | ✅ + number format, week start, month-start day |
| 22 | **Localisation** | 35+ languages | ✅ 6 shipped (en, hi, es, fr, de, pt) + ARB scaffold for the rest |
| 23 | **Backup / restore** | Device file + Google Drive/iCloud, full history | ✅ JSON backup via SAF, auto-backup folder, CSV import/export, PDF |
| 24 | **Security** | Biometric / PIN app lock | ✅ biometric + PIN fallback, screenshot blocking toggle |
| 25 | **CSV import** | Guided column mapping with review step | ✅ |
| 26 | **Onboarding** | Currency → first account → starter categories | ✅ 4-step, skippable |
| 27 | **SMS auto-capture** | *(Android-only, our differentiator)* Parse bank SMS into draft transactions with notification quick-categorise | ⚠️ v1.1, behind a feature flag (see §9) |

---

## 3. Screen map (route tree)

```
/                            → app shell
├── /onboarding              (currency, base account, categories, theme)
├── /lock                    (biometric / PIN gate)
├── /home                    ★ dashboard
├── /transactions            list + search + filters + export
│   ├── /transactions/new    quick entry sheet (amount keypad first)
│   └── /transactions/:id    detail / edit / delete / duplicate
├── /analytics               trends, donut, comparison, net worth
├── /budgets
│   └── /budgets/:id
├── /goals
│   └── /goals/:id
├── /subscriptions
├── /recurring
├── /loans
├── /splitter                bill split wizard + settlements
├── /accounts
│   └── /accounts/:id        ledger of that account
├── /assets
├── /more                    hub: labels, people, places, categories, templates
├── /settings                appearance, behaviour, security, backup, about
└── /settings/backup · /settings/import · /settings/export · /settings/about
```

**Bottom navigation (5):** Home · Transactions · Analytics · Budgets · More
**FAB:** persistent "＋" on Home/Transactions → opens `QuickEntrySheet` (modal bottom sheet, not a full page).
**Deep links:** `moneymanager://add`, `.../home`, `.../budget/:id`.

---

## 4. UI / design system

### 4.1 Material 3 foundations
- **Colour:** `ColorScheme.fromSeed` seeded from user accent (default a deep teal `#00696D`); `dynamic_color` package on Android 12+ so the app follows the wallpaper. Dark + AMOLED black variant (surface `#000`).
- **Typography:** Roboto (default) with a "Display" scale for money figures — amounts use **tabular figures** (`fontFeatures: [FontFeature.tabularFigures()]`) so digits don't jitter when animating.
- **Shape:** M3 tokens — cards 16/20 r, sheets 28/0, buttons pill. Chips for filters, `SegmentedButton` for expense/income/transfer.
- **Elevation:** tonal surfaces, not shadows. Nested cards use `surfaceContainerHigh` / `surfaceContainerLowest`.
- **Density:** 4-pt grid, 16 dp screen gutters, 12 dp card padding, 8 dp inner gaps. Min touch target 48 dp.
- **Edge-to-edge:** `SystemUiOverlayStyle` transparent, content padded by `MediaQuery.viewPadding`.

### 4.2 Signature components (build these once, reuse everywhere)
| Component | Used on | Notes |
|---|---|---|
| `BalanceCard` | Home | Big total + month income/expense pills, animated number |
| `AccountCard` | Home, Accounts | Icon, name, balance, per-month in/out, credit-card shows "due" |
| `AmountText` | everywhere | Currency-aware, coloured: expense = error tone, income = tertiary/green |
| `CategoryChip` / `CategoryPicker` | entry | Icon in coloured circle + label, horizontally scrollable, "recent" first |
| `TransactionTile` | lists | Leading avatar, title, sub-line (category · account), trailing amount, date group header ("Today", "Yesterday", "12 Oct") |
| `BudgetRing` | Budgets, Home | Circular progress with limit + spent + remaining |
| `TrendBarChart` | Home, Analytics | Paired income/expense bars, tap → tooltip, swipe → change period |
| `CategoryDonut` | Analytics | Donut + legend list with % and amounts |
| `PeriodSelector` | Analytics, Transactions | Segmented: Day / Week / Month / Year / Custom |
| `EmptyState` | all lists | Icon + one-line explanation + primary action |
| `NumericKeypad` | entry | 3×4 grid, `,`/`.` aware, backspace, "=" evaluates + − × ÷ |
| `FilterSheet` | lists | Multi-select categories/accounts/labels, amount range slider |
| `ConfirmSheet` | destructive | "Delete transaction?" destructive button + undo snackbar |
| `CardGrid` | Home | ReorderableGrid wrapper for dashboard cards |

### 4.3 Home screen layout (top → bottom)
1. App bar: month title (`October 2026 ▾`) — tapping opens month picker; trailing icons: search, lock quick-action.
2. `BalanceCard` — total net across accounts (hide toggle "eye"), income pill, expense pill, transfer pill.
3. **Dashboard cards grid** (2-column, drag to reorder, long-press menu → hide):
   - Trend graph (full width)
   - Budgets summary (top 3 rings)
   - Recent transactions (last 5, "See all")
   - Goals (top 2 progress bars)
   - Subscriptions (monthly total)
   - Loans (owed / owing)
   - Accounts carousel
4. FAB.

### 4.4 Interaction & motion rules
- **Entry:** FAB → sheet slides up 250 ms `easeOutCubic`; focus is *never* on a text field, the **keypad is live immediately**.
- **Saving:** optimistic insert + a 160 ms scale-in of the new tile, plus `Undo` snackbar for 4 s.
- **Deleting:** swipe-to-dismiss with `Dismissible` + undo, or long-press → menu.
- **Charts:** 200 ms tween on period change; no 3-D, no gradients behind data.
- **Haptics:** light impact on keypad tap and on save.
- **Accessibility:** every icon-only button has a `tooltip`/semantic label; money read as "₹1,240 rupees spent on Food"; text scales to 200 % without clipping (use `Wrap`/`Flexible`).
- **Reduced motion:** respect `MediaQuery.disableAnimations`.

### 4.5 The 5-second entry flow (the most important screen)
```
[Sheet opens]
① SEGMENTED: Expense | Income | Transfer     (default = Expense)
② BIG AMOUNT DISPLAY                          ₹ 0
③ Category strip (recent + favourites)        🍔 Food  🚕 Transport  🛒 Groceries …
④ Collapsed "details" row: [account ▾] [date ▾] [note] [label ＋]
⑤ Numeric keypad, with "=" calculator and "Next/Save" pill
→ Save, sheet closes, undo snackbar
```
Validation: amount > 0; if transfer, from ≠ to; if no account, prompt to create one (never block with a dead-end).

---

## 5. Data model (Drift / SQLite)

Amounts are **integers in minor units** (paise/cents) — never `double`. All tables carry `createdAt`, `updatedAt`, `deletedAt` (soft delete) for sync-safe undo and restores.

```
accounts(id, name, type[cash|bank|creditCard|wallet|investment], currencyCode,
         openingBalance, iconKey, colourArgb, isDefault, isArchived, sortIndex)

categories(id, name, type[expense|income], iconKey, colourArgb, parentId?,
           isArchived, sortIndex)

transactions(id, type[expense|income|transfer], amount, currencyCode, date, note,
             accountId, transferAccountId?, categoryId?, feeAmount?,
             placeId?, personId?, isReconciled, createdAt, updatedAt, deletedAt)

transaction_labels(transactionId, labelId)      -- M:N
transaction_splits(id, transactionId, categoryId, amount)   -- part-splits
attachments(id, transactionId, path, mimeType, createdAt)

labels(id, name, colourArgb)
people(id, name, phone?, note?)
places(id, name, latitude?, longitude?)
templates(id, name, type, amount, accountId, categoryId, note, useCount)

budgets(id, name, periodType[daily|weekly|monthly|yearly], amount, rollover,
        startsOn, isArchived)
budget_categories(budgetId, categoryId)

subscriptions(id, name, amount, cycle[weekly|monthly|quarterly|yearly], nextDue,
              accountId, categoryId, isPaused, reminderDaysBefore)

recurring_rules(id, name, type, amount, accountId, categoryId, frequency,
                interval, nextRun, lastRun, endDate?, autoPost)

goals(id, name, targetAmount, deadline?, accountId?, iconKey, colourArgb, isArchived)
goal_contributions(id, goalId, amount, date, transactionId?)

loans(id, kind[lent|borrowed], personId, principal, date, dueDate?, note, isSettled)
loan_payments(id, loanId, amount, date, note)

assets(id, name, kind[stock|mutualFund|property|gold|crypto|other], currentValue,
       currencyCode, iconKey, note)
asset_valuations(id, assetId, value, date)

bills(id, title, totalAmount, payerPersonId?, splitMode, date)
bill_participants(id, billId, personId, shareAmount, isSettled)
settlements(id, fromPersonId, toPersonId, amount, date)

fx_rates(baseCode, quoteCode, rate, asOf)
settings(key, value)   -- theme, base currency, week start, month start day, lock…
```

**Derived (SQL views / Dart mappers):** `account_balance`, `monthly_totals`, `budget_actual`, `net_worth`, `person_balance`.

**Migrations:** `schemaVersion` + step-by-step `MigrationStrategy`; every release appends a migration and a schema JSON export for tests.

---

## 6. Architecture

```
lib/
├── main.dart
├── app/                # MaterialApp, router, shell, theme, localisation
│   ├── router.dart     # go_router + deep links
│   └── theme/          # colour schemes, typography, component themes, tokens
├── core/
│   ├── money.dart      # Money value object (int minor units + currency)
│   ├── currency.dart   # list of currencies, symbols, formatting
│   ├── period.dart     # Day/Week/Month/Year range maths, custom ranges
│   ├── result.dart, extensions.dart, formatters.dart
├── data/
│   ├── db/             # tables.dart, database.dart, daos/, migrations/
│   ├── repositories/   # one per aggregate; the ONLY place DAOs are touched
│   └── backup/         # json_backup.dart, csv_io.dart, pdf_report.dart
├── domain/
│   ├── models/         # freezed models exposed to UI
│   └── services/       # budget_calculator, net_worth, recurrence_engine,
│                       # split_calculator, insight_engine, fx_service
├── features/           # one folder per module
│   ├── home/  transactions/  analytics/  budgets/  goals/  subscriptions/
│   ├── recurring/  loans/  splitter/  accounts/  assets/  labels/  people/
│   ├── places/  categories/  templates/  settings/  backup/  onboarding/  lock/
│   └── <feature>/  ├─ presentation/ (screens + widgets)
│                   ├─ application/ (riverpod providers/controllers)
│                   └─ domain/ (feature-local models)
└── shared/widgets/     # AmountText, CategoryChip, EmptyState, NumericKeypad…
```

**Rules for the AI agent**
1. UI never touches Drift — always through a repository via a Riverpod provider.
2. Screens are `ConsumerWidget`s; all state in `Notifier`/`AsyncNotifier` classes.
3. One public widget per file, file name = widget name (snake_case).
4. No business logic in widgets — put maths in `domain/services` with unit tests.
5. `flutter analyze` must be clean and `flutter test` green before a phase is "done".
6. No `print`; use `logging`/`dart:developer`. No `dynamic` in public APIs.

---

## 7. Build sequence (12 phases, each independently shippable)

| Phase | Deliverable | Definition of done |
|---|---|---|
| **0** | Repo, Flutter project, lint, CI workflow, folder skeleton, theme tokens, `Money`/`Period` core | `flutter build apk --debug` succeeds in Actions; app shows themed "Hello" screen |
| **1** | Drift DB: all tables, DAOs, migrations, seed data, repository layer | Unit tests for every DAO; in-memory DB test passes |
| **2** | App shell: router, bottom nav, onboarding, settings stub, theme switcher | Navigate all 5 tabs; onboarding writes settings; dynamic colour works |
| **3** | Accounts + Categories CRUD | Create/edit/archive/reorder; balance maths correct; no data loss on category delete |
| **4** | Transactions CRUD + QuickEntrySheet + detailed list + search/filters | Add expense/income/transfer in ≤5 s; filters combine; undo works |
| **5** | Home dashboard with reorderable cards + trend chart + balance | Cards persist order; totals match repository truth |
| **6** | Budgets (rollover, rings, alerts) + Insights engine (safe-to-spend) | Budget maths unit-tested incl. rollover edge cases |
| **7** | Recurring engine + Subscriptions + Templates | Missed occurrences post once, idempotent; reminders fire |
| **8** | Goals, Assets, Loans, Bill splitter, Labels, People, Places | Each CRUD + its own report slice; split maths tested |
| **9** | Analytics + Reports: donut, comparison, net worth, CSV/PDF export | Exported PDF opens; numbers reconcile with dashboard |
| **10** | Backup/restore (JSON), CSV import wizard, auto-backup, biometric lock, widgets, deep links, notifications | Restore on a clean install reproduces the exact ledger |
| **11** | Hardening: a11y pass, 200 % text, empty/error states, performance, `flutter analyze`, integration tests | Startup < 2 s cold, list scrolls at 60 fps on a mid-range device |
| **12** | Release: signing, versioning, ProGuard, split ABI, GitHub Release with APK + AAB, Play Store listing assets | Tagged `v1.0.0` produces a signed APK artifact + AAB |

Feature flags in `settings.dart` keep `sms_import` and `ai_summary` off for the first release.

---

## 8. Extras the agent should add (cheap, high value)
- **Safe-to-spend/day** on Home: `(budget remaining − committed recurring) / days left`.
- **Insight cards**: "Food is 32 % above your 3-month average", "3 subscriptions renew this week".
- **Month-close summary** notification + a shareable image card of the month.
- **Undo everywhere** (snackbar), soft delete in DB.
- **Recurring catch-up**: if the app wasn't opened, post every missed occurrence once on launch.
- **Quick-add widget** and **balance widget**.
- **Duplicate detection** when a manual entry matches an SMS/import within 2 days and the same amount.

## 9. Android specifics
- `minSdk 26`, `targetSdk 35`, `compileSdk 35`, Java 17, Kotlin 2.x, `flutter.minSdkVersion` overridden in `android/app/build.gradle.kts`.
- Permissions: `POST_NOTIFICATIONS` (13+), `USE_BIOMETRIC`, `SCHEDULE_EXACT_ALARM` (optional), `READ_SMS`+`RECEIVE_SMS` only in the `sms` feature flavour, `CAMERA` for receipts.
- **Zero `INTERNET` permission in v1** — it's a selling point; keep it out of the manifest and state it in the store listing. (Add it only when you later ship cloud sync/BYOK AI.)
- `applicationId` e.g. `com.yourname.moneymanager`; `versionCode`/`versionName` from `pubspec.yaml` via `flutter build --build-number`.
- No obfuscation of the DB layer names needed, but enable `--obfuscate --split-debug-info` and `--split-per-abi` for release APKs.

## 10. Release checklist
1. `flutter test` + `flutter analyze` clean, CI green on `main`.
2. Version bump in `pubspec.yaml` + CHANGELOG entry.
3. Tag `v1.0.0` → Actions builds signed APK (`arm64-v8a` + universal) and AAB.
4. Install the arm64 APK on a real device; run through the smoke script in `Prompt-Pack.md` (Phase 12).
5. Privacy policy page (offline, no data collected), store listing: 512×512 icon, feature graphic 1024×500, 4–8 phone screenshots, short + full description, data-safety form ("No data collected").
6. Play Console: internal testing → closed testing → production. Keep the "no internet permission" claim accurate.

## 11. Risks & how the prompts mitigate them
| Risk | Mitigation baked into the prompt pack |
|---|---|
| AI agent generates a beautiful UI with broken maths | Money as integer minor units; unit tests required each phase |
| Data loss on schema change | Drift migrations + mandatory backup export before migration in debug |
| Scope creep → never ships | Phases are gated: each must build + pass tests before the next |
| Widget/sheet rebuild storms | Riverpod selectors, `const` constructors, list `itemBuilder` only |
| Agent silently breaks accessibility | Explicit a11y acceptance criteria in Phase 11 |
| APK signing secrets leak | Keystore from GitHub Secrets only, never committed |
