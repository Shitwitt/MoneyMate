# Reference batch 4 — Categories, connected entry, context and Spending Health

**Status: integrated; SDK/browser verification in progress. Not yet a completed handoff.**

All 20 supplied originals were opened before implementation. This batch follows the verified Batch 3 baseline `244c9b62bdc7a7adbf60a81525e6ff647f8aa631` / run `42189659642`. Tink retains its own branding, original icons, licensed rounded fonts and isolated fictional demo. No OS bars, private overlays or proprietary photos are copied.

## Reference coverage

| Original | Connected implementation |
|---|---|
| 040253 | Existing Recurring overview/statistics, All/Calendar, Active/Due/Archived and real process/archive/history flows retained; finite shared card/icon/ring motion |
| 040311, 040313 | Full recurring help retained: frequency, processing, totals, statuses, archive, reminders/end, budget/tags and local-only operation |
| 040332 | Categories help: types, ID-based hierarchy, budgets, insights, organization and scope |
| 040336 | Category type tabs, parent/child chips, actual counts/signed totals, period selection/calendar, sorting/custom reorder, Add |
| 040349 | Category detail: subtree/exact-child filters, stacked/pie allocation and 18 financial-month curved-line points |
| SmartSelect_20261106_040403_Paisa.jpg | Eight calendar-week bar windows; painter-matched long-press/drag inspection and exact record drilldown |
| 040413 | Category count, mean/largest amount, actual activity insights, grouped history, pinned period dock and Edit |
| 040447, 040451, 040459 | Reworked full transaction form: type/templates/name/autocomplete/calculator/notes/date/time, expandable account/category/subcategory/budget/labels/people/place/loan/goal choices, Add flows, receipts and fixed Add transaction / Save transaction with expand/collapse control |
| 040544, 040550 | Places help/list/grid/book-net/counts, financial-month/overall/sort, detail, Add/Edit and non-destructive deletion |
| 040605 | People help/linking/sorting/signed net/counts and linked local records; no contacts upload |
| 040615, 040621, 040630, 040637, 040647, 040659 | Continuous Spending Health dashboard: disclosed local index/components, logged-expense streak/challenge, report card, swipeable habits, heatmap, category sparklines, signed recorded-surplus projection and possible repeating-purchase review |

## Calculations and scopes

- Category trees use **IDs**, include descendants once and remain bounded for malformed legacy cycles. New invalid hierarchies remain rejected. A named detail chip selects the exact category; the overview includes the subtree. Posted/included-account analytics never silently include future schedules. Transfers expose moved volume, not fabricated income/expense or net profit.
- Category charts use 18 actual financial-month line-chart windows and eight calendar-week windows. Positive/negative bounds share a genuine zero baseline. Bar selection uses the same bins as painting; line selection uses endpoint positions. Holding/dragging, taps, arrows and accessibility adjustments reveal the same values. Undefined percentage comparisons remain unavailable. Matching-record routes preserve category, date, posted/included and other filters.
- People/Places book totals deliberately include saved schedules, as Labels do. Net is income minus expense; transfer records count but add zero to net. People may overlap. Deleting a context strips its links, not the money records.
- Every cash-flow amount uses saved **manual reference rates**, not live prices or guaranteed historical-rate snapshots. Transfers retain their explicitly saved receiving amount; dedicated loan repayment agreements retain their existing immutable-base rules.
- The hero ring is the equal mean of available Buffer, Spending, Goals, Debt and Record coverage indicators, requiring at least two. These are transparent local bookkeeping indices, **not real financial-health, credit or medical assessments**. Its cash inputs are posted records; opening balances, saved allocations and current tracker state are explicitly disclosed. Missing history is not financial well-being.
- Streaks count consecutive expense-logged calendar dates below the **unrounded** six-completed-financial-month daily mean. Gaps break them. Absent/zero expense baselines are unavailable. Current-day records remain provisional. The illustrative challenge is a rounded 15%-lower target versus the largest prior-period category, not a saved budget or advice.
- Heatmap days without cash-flow records are **not recorded**, not verified no-spend days. Saved transfers are excluded from this cash-flow view. A selected day exposes actual income/expense/net and scoped records.
- Year-end projection is signed posted year-to-date income minus expense plus the six-completed-period mean daily surplus times calendar days after today. It is not an account balance, investment return, forecast guarantee or proof of an actual zero when logs are absent. Negative values remain negative.
- Repeat candidates require at least two consecutive completed calendar months ending last month, exactly one transaction/month, normalized name/account/category matching, days within three and native amounts within 20% of the unrounded median. Archived accounts, recurring-linked records and existing matching rules (including archived rules) are excluded. Daily illustration is monthly amount × 12 / actual days in the year. A candidate is **not a confirmed subscription**: the review form is unsaved, automatic posting starts off, and only explicit Save creates a rule.

## Persistence, motion and access

The transaction form keeps calculator validation, native-account precision, explicit/editable transfer FX, existing timestamps/receipts/links, manual budgets, templates, sequential entry, and validate → durable save → publish. Its fixed footer cannot scroll away; collapse preserves metadata. Missing category types are recoverable through Add rather than selecting an invalid hidden fallback. Existing editor route-completion/controller-disposal and own-route closure under achievements are retained.

Card/icon/ring/chart effects are finite and respect reduced motion. No endless ornamental loops were introduced. Icon foregrounds choose black/white against their composited background, rather than retaining low-contrast white on every peach tint. Shared 48px control targets, scaling/RTL and dock-versus-FAB geometry remain required; this is not a blanket accessibility-conformance claim.

Detailed help/forms remain predominantly English alongside the 36 starter core locales. Proprietary reference fonts and exact motion timing cannot be certified from still images. Camera/gallery, physical-device and iOS checks remain platform work. Local data/backups are unencrypted; PIN is not database encryption.

## Verification gates (pending)

- Flutter SDK format, analyzer and full suite, including added data/gesture/narrow-160%-RTL/privacy/pinned-save regressions.
- America/New_York calendar/DST run with UTC-instant weekday/last-seven cases.
- Connected browser journey with real carousel swipes and pointer holds, real record drilldowns, category scopes, metadata persistence, context edits and unsaved reminder-draft cancellation.
- Required full screenshot files plus bounded review copies for all Batch 4 sections, while preserving Batch 1–3 browser/offline coverage.

**APK hold remains active.** Both release and direct-Gradle native paths stay opt-in. No APK/AAB/native build is requested.
