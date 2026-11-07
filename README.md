# MoneyMate

An offline-first, Material You spending tracker — a 1:1 feature port of the
Play Store app `dev.hemanths.paisa` (Spending Tracker – Paisa).

No accounts, no cloud, no internet permission. Everything lives in Hive on the
device and can be exported / restored as a JSON backup.

## Build order (6 steps)

| Step | Scope | Status |
| ---- | ----- | ------ |
| 1 | Architecture, Material 3 theme engine, offline Hive database | ✅ done |
| 2 | App shell, navigation, onboarding, home dashboard | ⏳ |
| 3 | Transaction entry sheet, ledger & filters, charts | ⏳ |
| 4 | Accounts & categories management | ⏳ |
| 5 | Debts / loans / EMIs + installments | ⏳ |
| 6 | Settings, biometric lock, backup & restore, polish | ⏳ |

## What step 1 delivers

```
lib/
├── main.dart                          # bootstrap + provider wiring + step-1 harness
├── core/
│   ├── constants/icons.dart           # tree-shake-safe icon registry (persisted codePoints)
│   ├── enum/filter_enums.dart         # TransactionType, AccountType, DebtType, FilterExpense
│   ├── theme/
│   │   ├── paisa_theme.dart           # Material You engine, 4 modes, component themes
│   │   ├── paisa_colors.dart          # money-semantic ThemeExtension (income/expense/…)
│   │   ├── paisa_typography.dart      # GoogleFonts.outfitTextTheme with offline fallback
│   │   ├── seed_color.dart            # 12 vibrant seeds
│   │   └── theme_preference.dart      # System / Light / Dark / AMOLED
│   └── utils/
│       ├── id_generator.dart          # UUID v4 ids
│       └── money_format.dart          # ₹ + Indian lakh/crore grouping
├── data/
│   ├── local/hive_storage.dart        # boxes, CRUD, balances, seeding, backup/restore
│   └── models/                        # 5 persisted models + settings + in-memory joins
├── domain/default_data.dart           # seeded Indian categories & accounts
└── features/settings/appearance/appearance_controller.dart
```

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

Tests: `flutter test` (data layer round-trips, balance maths, seeding
idempotency, theme contracts).
