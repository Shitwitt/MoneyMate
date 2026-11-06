# Tink 2026 rebuild — source, features and limits

Edition **2026.11.6+6**, reviewed 2026-11-06. This is a substantive update of the existing Tink application, not a renamed build 5, an official Paisa binary, or a claim to possess the closed/current official 2026 Flutter tree.

## References actually checked

1. All previously supplied reference batches remain mapped in `REFERENCE_BATCH_01.md` through `REFERENCE_BATCH_04.md`. The warm coffee/peach Material 3 layout, original Tink art, chart calculations, help pages, hold inspectors and connected destinations are preserved.
2. [Paisa website](https://paisa-tracker.app/), [changelog](https://paisa-tracker.app/changelog), [FAQ](https://paisa-tracker.app/faq) and [automation](https://paisa-tracker.app/automation). The newest website changelog entry returned at review time is **2026.03.04**; this does not establish the latest store binary or an exhaustive current feature specification.
3. [h4h13/paisa-app releases](https://github.com/h4h13/paisa-app/releases): an assets/release-documentation repository, not the complete Flutter implementation. The latest release returned was v2025.08.21. The earlier finding about absent reusable app source applies to that repository, **not to every surviving fork**.
4. The newly supplied README is a source-recovery/build guide, not an attached full application tree. It identifies [confumbit/Paisa](https://github.com/confumbit/Paisa), whose `dev` source was pinned at **369aee29ebf51dd5007deca2bb414917f12b208a**. Its actual `LICENSE.txt` says **GPL-3.0-or-later, Copyright (C) 2022 Hemanth S**. Package name/version were independently read as **paisa 6.3.6+636** without importing or displaying upstream packaging/signing secrets.
5. The guide's [maxcodl/Paisa-plus](https://github.com/maxcodl/Paisa-plus) reference was checked at **516fafbf0b7a994005f82c92cff5f156d8c2d664** (commit date 2026-10-31). It is a separate Kotlin/Jetpack Compose rewrite with no Dart files, not current official Paisa Flutter source. Its SMS/Gmail/model/update-network integrations were not imported: they would contradict this project's no-network/no-message-access constraints.

## Real licensed code reuse

`lib/core/services/paisa_legacy_decoder.dart` adapts the genuine old `PaisaDataResponse` and account/category/transaction/debt/repayment JSON factories into typed Dart records. This is functional compatibility code, not an unused source dump. It is used by the new Backup → **Import Paisa 6.3.6 JSON** workflow.

The existing Tink finance/UI was not replaced wholesale by the old tree: the old goals repository contains unfinished methods and would regress working Tink features. No old packaging configuration, signing credentials, proprietary art, logos, screenshots, fonts or APKs were imported. Original schema excerpts, exact commit/file hashes, copyright, licence and modification notices are in `third_party/paisa_6_3_6/`.

The combined derivative distribution is now **GPL-3.0-or-later**. The original Tink MIT notice is retained in `LICENSES/Tink-original-MIT.txt`; font/dependency notices retain their own terms. Settings → Open-source licenses includes the GPL, original MIT notice and adaptation provenance. Each new APK publication includes the complete runnable Tink source ZIP from the **same build commit**, including build scripts and notices.

## New work in this edition

| Area | Implemented behavior | Safety / actual scope |
|---|---|---|
| Direct Home reordering | Home toolbar handle enters inline edit mode. Individual cards have real drag handles and accessible move-up/down buttons. Save persists immediately; Done returns to the normal paired dashboard. | Hidden-card positions and visibility remain intact. Failed durable saves never publish a different order. Existing chart long presses are not hijacked for reordering. This is edit → drag, not a claim that every normal chart surface is a reorder handle. |
| Page shortcuts | Settings → Page shortcuts copies canonical `tink://open?page=reports` and other allowlisted local destinations. Direct `tink://reports` and `tink://page/reports` forms, plus legacy `paisa://`, are accepted. | Page requests cannot create money records. Existing profile/unlock/demo/queue guards remain. A destination is pushed without silently discarding an unsaved editor. No ownership of Paisa's HTTPS domain or universal links is claimed. |
| Shape privacy | Shared `AmountText` now paints a fixed circle/diamond/square mask, independent of amount, sign or digit count. Accessibility says “Amount hidden”, not the private value. | Existing chart inspectors hide values under privacy. String-only contexts/native widget text can still use a text mask. Full amounts in explicitly confirmed exports remain disclosed. Privacy is not encryption. |
| Transaction keyboard flow | Name's Next focuses Amount; Amount's Next focuses Description/notes. Multi-line notes remain possible and an icon identifies the field. | Focus changes do not save, select a different autocomplete name, clear metadata, or discard the calculator expression. All focus nodes/controllers are disposed with their editor. |
| Category exclusions | Transaction/report filters can exclude specific categories **and their descendants**, with exclusions preserved when date windows change. | Exclusions win over inclusion, scope the same underlying records/exports, and never delete categories or history. Clearing filters clears exclusions too. |
| Tablet accounts | The existing account master/detail view now works at portrait-tablet widths from 760px as well as landscape. The detail pane has its own close action. | 800px/1280px automated layouts are targeted. Larger text falls back to a single-pane presentation; account action buttons wrap. This is not certification of every tablet screen or device. |
| Legacy source compatibility | Choose an old JSON file, explicitly select its currency and loan-direction interpretation, validate/preview, then confirm creation of a separate profile. Optional retained original JSON is downloadable from Backup. | Exact 6.3.6 schema only; 10 MiB uncompressed limit. Both old repayment key variants are handled without dropping/doubling data. No existing profile is replaced, no synthetic repayment cash is posted, and lock material stays local. |
| Version identity | App/Android metadata, in-app About and iOS extension metadata use 2026.11.6 / build 6. Home has a 2026 badge. | The version bump accompanies the functional code above; it is not evidence of official source provenance. Package/component IDs remain stable. |

## Existing publicly documented finance features retained

- 14-step local setup, multiple isolated profiles, editable temporary demo and safe exit; no account/backend/tracking.
- Multi-currency account kinds/finishes, signed opening balances, account grouping/history, single-record transfers with agreed receiving amounts, manual reference rates and net worth.
- Income/expense/transfer entry, inline expression calculator, templates/frequency suggestions, date/time, notes, receipt attachments, labels, people/places, bulk selection and full filtered/selected CSV/PDF export.
- Categories/types/parent-child hierarchy, category calendar/donut/stacked/monthly/weekly/overview/insight routes; overlapping label/context relationships are not falsely additive.
- Budgets/custom dates/rollover/overspend/allowances; manual and account-linked goals; lent/borrowed loans/partial repayments/manual closure; bill split/settlement bookkeeping; manually valued assets/custom icons/history.
- Recurring overview/All/Calendar/Active/Due/Archived/help, intervals/end/reminders/process/history; saved templates and upcoming transactions. No false guarantee of OS background ledger posting.
- Five reports plus analytics/trends/velocity/six-month comparisons/weekday/outlier/projection panels, actual held values and scoped transaction routes; PDF transaction tables and custom date windows.
- Local reminders, original achievements, transparent local Spending Health components, free local Pro simulation; Android widgets and iOS WidgetKit source; system/light/dark/Just Black, dynamic/accent colors, licensed offline fonts, reduced motion and RTL.

## Legacy import details to review before confirming

- Old exports do **not** store per-account currency; one explicitly chosen currency is applied to all imported accounts. Cross-currency transfers cannot be reconstructed by guessing. Currency minor-unit rounding is counted and disclosed.
- The old Debt/Credit labels are ambiguous across user conventions. The user explicitly chooses the mapping; the preview shows loan directions and principal amounts. No bank/payment connection is created.
- Repayments/contributions become history only. Existing cash records are retained once; manual closed-loan flags do not fabricate a final payment. A completed legacy goal becomes archived.
- IDs must be integral, present and unique. Missing references, mismatched repayment parents/types, overpaid loans, unknown enums, malformed dates/JSON, wrong/current versions and oversized files fail before storage.
- Categories used for both income and expense receive separate valid type-specific mappings. Original bank labels and transaction/loan notes are retained. Old numerical icon codes use Tink icons.
- Old category caps lack stored date windows and are not activated as guessed Tink budgets. Original category descriptions/icon codes/goal descriptions and every original field remain in the retained source JSON if that option is enabled, or in the user's original file if declined. Keep that file.
- Adding an imported profile preserves all existing profile data byte-for-byte and the current lock. Global silent-add and notification switches are disabled for explicit review. An import does not award spending achievements.
- During **Demo**, imports remain temporary and disappear on Exit Demo; the UI warns before confirmation. Exit Demo before importing real data for persistence.
- Local data, retained original JSON and backups are **unencrypted**. Keep exports private. A Tink checksum verifies backup integrity, not secrecy or the trustworthiness of the input file.

## Honest differences from the official product

No current official 2026 Flutter implementation or store binary was obtained. Current-Paisa backup formats, complete official localization, automatic Google Drive/iCloud account integration, branded seasonal splashes and exact proprietary layouts/fonts/assets are not claimed. Tink keeps 36 starter core locales; detailed forms/help are largely English. Optional OS share/save can place a local export in a provider selected by the user, but Tink itself does not upload it. Native SMS/Gmail/notification scraping and model downloads from the separate Paisa+ rewrite are deliberately not added.

App compilation, browser tests, parser/controller tests and layout tests do not prove physical-device camera, biometrics, notification delivery, launcher widgets, native intent dispatch or iOS signing. The APK handoff must identify its real certificate and warn about backup-before-uninstall if a prior installation is signed differently.

## Verification status

Implementation and regression coverage are present. **New-build checks and publication are pending until recorded in `BUILD_STATUS.md` and `ANDROID_BUILD_06.json`; build 5 is historical and is not this 2026 APK.** The strict SDK format/analyzer/Flutter suite, calendar regressions, Python packaging/licence tests, browser journeys and both explicitly requested native build paths will determine the release status.
