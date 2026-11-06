# Reference batch 3 — Loans, Goals, Labels, Analytics

**Status: implementation and verification in progress. Not a completed handoff.**

This batch uses the 20 originals `Screenshot_20261106_<time>_Paisa.jpg` provided on 6 November 2026. All twenty have been opened and reviewed. Screenshot financial figures and date countdowns are not authoritative data: several do not reconcile. Tink keeps actual local-record calculations, its own branding, licensed fonts and original assets. No OS bars, private overlays or proprietary imagery are reproduced.

## Reference-to-implementation checklist

| Original time | Screen / behavior | Source / verification target |
|---|---|---|
| 035912 | Loans help: types, payments, summary, status, people, dates, progress | `loans_screen.dart`, fixed-title / scroll-body / pinned Got it sheet |
| 035915 | Loans help continuation and sorting | Same sheet, all eight sections; name/principal/remaining/due-date sorting |
| 035928 | Loan principal, pills, payment progress/details/manual completion/Edit | Loan detail; actual paid vs unpaid vs total; explicit close/reopen |
| 035935 | Loan payment and linked transaction history | Tracking-only events plus linked ledger records; live transaction details |
| 035947 | Lending editor and entity/date/account/category choices | Full-page transactional editor, pinned Create/Update Loan |
| 035953 | Category choices and color palette/shades/hex | Shared reference picker; accessible 48px swatches, copy and custom hex |
| 040003 | Borrowing and income-category choices | Type-dependent category options; existing payments protect direction integrity |
| 040020 | Payment transaction details and Delete/Edit/Copy | Live bottom sheet; navigable linked entities; copy opens an unsaved draft |
| 040038 | Goals help | Five sections; explicit whole-book-balance versus manual allocation tracking |
| 040044 | Goals list, statuses, signed saved/remaining/percentage/sorting | Linked balances remain negative; completion is derived; archive is reversible |
| 040047 | Goal detail, date/needed tiles and grouped history | Linked-account transaction scope includes transfer destinations; day/week/month/year grouping |
| 040100 | Goal editor, dates, account, colors and photo/icon | Full-page editor; gallery photo optional, validated local raster, original icon choices |
| 040117 | Labels help and many-to-many behavior | Three sections; overlapping tags never duplicate ledger records |
| 040122 | Labels list/grid, counts, signed totals, financial-month/overall | Live scopes, names/icons/colors and Add |
| 040128 | Label detail, income/expense summary, grouped records/Edit | Signed net in base currency; transfers count as records but not cash-flow net |
| 040148 | Smart Insights swipe, velocity/7-day chart and summary cards | Local `AnalyticsSnapshot`; calendar-day math and disclosed estimates |
| 040200 | Top categories and six-month curved overview | All-history category shares; posted-only month buckets with bounded curves/dots |
| 040206 | Per-category predictions | Six-completed-month average + current pace, floored at posted spending |
| 040214 | Unusual spending entries | Per-category Tukey upper fence, minimum four observations; tap to record details |
| 040222 | Category trend sparklines and weekday bars/extremes | Actual six-month/current-period values and all-history Sunday–Saturday totals |

## Financial and persistence contracts

