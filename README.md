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
| 4 | Accounts & categories management | ⏳ |
| 5 | Debts / loans / EMIs + installments | ⏳ |
| 6 | Settings hardening, biometric lock, backup & restore, polish | ⏳ |

## What steps 1–3 deliver

```
lib/
├── main.dart                          # Hive boot → provider → onboarding/shell switch
├── core/
│   ├── constants/
│   │   ├── avatars.dart               # 12 built-in profile avatars
│   │   ├── currencies.dart            # 40+ currencies, INR pinned, grouping metadata
│   │   └── icons.dart                 # tree-shake-safe icon registry
│   ├── enum/filter_enums.dart         # TransactionType, AccountType, DebtType, FilterExpense
│   ├── l10n/app_strings.dart          # en / hi / de / es / fr + TranslationScope
│   ├── theme/                         # Material You engine (step 1)
│   └── utils/
│       ├── currency_formatter.dart    # ₹1,25,450.00, ₹1.5L, parsing, masking
│       └── id_generator.dart
├── data/
│   ├── local/hive_storage.dart        # 6 boxes, CRUD, seeding, backup/restore
│   └── models/                        # 5 persisted models + settings + budget stat + joins
├── domain/default_data.dart           # seeded Indian categories & accounts
├── providers/paisa_provider.dart      # the financial engine (see below)
├── screens/
│   ├── main_shell.dart                # 5-tab shell + container-transform FAB
│   ├── home/home_screen.dart          # balance hero, period chips, grouped ledger
│   ├── search/search_screen.dart      # real-time search + filter chips
│   ├── transactions/                  # add/edit form + calculator sheet
│   ├── accounts/, overview/, debts/   # the remaining shell destinations
│   ├── budgets/, categories/          # budget editor, category manager
│   ├── settings/                      # profile, theme, currency & data settings
│   └── onboarding/                    # 5-step intro flow
│       ├── onboarding_screen.dart     # orchestration + single Hive write at the end
│       ├── onboarding_state.dart      # in-memory draft, presets, 12 categories
│       ├── pages/                     # welcome, profile, accounts, categories, currency
│       └── widgets/                   # lava lamp backdrop, shared scaffold
└── widgets/
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
flutter run
```

Requires Flutter **3.27+** (stable) because the design system uses
`CardThemeData` / `DialogThemeData` and Material 3 surface containers.

Tests: `flutter test`

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
