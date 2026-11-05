# Tink 1.2 build verification — 2026-11-05

Version: **1.2.0+3**. The editorial/glass redesign is being validated on
[`arena/9ea2a134-moneymate`](https://github.com/Shitwitt/MoneyMate/tree/arena/9ea2a134-moneymate).

**A fresh 1.2 APK is not published yet.** Do not relabel the historical 1.1 APK as
this redesign. [Previous verified 1.1 release evidence](HISTORICAL_1_1_BUILD.md)
is retained separately.

The release process checks the actual embedded version, Tink label, package ID,
Android API 24 minimum, all three ABIs, absence of Internet permission, signature
and SHA-256 before publication. Signing remains the documented test/debug-key
fallback unless a persistent release keystore is configured.

Full unit/widget, DST, offline packaging, browser and native results will be
recorded here after completion; source changes alone are not build proof.

## Installation and platform limits

No physical Android/iOS installation is claimed. Camera, biometrics, notification
delivery, launcher widgets and signed upgrade continuity need [device QA](QA.md).
iOS sources are included; Android success is not iOS compilation/signing proof.

**Export and verify a backup before uninstalling an older version.** An APK from
a different CI signing certificate cannot update an existing installation even
though the package ID is unchanged. Keep a verified backup, uninstall only if
necessary, install Tink, then restore. Configure a persistent private release key
for future signed upgrades; never commit the key or put it in chat.

Local storage and portable backups are not encrypted at rest. The app PIN is not
database encryption. Pro is a free local simulation; all transfers/assets/cards
are bookkeeping records, not banking, payments or card issuance.
