# Tink 1.3 reference batch 1 — verification in progress

Source version **1.3.0+4**, branch `arena/9ea2a134-moneymate`.
No verified 1.3 APK is claimed yet. [The 1.2 binary is historical](HISTORICAL_1_2_BUILD.md).

- Local preliminary Dart/WASM parsing, JavaScript syntax and four Python offline-packaging tests passed.
- Actual Flutter SDK checks found missing imports and formatting differences in the first iteration. Corrections are being rechecked; a preliminary parser is not SDK proof.
- Strict non-mutating formatting remains mandatory. Diagnostic formatting runs only on a temporary copy and cannot turn a failed gate green.
- New regression coverage targets demo isolation, recurrence atomicity/anchors/metadata, 36 generated locales, RTL, larger text, restored layout migration and real expense-series data.
- Fresh native APK inspection, browser screenshots/offline checks, certificates and checksums will be recorded here after completion.
- Physical-device integration and signed iOS distribution remain unverified. No assertion of exact proprietary-font or unseen-screen matching is made.

Data and portable backups are unencrypted. PIN/biometrics are interface locks, not database encryption. Pro remains a persisted local simulation.
