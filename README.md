# MoneyMate

An offline-first, Material You spending tracker — a 1:1 feature port of the
Play Store app `dev.hemanths.paisa` (Spending Tracker – Paisa).

No accounts, no cloud, no internet permission. Everything lives in Hive on the
device and can be exported / restored as a JSON backup.

## Build order (6 steps)

| Step | Scope | Status |
| ---- | ----- | ------ |
| 1 | Architecture, Material 3 theme engine, offline Hive database | ✅ done |
| 2 | Currency engine, financial state provider, onboarding intro flow | ✅ done |
| 3 | App shell, home dashboard, search & transaction engine | ✅ done |
| 4 | Accounts carousel, loans/EMIs, categories & budgets | ✅ done |
| 5 | Analytics & charts, history filters, exports | ✅ done |
| 6 | Final polish pass, packaging & release tooling | ✅ done |

## What steps 1–6 deliver

```
lib/
├── main.dart                          # Hive boot → provider → onboarding/shell switch
├── core/
│   ├── constants/
│   │   ├── avatars.dart               # 12 built-in profile avatars
│   │   ├── currencies.dart            # 40+ currencies, INR pinned, grouping metadata
│   │   └── icons.dart                 # tree-shake-safe icon registry
│   ├── enum/filter_enums.dart         # TransactionType, AccountType, DebtType,
│   │                                  # FilterExpense, AnalyticsRange, AnalyticsTypeFilter
│   ├── l10n/app_strings.dart          # en / hi / de / es / fr + TranslationScope
│   ├── theme/                         # Material You engine (step 1)
│   └── utils/
│       ├── app_lock.dart              # local_auth biometric / PIN prompt
│       ├── backup_service.dart        # real file I/O: share JSON/CSV, pick backup
│       ├── currency_formatter.dart    # ₹1,25,450.00, ₹1.5L, parsing, masking
│       └── id_generator.dart
├── data/
│   ├── local/hive_storage.dart        # 6 boxes, CRUD, seeding, backup/restore
│   └── models/                        # 5 persisted models + settings + budget stat
│                                      # + analytics snapshot & chart point models
├── domain/default_data.dart           # seeded Indian categories & accounts
├── providers/paisa_provider.dart      # the financial engine (see below)
├── screens/
│   ├── main_shell.dart                # 5-tab shell + container-transform FAB
│   ├── home/home_screen.dart          # balance hero, period chips, grouped ledger
│   ├── search/search_screen.dart      # real-time search + filter chips
│   ├── transactions/                  # add/edit form + calculator sheet
│   ├── accounts/                      # carousel + account editor
│   ├── debts/                         # loans/EMIs + record editor
│   ├── budgets/                       # overview, category cards, category editor
│   ├── overview/                      # analytics & reports (4 live charts)
│   ├── settings/                      # profile, appearance, currency, security, data
│   └── onboarding/                    # 5-step intro flow
│       ├── onboarding_screen.dart     # orchestration + single Hive write at the end
│       ├── onboarding_state.dart      # in-memory draft, presets, 12 categories
│       ├── pages/                     # welcome, profile, accounts, categories, currency
│       └── widgets/                   # lava lamp backdrop, shared scaffold
└── widgets/
    ├── analytics_charts.dart          # line / donut / bar / stacked-bar charts
    ├── app_lock_gate.dart             # launch & resume lock screen
    ├── avatar_view.dart               # photo-or-tile avatar with on-disk fallback
    ├── transaction_tile.dart          # 48×48 squircle row + day headers
    ├── period_summary.dart            # hero balance card, animated counter, chips
    └── error_view.dart
```

### Step 3 — the daily driver

* **Shell** — avatar + `Welcome back, [name]` + search + profile actions in the
  app bar, a five-destination `NavigationBar` (Home / Accounts / Overview /
  Debts / Budgets) and a `OpenContainer` FAB that morphs the button into
  `AddTransactionScreen` (`animations: ^2.0.11`).
