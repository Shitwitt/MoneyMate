# Tink build verification — 2026-11-04

Redesign version: **1.1.0+2**. Internal Android ID: `com.example.paisaclone`.

The redesigned Tink code, native labels/icons, offline fonts, six introductory
pages and tests are on `arena/9ea2a134-moneymate`. Final release and browser
verification are in progress. The final verified run/download is recorded here
after it completes. Historical PaisaClone 1.0 APK releases are not this redesign.

The release workflow checks formatting/analyzer/tests, builds an optimized APK,
and verifies the embedded version, Tink label, API 24 minimum, native ARM64 app,
signature and absence of Internet permission before optional publication. The
separate push workflow builds a debug APK directly with Gradle.

No physical Android/iOS installation is claimed. Camera, biometrics, notification
delivery, launcher widgets and signed upgrade continuity need [device QA](QA.md).
iOS sources are included; a successful Android job is not iOS compilation proof.
The default release fallback uses a debug key, not production signing. A new CI
runner can generate a different certificate. Export and verify a backup before
uninstalling an older differently signed build. Local storage/backups are not
encrypted at rest.
