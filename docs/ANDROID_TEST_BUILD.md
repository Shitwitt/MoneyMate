# Tink 1.3.0+5 — Android test APK ready

## GET YOUR APK NOW

**[Download Tink-Android-release.apk](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42205565833/Tink-Android-release.apk)** — Android 7/API 24+, 98,819,607 bytes (98.8 MB); universal ARM64, ARMv7 and x86-64. This is the new build 5 with the connected reference batches 1–4 and whole-app reference review, not the older build 4.

[APK SHA-256](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42205565833/Tink-Android-release.apk.sha256) · [Public package/certificate metadata](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42205565833/Tink-APK-metadata.txt) · [Complete APK-matched runnable source](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42205565833/Tink-source.zip) · [Source SHA-256](https://github.com/Shitwitt/MoneyMate/releases/download/apk-release-42205565833/Tink-source.zip.sha256)

**Here is how you get the APK ready to download and install**

1. If an earlier Tink is installed, **export and verify a backup before uninstalling anything**. This build's Android Debug test certificate differs from the last published build 4, so Android cannot update that differently signed installation in place. Uninstalling deletes local data. Do not bypass this warning by clearing app data.
2. Download the `.apk` above, not the source ZIP. Open it from Downloads; allow **Install unknown apps** for your browser/files app if Android asks, then install.
3. Open Tink. Start with **Try Demo Mode** to test the connected features without changing a real profile, or restore your verified Tink backup after completing setup. Paisa's own backups are not claimed to be compatible.

## Checks that passed

- Exact built source: `61897023181c99469a3cb915071d167f6ed6c6b3`.
- [Main workflow 42205565833](https://github.com/Shitwitt/MoneyMate/actions/runs/42205565833): **SUCCESS**, all 13 jobs passed.
- Strict SDK formatting, analyzer, complete Flutter suite, DST/calendar reruns and all 15 Python regressions passed (`127851199323`).
- Optimized Android APK compile, Tink label/version/package/minimum, all three native app payloads, signature verification and absence of Internet permission passed (`127852137596`).
- Real-browser setup/persistence/offline checks, chart/calendar holds, carousel swipes, filtered PDF/CSV downloads, saved calculator/name/notes and recurring-draft cancellation passed (`127852137822`). All 39 Batch 4 and 27 Batch 3 full-frame gates passed again.
- [Separate direct-Gradle debug build 42205565926](https://github.com/Shitwitt/MoneyMate/actions/runs/42205565926): **SUCCESS** (`127851198481`). The primary download above is the optimized release-mode APK, not that separate debug artifact.

## Identity and signing

- Version: **1.3.0**, Android build code **5**.
- Package ID: `com.example.paisaclone` (legacy stable ID); displayed brand: **Tink**.
- APK SHA-256: `70c0e9052c64b12b10d0b25ebdae81e98e0584f900cac5a1963e6a73e0af8714`.
- Signer: `C=US, O=Android, CN=Android Debug` — test signing, **not Play Store signing**.
- Certificate SHA-256: `24f95422e50a2cb83e658390edca1280e8fbaeac1ffa2bff5566d991ab3453c9`.
- Minimum API 24; compile SDK 36; no Internet permission.

Compilation/package inspection and browser tests are **not physical-device testing**. Camera/gallery, biometrics, native link dispatch, launcher widgets, local notifications and OEM background restrictions still need testing on a phone. No iOS build is claimed. Data/backups are unencrypted; PIN/biometrics are interface locks, not database encryption. Pro is a local simulation, not a purchase.

Tink was independently adapted from its existing code using the supplied images and public feature/layout references. The linked Paisa repository did not provide reusable Flutter app source; no exact clone or certified Paisa parity is claimed. The source ZIP captures the exact build-time revision; completed-build notes and later documentation are available here and on the working branch. Future native builds remain explicit opt-ins.