* **Hero card** — 28dp radius, `primaryContainer` gradient, 34sp balance with
  `AnimatedAmount` (no 0 → total flash on first build) and two tonal sub-cards:
  down-left green income and up-right red expense, each with its row count.
* **Period chips** — `Daily / Weekly / Monthly / Yearly / All` `ChoiceChip`s drive
  both the hero and the ledger through `provider.setSelectedTimeFilter`.
* **Grouped ledger** — `Today` / `Yesterday` / `07 Nov 2026` headers with the net
  daily total (`+₹X` / `-₹Y`, transfers excluded), then rows of 48×48 squircles
  tinted `category.color` at 18% opacity, `Category • Account • 07:30 PM`, and a
  right-aligned `-₹500` red / `+₹2,000` green / `⇄ ₹1,000` blue amount.
* **Swipe to delete** — `Dismissible.confirmDismiss` returns `false` so the row
  springs back while the parent deletes and shows a 5-second **Undo** snack bar
  that re-adds the exact same record.
* **Add / edit form** — `SegmentedButton<TransactionType>`, a tappable amount
  that opens the built-in `+ − × ÷` calculator sheet (`ExpressionCalculator`
  honours precedence, tolerates trailing operators and returns `null` on
  division by zero), account pills (one row for expense/income, two rows for a
  transfer with the source disabled as "In use"), the category wrap grid with a
  `+ Add Category` chip (hidden for transfers), side-by-side date/time tonal
  pickers, an `_ImpactPreview` of the resulting account balance, a full-width
  bottom pill **Save**, and delete in edit mode.
* **Search** — live filtering over title, notes, category name and amount, with
  type / account / category filter chips that compose, and a result count.

| Performance note | Implementation |
| --- | --- |
| No rebuild storms | `context.watch` only where values are drawn; helpers stay `const` |
| No 0 → total flash | `AnimatedAmount` seeds its `Tween` with the first value |
| No layout jank | fixed-height cards, `FittedBox` on money, `IndexedStack` tabs |
| No double counting | linked debt rows are excluded from summaries and the ledger list |

### Step 4 — accounts, loans and budgets

* **Accounts carousel** — `PageView(viewportFraction: 0.9)` of 220dp, 28dp-radius
  Material cards built by `AccountCardView` (`lib/widgets/account_card.dart`):
  contactless chip glyph, `CASH`/`BANK`/`CARD` badge, `•••• •••• •••• 4821`,
  holder, bank, network mark and the **live** balance (`FittedBox` so ₹1,25,450
  never wraps). Animated page dots sit underneath; the focused card drives two
  tonal summary cards (account income / account expense with credit & debit
  counts), opening-balance and transfer-in/out stats, quick actions and the
  account's full statement — income, expense, transfers in **and** out, with a
  `+`/`−` direction glyph and swipe-to-delete.
* **Account editor** — `add_account_screen.dart`: type tiles, bank/wallet/card
  name, holder, last-4 (digits only), opening balance, twelve gradient card
  themes, "use as default" and a destructive delete that explains exactly what
  goes with the account. The card at the top is a live preview of all of it.
* **Loans & EMIs** — `debts_screen.dart` hosts a two-tab bar (`Debts` = money
  lent, `Credits` = money borrowed) over one shared card: person/bank, notes,
  start & due chips that turn red when overdue, `DUE SOON`/`OVERDUE`/`SETTLED`
  badges, total / paid / remaining, an animated 10dp rounded payoff bar
  (`65% paid`) and an expandable installment history (`Date • Amount • Account
  used`) with per-row delete. **`+ Add payment` / `Pay EMI`** opens a sheet that
  pre-fills the outstanding balance, offers 25/50/75/100% shortcuts, an account
  picker, a date and a note; saving writes the installment *and* the matching
  income/expense transaction, so the bar and the balance move together.