- Loans persist optional start date, icon/color, person, account/category preferences and manual-closure status without changing legacy records. An absent legacy start is **Not recorded**, not an invented date.
- Principal and flat lifetime interest are in profile currency. New loans can optionally post a converted disbursement; editing does not duplicate or rewrite it. Repayment action optionally posts a linked native-currency account record. Merely tagging another transaction as a loan is not a repayment.
- New explicit repayment events store their transaction IDs. Amount/account edits update tracked paid amounts; notes/date edits retain the agreed base amount. Unrelated writes and FX changes must not silently revalue old payments. Deleting/unlinking removes the linked event. Legacy independent tracking-only payments are not guessed from names.
- Paid is actual posted repayment events; scheduled future repayments are not yet paid. Manual completion removes the debt from outstanding summaries but never fabricates paid cash. Reopening restores the genuine unpaid balance. Contract dates organize the tracker, not a bank accrual schedule.
- Linked goals use the whole account book balance, including opening, withdrawals, transfers and scheduled records, using saved FX. This preserves existing Tink behavior while removing the misleading zero floor. It is **not deposit-only tracking**. Manual allocations remain saved when linked but are not double-counted; unlinking restores their use. Unlinked progress remains manual allocations plus tagged income.
- Labels are many-to-many. Book totals include saved scheduled records; income minus expense is net, transfers contribute zero. Different labels overlap and must not be added together as a consolidated total. Deleting a tag retains every transaction and other tags.
- Analytics uses posted expenses, saved FX and included accounts only. No transfers, opening balances, future records or fabricated scores. Current-month comparisons explicitly name the prior **whole** financial month. Zero baseline percentages are unavailable, not fake 100% increases.
- Velocity uses elapsed calendar days including today; remaining excludes today. Each category forecast equally blends its six-completed-month average and current pace, with a floor at that category’s posted spending; without a category baseline it uses pace alone. The overall prediction is the sum of those category forecasts, so the panels reconcile. Predictions are transparent low-confidence estimates, not AI advice. Outlier flags are not fraud detection. Empty/sparse data remains empty/unavailable.
- All writes keep validate → durable save → publish. Editors await their own route exit before controller disposal and close their own route even when an achievement overlays it. Copying a record opens a new draft and never silently posts money.

## Motion, accessibility and platform limits

Shared rounded coffee/peach theme, finite/reduced-motion wave/line/bar transitions, genuine horizontal insight paging and scrollable help/editors. Large-text / narrow / RTL checks target every new screen. Palette touch targets intentionally remain at least 48px, so the number of columns can differ from the reference. Monetary privacy must mask chart values and raw goal/loan percentages too.

Exact proprietary font outlines and motion timing cannot be certified from still images. Detailed forms/help remain mostly English, alongside the existing 36 starter core locales; this is not a complete-translation claim. Gallery selection and physical-device/iOS execution need platform testing. Local data/backups remain unencrypted; PIN is not database encryption.

## Verification (in progress)

Run `42176720069` at `d374c68` passed Flutter analysis, the full Flutter test suite (including the repaired chart semantics), the America/New_York calendar run and all 12 offline-packaging Python tests. The run remained red solely on strict SDK formatting; its exact SDK patch has been applied. New calendar-date boundaries, retained direction-specific category drafts and explicit repayment conversion disclosure are being rechecked. Browser journeys and screenshot review are still pending; no completion claim is made.

Required remaining coverage:

- New deterministic data tests: migrations, repayments/FX/edit/delete/atomic failures, manual close/reopen, signed goals/transfers, tags/deletion, grouping/DST, analytics exclusions/rates/calendar/forecasts/outliers/empty baselines.
- New widget regressions: 320px/160% LTR and RTL across seven screens; privacy, type-dependent choices, custom hex save, lifecycle/disposal, help, label filters/grid, copy drafts, reduced-motion carousel and rounded Edit controls.
- Existing full analyzer, localization, Flutter, calendar and offline-packaging suites remain required. Exact SDK formatting is authoritative; the local WASM formatter is only a syntax/preformat aid.
- Chromium adds the connected Batch 3 demo journey and 25 Batch 3 coverage frames (including a separate swipe result and palette continuation). Existing Batch 1/2 journeys, theme persistence, offline reload and zero external runtime requests remain required.
- Four screenshot-only review jobs require the new full frames and bounded thumbnails for close review; previous Batch 2 evidence does not verify this batch.

**APK hold remains active.** No APK/AAB/native compilation is requested or authorized. Both native workflow jobs remain explicitly opt-in; source/web checks run on UI-only pushes. No next image batch will be requested until implementation and these checks/review are completed.
