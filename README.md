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
| 3 | Transaction entry sheet, ledger & filters, charts | ⏳ |
| 4 | Accounts & categories management | ⏳ |
| 5 | Debts / loans / EMIs + installments | ⏳ |
| 6 | Settings, biometric lock, backup & restore, polish | ⏳ |

## What steps 1–2 deliver

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
│   ├── main_shell.dart                # post-onboarding shell (4 tabs)
│   └── onboarding/                    # 5-step intro flow
│       ├── onboarding_screen.dart     # orchestration + single Hive write at the end
│       ├── onboarding_state.dart      # in-memory draft, presets, 12 categories
│       ├── pages/                     # welcome, profile, accounts, categories, currency
│       └── widgets/                   # lava lamp backdrop, shared scaffold
└── widgets/
    ├── avatar_view.dart               # photo-or-tile avatar with on-disk fallback
    └── error_view.dart
```

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