* **Categories & budgets** — `categories_budget_screen.dart`: a monthly overview
  card (spent vs total budget, remaining, `₹X / day` safe spend, over-budget
  count) over per-category cards showing the icon, name, spend and transaction
  count, a progress bar that is **primary (<75%) → amber (75–99%) → error
  (≥100%)**, a percentage badge and an `Exceeded by ₹X` tag. Tapping the chevron
  opens the month's transactions for that category with per-row delete.
* **Category editor** — `add_category_screen.dart`: name, description, a 36-icon
  picker grid, a twelve-colour palette, a `Set Monthly Budget` `SwitchListTile`
  with an animated amount field, and delete.

### Step 5 — analytics & reports, settings, backup

**Overview tab — four fully dynamic charts.** `overview_screen.dart` is now the
analytics screen. A sticky filter bar pins the title, the live scope line
(`01 Nov – 30 Nov · 5 records`), the four time chips (`This Week / This Month /
This Year / All Time`) and a custom three-way segment (`All / Expense Only /
Income Only`, sliding tonal pill, full labels). Both filters persist in the
settings box, so the tab reopens the way it was left.

Every point on the screen comes from `PaisaProvider.analyticsSnapshot()`, which
buckets the real ledger for the selected window and type:

| Chart | Widget | Data |
| --- | --- | --- |
| Net cashflow & savings rate | `_NetCashflowCard` | net, savings rate, average daily spend, highest spending day, `AnimatedAmount` + privacy toggle |
| 1. Income vs expense | `IncomeExpenseLineChart` | curved `LineChart` (`isCurved`, `preventCurveOverShooting`), gradient area fill, dotted grid, per-bucket tooltips with the weekday date and formatted amounts |
| 2. Category donut | `CategoryDonut` + `_CategoryLeaderboard` | `PieChart` of real categories/colours; a tap grows the slice `58 → 70` and swaps the centre hole to the category name + share; ranked leaderboard (icon, name, txn count, amount, %, mini bar) |
| 3. Monthly comparison | `MonthlyFlowBarChart` | grouped `BarChart` of the last 6 (or 12) months, gradient rods, dimming on touch, month tooltip |
| 4. Account distribution | `AccountDistributionBar` + `AccountTypeCaption` | one stacked 100% bar per account, ranked breakdown with mini bars, `Cash / Bank / Cards` percentage chips |

Bucketing rules (all in the provider, unit-tested):

* day buckets for week/month windows, month buckets for year/all-time;
* transfers never count as income or expense; linked loan-installment mirrors are
  excluded so a repayment is reported once;
* the window is clamped to today so an unfinished week never plots empty future
  days or drags the daily average down;
* the donut distributes outflow (or income, in `Income Only` mode) and folds
  orphaned categories into a synthetic `Uncategorised` slice.

**Settings — profile, appearance, money, security, data.** `settings_screen.dart`
is rebuilt around five groups:

* **Profile** — gradient card with avatar (tap to pick a real image, or choose one
  of the twelve built-in tiles), inline name editing and live record / account /
  category / loan counts.
* **Appearance** — four theme cards (`System / Light / Dark / AMOLED`), an AMOLED
  pitch-black switch, a Material You switch and an accent-colour modal with the
  twelve seeds (enabled only when Material You is off).
* **Currency & language** — a searchable currency sheet with symbol, code and a
  live `sampleAmount` preview; changing it reformats the entire app instantly.
* **Security** — `App lock` via `local_auth`: enabling asks the device to confirm
  first, and `AppLockGate` (wrapped around `MaterialApp.home`) re-locks on launch
  and on every resume. Device PIN/pattern works as the fallback, and a platform
  with no screen lock stays open with an explanation rather than locking the
  owner out.
* **Data & backup** —
  * **Export full backup** → `BackupService.shareBackup()` writes
    `paisa_backup_YYYYMMDD.json` (accounts, categories, transactions, debts,
    installments, settings) into the app sandbox and hands it to the platform
    share sheet; the timestamp is stored as `lastBackupAt`.
  * **Restore** → confirmation → `file_picker` → `restoreBackupJson()`, which
    re-validates every record through its model and reports how many came back;
    a foreign or damaged file throws `FormatException` **before** anything is
    wiped.
  * **CSV export** → `paisa_transactions_YYYYMMDD.csv` with the exact header
    `Date,Title,Type,Category,Account,Amount,Notes`, RFC-4180 escaping, plain
    decimal amounts and `HDFC Savings → Cash in Hand` for transfers.
  * **Clear all data** → destructive confirmation that states the record count,
    then `resetEverything()`.

