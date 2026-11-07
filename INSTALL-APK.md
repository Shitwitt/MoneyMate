# MoneyMate — Android test build

**File:** `apk/MoneyMate-1.0-debug.apk` (4.95 MB / 4.72 MiB, debug-signed)
**SHA-256:** `1e5448a045bbb772bd25f6848304fdecdeb271f5f6dbbd6d71474493d47127bb`
**Package:** `com.moneymate.app` · minSdk 22 (Android 5.1+) · targetSdk 34
**Built from:** branch `arena/d91b14b6-moneymate` @ `c8173b5` via GitHub Actions

## Install on your phone

**Option A — QR / direct link (fastest)**

1. Scan `apk/install-qr.png` with your phone, or open:
   <https://github.com/Shitwitt/MoneyMate/raw/apk-builds/MoneyMate-latest.apk>
2. Chrome asks to download the file → tap it → *Install anyway* when prompted
   ("unsafe app blocked" appears because the build is debug-signed, not from the Play Store).
3. If the install is refused, enable **Settings → Apps → Special access → Install unknown apps → Chrome**.

**Option B — artifact from the Actions run**

Actions → *Build APK* → latest run → **Artifacts → MoneyMate-debug-apk** (requires GitHub login).

**Option C — rebuild locally** (needs JDK 17 + Android SDK)

```bash
npm install
npm run android:apk          # build web + cap sync + gradlew assembleDebug
# output: android/app/build/outputs/apk/debug/app-debug.apk
```

## What's inside

Everything built so far runs fully offline inside a WebView:

- **Step 1** — Home Dashboard: hero balance card, all 17 bento widgets, templates,
  calendar heatmap, trend chart, track‑budgets carousel, multi‑currency upcoming
  list, FAB and floating pill navigation (privacy masking included).
- **Step 2** — Accounts (6-account swipeable carousel + transactions), Reports &
  Analytics (month strip, insights, bar/line chart toggle, filter dropdowns,
  donut, Financial Reports directory), Budgets overview, the *How Budgets Work*
  modal and the single-budget detail view with its pace chart.
- **Step 3** — Assets (portfolio totals, grouped list, colour-picker editor),
  Bill Splitter (equal/percentage/custom, participant payment menu, net
  balances + settle-up) and Loans (lending/borrowing/completed, partial and
  full payments, auto-completion, due-date countdowns), plus a global
  light/dark theme engine.
- **Starting onboarding** — 14-step first-run flow with exact Paisa showcase
  artwork, Start Fresh, JSON backup restore/export, Try Demo Mode, 35-language
  engine, Base64 profile-photo upload, name validation and nine-currency
  selection. Replay it any time from **Profile & App Settings**; the circular
  avatar on Home / Accounts / Reports uses the uploaded photo or initials.
- **Live overhaul** — The old demo-mode ribbon and Exit Demo pill are removed.
  One persisted reactive store drives
  every input, button, calculation and eight touch/mouse-scrubbed SVG charts.
  The profile modal edits **Raj**, base currency `₹/$/€/£` and offers
  **Reset / Clear All Data**. Universal transaction, account, budget, asset,
  bill, loan, goal and template editors are fully live; future-dated rows appear
  under **Upcoming transactions**. Reports unlock all five donut dimensions and
  live month filtering. Linked loan repayments/charges, goal deposits and bill
  payments recompute summaries and progress immediately.

## Notes

- The APK is **debug-signed** (auto-generated debug keystore) — perfect for testing,
  not for Play Store distribution. Say the word when you want a release build and I'll
  wire a signed, minified release APK (keystore generated in CI, stored as a base64 secret).
- Each push to this branch rebuilds and refreshes `MoneyMate-latest.apk` on the
  `apk-builds` branch automatically.
