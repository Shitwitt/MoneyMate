# Paisa 6.3.6 compatibility source notice

- **Copyright (C) 2022 Hemanth S**; GPL-3.0-or-later. The full, unchanged upstream licence is `LICENSE.txt` here and is bundled in the application.
- Source: https://github.com/confumbit/Paisa/tree/369aee29ebf51dd5007deca2bb414917f12b208a (branch `dev`, exact commit `369aee29ebf51dd5007deca2bb414917f12b208a`).
- The upstream package name/version were independently checked as **paisa 6.3.6+636**. Packaging/signing configuration, credentials, logos, artwork, screenshots and fonts were **not** imported.
- `reference/` contains the original schema/export/model excerpts used for this adaptation, saved as `.dart.txt` so they are reviewable source evidence, **not a second executable app or an instruction to build unreviewed upstream configuration**. Per-file hashes are in `SOURCE_MANIFEST.json`.

## Modified work, 2026-11-06

`lib/core/services/paisa_legacy_decoder.dart` adapts `PaisaDataResponse` and the JSON factories for AccountModel, CategoryModel, TransactionModel, DebitModel and DebitTransactionsModel. Hive/Freezed/generated implementation dependencies were replaced by typed Dart records; strict version, numeric, enum, ID, timestamp, size and collection validation was added. The adapter accepts the exporter's actual repayment key `transactions` and the old parser's `debitTransactions`, but rejects ambiguous simultaneous populated arrays.

`paisa_import_service.dart` and `features/settings/paisa_import_screen.dart` convert only after validation, require a currency and an explicit loan-direction mapping where applicable, preview all consequences, and append a NEW profile with fresh IDs. They do not copy the old destructive clear-before-import routine. No repayments are invented as new cash transactions. Unknown formats, dangling links, duplicate IDs and overpaid loans fail without changing current data. Legacy category caps are retained as original metadata, not silently converted to budgets with guessed dates. Original JSON retention is optional and explicitly disclosed as unencrypted local data.

The combined Tink distribution with this GPL adaptation is distributed under **GPL-3.0-or-later**, without warranty. Original Tink code was MIT-licensed; that permissive copyright/permission notice is preserved in `LICENSES/Tink-original-MIT.txt` and in-app notices. Other dependency/font licences retain their own terms. Tink branding and the rest of its finance implementation remain independent; no affiliation with Paisa/Hemanth Savarala is claimed.

Every distributed test APK must be accompanied by the corresponding runnable Tink source archive from the **same build commit**, including modifications, build scripts, this notice and the licences. Do not use a different historical ZIP as the corresponding source. This repository's APK publisher uploads that archive beside the APK. No current official 2026 Paisa Flutter source was obtained; do not advertise this legacy adaptation as such.