### Durability & correctness notes (step 5)

* **No future leakage.** The analysed window is clamped to today, so a recurring
  entry scheduled for next week cannot make this month's daily average or line
  chart lie. `daysElapsedInPeriod()` is clamped the same way.
* **No silent data loss.** A record whose category was deleted (an old backup, a
  hand-edited file) is folded into a synthetic `Uncategorised` slice, so the
  donut's shares still sum to 100% and the account bar still adds up.
* **Restore is transactional-ish.** Every incoming record is re-validated through
  its model *before* any box is written, and a file that is not a MoneyMate
  backup throws `FormatException` without touching the current ledger.
* **CSV is spreadsheet-safe.** Fields containing `,` `"` or newlines are quoted,
  inner quotes are doubled, and amounts are plain decimals (`450.00`) with no
  currency symbol or grouping, so Excel/Sheets parse them as numbers.
* **The lock cannot lock you out.** `local_auth` runs with `biometricOnly: false`
  (device PIN/pattern is a valid fallback); if the platform has no screen lock at
  all, the app stays open and explains why.

### Step 6 — entry point, app lock, packaging

**One boot path.** `main()` opens the Hive boxes and reads the persisted
settings *before* `runApp`, so the first frame already has real data and the
right palette — no splash spinner, no flash of the wrong theme on a cold start.
The tree is `MultiProvider` → `PaisaThemeBuilder` → `MaterialApp` →
`TranslationScope` → `BiometricGate` → onboarding or shell:

* `Provider<HiveStorage>.value` exposes the already-open database;
  `ChangeNotifierProvider<PaisaProvider>` builds the financial engine around it.
* `PaisaThemeBuilder` (from step 1) is reused rather than re-implemented, so
  the `DynamicColorBuilder` subscription only happens on Android — the one
  platform where Material You can actually answer. Resolving the theme in
  `main.dart` as well would have meant two places to keep in sync.
* `TranslationScope` wraps the `MaterialApp`'s child at the top, so every
  screen — including dialogs pushed later — translates live when the language
  changes.
* Orientation is locked to portrait before the first frame: the layouts are
  built as a single narrow column of money and the charts re-bucket rather than
  rotate.

**Onboarding → shell without a rebuild race.** `_EntryPoint` returns a
`KeyedSubtree` keyed on `onboardingComplete`. The moment the last onboarding
page writes its single Hive transaction, the key changes and `MainShell` is
built fresh, seeded from the freshly written boxes instead of the empty
pre-onboarding ones.

**App lock that cannot lock you out.** `BiometricGate` wraps `AppLockGate`:

* Lock is **off by default**; nothing is prompted until the user turns it on in
  Settings, and turning it on is only allowed after the device has actually
  authenticated once.
* Unlock goes through `local_auth` with `biometricOnly: false`, so PIN, pattern,
  password, fingerprint *and* face all count. A phone with biometrics enrolled
  but a broken sensor still opens with its PIN.
* The lock re-engages when the app returns from the background, but only if it
  had been unlocked in that session — a user is never asked twice while
  switching apps to copy an amount.
* If the platform reports no screen lock at all, the gate **fails open**: the
  ledger renders and a floating snack bar explains that MoneyMate stayed
  unlocked because the device can't authenticate. Refusing entry would hold the
  owner's own ledger hostage over a device setting they may not be able to
  change. A *cancelled* prompt is different — that is the user's own "no", so
  the lock stays up with an "Unlock" button and a message.

