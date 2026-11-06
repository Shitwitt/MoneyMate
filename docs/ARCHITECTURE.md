# Architecture & financial invariants

## Storage and state

`LocalStore` implements `AppRepository`; Riverpod injects it into `AppController`. One validated versioned `AppData` JSON snapshot is stored as a Hive `String` value. Each snapshot contains separately owned `ProfileData` aggregates; only display/security preferences and the simulated Plus flag are global. No profile reads another profile's account IDs or transactions. A previous snapshot is retained for explicit startup recovery.

All write operations go through a serialized future queue. The transformation runs against the latest durable state inside that queue, validates every reference/invariant, saves and flushes, then publishes the new Riverpod state. A failed write leaves visible state unchanged; later queued operations still run. There is no optimistic balance mutation to reconcile. Hive's write is the snapshot's atomic boundary, not a pair of independent debit/credit calls. Very large snapshots trade write throughput for simple, inspectable transactions and portable backups; see README safety caps.

## Money

* Store integer minor units, not doubles. USD/INR have two, JPY/KRW zero, KWD/BHD/OMR three. Floating point is used only at formatting/exchange/expression boundaries and values are rounded once to the target currency's precision.
* An account owns its own currency and signed opening balance. Each expense subtracts; income adds. A transfer is ONE `MoneyTransaction` with outgoing amount/account and locked receiving amount/account. Balances are projections, never a second mutable cache. Editing/deleting a transfer necessarily affects both projections together.
* Transfers are excluded from income/expense analytics. Category types must match transaction types. Referenced accounts/categories/entities/goals/loans must exist before a snapshot can commit.
* Rates are user-maintained currency units per USD; USD is always 1. A missing/nonfinite/zero rate is an error, never silently replaced with 1. Historical native account values stay unchanged after rate edits, but converted reports use current reference rates. This is not historical FX accounting.
* Changing profile currency atomically rebases profile-denominated budgets, goals/events, loans/repayments, assets/history and bills. Account currencies/native transactions/locked transfers do not change. Largest-remainder redistribution preserves bill totals and bounded repayment totals. Converting to a coarser currency can round small historical allocations to zero; positive targets retain a minimum one minor unit.

## Net worth, debt and goals

`accounts + asset values + outstanding lent - outstanding borrowed`. Excluded accounts are omitted; archived accounts remain included unless explicitly excluded. Loan total is principal plus optional flat lifetime interest minus recorded repayments. New loan disbursement and repayments can optionally post matching account entries in the same snapshot. Tagging an ordinary transaction to a loan is metadata, not an implicit repayment.

Manual goal contributions are allocations and do not move account balances. Tagged income contributes to a manual goal; linked-account goals use the linked account's whole converted balance instead. Goals are not added to net worth, preventing double counting. Users must not manually allocate and tag the same money twice.

## Calendar and recurrence

Date windows use inclusive start and EXCLUSIVE end, so transactions at any time on an inclusive selected day are included. Financial starts on the 29th–31st clamp in shorter months. Weekly windows respect the first-day setting. Recurring monthly/yearly rules stay anchored to their original day rather than drifting after February. Local timezone is obtained from the OS for notification scheduling.

A recurring budget's rollover is the signed sum of each prior allowance minus spending from inception. Overspend is carried as debt, not dropped. Custom ranges are one-off and do not roll over. A recurrence occurrence ID is deterministic (`rule ID @ timestamp`); catch-up cannot duplicate an occurrence it has already posted. Catch-up happens on open/resume, up to 1,000 overdue entries per rule per pass; notifications cannot run financial writes while the app is closed. Deleting a posted recurring transaction removes that occurrence from history and does not rewind its rule's next date.

## Imports, exports, security

Full backup = format/version/date/checksum plus all profiles, records and embedded images. SHA-256 detects accidental corruption; it is NOT a signature or encryption. Export intentionally removes PIN hash/salt. Restore validates before replacement, keeps the current installation's lock, and disables silent automation/notifications for review. A ZIP is read in memory; arbitrary entry paths are never written. Size/record limits defend against accidental excessive imports, but this is not a hostile-file sandbox/security audit.

CSV import maps columns and previews all invalid rows before one atomic batch. IDs are preserved when present; otherwise stable row fingerprints prevent accidental repeat imports. Transfers/attachments/full tags use JSON/ZIP instead. CSV export neutralizes dangerous spreadsheet formula prefixes in text cells.

Activity/Search CSV and PDF exports capture the full active-profile filtered list, not the 80 rendered rows. An explicit ID selection resolves against the whole active-profile ledger even after search hides a selected row. The chooser distinguishes these scopes, dismisses the search keyboard and warns that amounts are unmasked and files unencrypted. `TransactionExportService` copies the selection before asynchronous generation. A filtered PDF includes the complete selected-record table and discloses future saved records, manual rates and its non-backup scope; no-income savings rates are unavailable. Reports' existing PDF/print and backup flows remain separate.

Canonical custom links use `tink://`; legacy `paisa://` remains compatible and can collide with the original app's registered scheme. Automation accepts `description` as a notes alias, with explicit `notes` taking precedence. It retains unlock, opt-in, existing-name validation, bounded queue and duplicate guards; no transfers or remote payment are inferred. Native widget/manifest identifiers stay stable, while their launch URLs and visible labels use Tink. The original website's HTTPS/universal-link domain is not owned or claimed by this app. Native dispatch still needs platform/device testing.

The six-digit PIN is derived with PBKDF2-HMAC-SHA256 (120k rounds, 128-bit random salt). UI lock is above the Navigator and obscures background/resume; biometrics are native with PIN fallback. Five failures create an in-process cooldown, not a tamper-proof hardware retry counter. Hive and backup data are not encrypted at rest. Device sandbox/encryption, safe exports and a trusted browser are still required. Widgets mask amounts while lock/hide settings are on. No remote telemetry/logging SDK is present.

## Extension points

Repository interfaces allow replacing snapshot storage with indexed Hive records/Drift without changing feature UIs, provided commit atomicity is preserved. Future encryption should use a carefully designed secure-storage key lifecycle with explicit backup/recovery semantics—not a fixed key in source. Native background posting must account for OS scheduling restrictions and concurrent repository writes. Complete translations can expand the ARB surface without introducing a translation server.

## Reference UI state

Shared chart painters and inspection hit-testing use the same data bins/points. Posted analytics and book-total catalog scopes are explicit rather than silently interchanged. The Analytics insights and Spending Health habits have route-local `PageStorageKey`s so lazy vertical list recycling restores the selected horizontal page as well as its counter. Narrow/large-text layouts stack; normal People/Places and category rows reserve only the actual trailing amount width, with a bounded scale-down fallback for very large values. These source/widget guarantees do not certify exact proprietary fonts, every physical-device layout or motion inferred from still images.