**Packaging.** `.github/workflows/build-apk.yml` builds a universal release APK
on every push to `main`/`master` or a working `arena/*` branch, on pull requests
(artifact only), and on demand. JDK 17 + Flutter stable, then `flutter create` generates the native
`android/` folder (the repo stores Dart only), `tool/android_hardening.py`
makes it `local_auth`-safe, `flutter build apk --release
--no-tree-shake-icons` produces `app-release.apk`, which is uploaded as the
`MoneyMate-APK` artifact and, on `main`/`master` pushes and manual runs,
attached to a `v1.0.<run number>` Release.

The job also deletes the template `test/widget_test.dart` that `flutter create`
writes (it pumps a `MyApp` class this project does not have, which would fail
`flutter analyze`), then runs `flutter test` before building.

`tool/android_hardening.py` is checked in and idempotent because the generator
gets `local_auth` wrong by default:

1. `MainActivity.kt` extends `FlutterActivity`. `local_auth` needs a
   `FragmentActivity` host — a plain activity throws `no_fragment_activity` the
   first time the prompt is shown — so the launcher is repointed to
   `FlutterFragmentActivity`.
2. `android.permission.USE_BIOMETRIC` is absent from the generated manifest, so
   it is inserted (once) before `<application>`.

It exits non-zero if the manifest or launcher is missing, so CI fails loudly
instead of shipping an APK whose app lock cannot prompt.

### The financial engine (`PaisaProvider`)

Every number the UI shows is derived, never stored:

| Formula | Implementation |
| --- | --- |
| `balance(id) = initial + income − expense − transferOut + transferIn` | `_computeBalances()` |
| `totalNetBalance = Σ balances` | `totalNetBalance` (+ `totalAssets`, `totalLiabilities`) |
| `periodIncome / periodExpense` | sum of that type inside the `FilterExpense` window |
| transfers | **never** counted as income or expense — surfaced separately as `periodTransferVolume` |
| budget | `spent / budget`, `remaining`, `remaining / daysLeftInMonth` per category |
| loan | `paid = Σ installments`, `remaining = amount − paid`, `progress = (paid / amount).clamp(0,1)` |
| analytics | `analyticsSnapshot()` buckets the window by day or month; `savingsRate = net / income`, `averageDailySpend = expense / elapsedDays` |
| CSV | `exportTransactionsCsv()` — quoted, decimal amounts, newest first |

**Installments move real money.** Recording an installment with an account
writes a linked ledger row: `DebtType.debt` (someone repaying you) → **income**;
`DebtType.credit` (you paying an EMI) → **expense**. The linked row carries a
`Debt installment` description prefix, is excluded from period summaries so a
repayment is never reported twice, and is deleted with its installment.
`repairDebtLedger()` heals installments saved without a mirror row.

### Onboarding

Five pages, one in-memory draft, **one Hive write at the very end** — backing
out leaves the database untouched.

1. **Welcome** — animated lava-lamp backdrop from the tonal palette, logo, three
   feature pills, and the language selector (English, हिन्दी, Deutsch, Español,
   Français) which translates the flow live.
2. **Profile** — `TextFormField` + 12 illustrated avatars + real photo picking
   (copied into the documents directory so it survives cache eviction).
3. **Preset accounts** — Cash / Bank / Card cards with an opening-balance dialog.
4. **Preset categories** — multi-select grid of twelve Indian categories with
   sensible default budgets.
5. **Currency** — searchable list of 40+ currencies with INR pinned and badged.

### Design decisions that keep CI green

* **No code generation.** Every model implements `toMap()` / `fromMap()` by hand
  and is stored as a plain `Map` in Hive — no `@HiveType`, no
  `build_runner`, no `.g.dart` files that can go missing.
* **Total deserialization.** `lib/data/models/map_utils.dart` coerces missing or
  mistyped values (`"1500"` → `1500.0`, `1` → `true`, unknown enum keys →
  defaults) so one corrupt row can never crash a list.
* **Tree-shake-safe icons.** Icons are persisted as `codePoint` ints but always
  resolved back through the `ICONS` registry of `IconData` constants, never
  constructed with `IconData(...)`.
* **Offline first font.** `PaisaTypography` wraps `GoogleFonts.outfitTextTheme`
  in a guard and falls back to the platform text theme on a cold offline start.

### Theme engine

* Dynamic Color (`DynamicColorBuilder`) on Android 12+, with an automatic
  fallback to the seed palette when the platform supplies nothing — or supplies
  a monochrome scheme.
* Twelve vibrant seeds: Teal, Green, Lime, Yellow, Orange, Deep Orange, Red,
  Pink, Purple, Deep Purple, Indigo, Blue.
* Four modes: `System`, `Light`, `Dark`, `AMOLED`. The AMOLED variant collapses
  `surface`, `surfaceContainerLowest`, `surfaceTint`, `shadow` and `scrim` to
  `#000000` while keeping 5–13% primary-tinted containers so cards stay visible.
* `Card`, `Dialog`, `BottomSheet` are `RoundedRectangleBorder(24)` with zero
  elevation and transparent shadow colours. Money semantics live in the
  `PaisaColors` `ThemeExtension` (`income`, `expense`, `transfer`, `debtGiven`,
  `debtTaken`, `warning`, `success`, `chartPalette`, …).

### Storage

Boxes: `accounts_box`, `categories_box`, `transactions_box`, `debts_box`,
`debt_transactions_box`, `settings_box`.

`HiveStorage` exposes synchronous reads (`getAccounts`, `getTransactions`,
`getAccountBalances`, `dateRangeForFilter`, `spendingByCategory`, …) and async
writes (`saveTransaction`, `deleteCategory`, `seedDefaults`,
`restoreBackupFromJson`, …). Balance maths is derived, never stored, so a
crashed write can't desync the ledger.

`seedDefaults()` is idempotent — it seeds 2 accounts, 14 Indian expense
categories and 2 income categories, skips anything that already exists, and
guarantees exactly one default account.

## Getting started

```bash
flutter pub get
# The repo ships Dart only; generate the native shell once (it is also what CI
# does), then harden it for local_auth:
flutter create . --platforms=android --org dev.hemanths.paisa --project-name moneymate
python3 tool/android_hardening.py
flutter run
```

Requires Flutter **3.27+** (stable) because the design system uses
`CardThemeData` / `DialogThemeData` and Material 3 surface containers.

Tests: `flutter test`

The `android/` folder is generated, not committed, so `flutter create` is
required before the first device build or `flutter run` — the workflow does the
same thing in CI.

| Suite | Covers |
| --- | --- |
| `hive_storage_test.dart` | seeding idempotency, CRUD, derived balances, filters, backup round-trip |
| `paisa_provider_test.dart` | the exact balance formula, transfers, period maths, budgets, installments, validation, onboarding |
| `currency_formatter_test.dart` | Indian grouping, compact `K/L/Cr`, 8 currencies, parsing, masking |
| `onboarding_test.dart` | the full five-page walk plus "nothing is written until the last tap" |
| `paisa_theme_test.dart` | 24dp tonal surfaces, zero elevation, 4 modes, 12 seeds |
| `expression_calculator_test.dart` | precedence, trailing operators, ÷0, rounding, prettify |
| `transaction_grouping_test.dart` | day bucketing, Today/Yesterday labels, ordering, day net |
| `search_filter_test.dart` | title / notes / amount / category matching, filter composition |
| `add_transaction_test.dart` | validation, expense save, transfer rules, edit mode |
| `step4_accounts_debts_budgets_test.dart` | card masking, 12 card themes, account totals, installments → income/expense + delete cascade, overdue, budget maths and the three editors |
| `step5_analytics_settings_test.dart` | snapshot buckets for all four ranges, type filters, savings rate / daily average / peak day, ranked slices, account split, 6-vs-12-month bars, filter persistence, backup round-trip, corrupt-file rejection, CSV header + row shape, currency switch, settings reload, and the Overview/Settings widgets (all four `fl_chart` types render and the chips recompute) |
