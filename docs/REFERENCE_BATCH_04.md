# Reference batch 4 — Categories, connected entry, context and Spending Health

**Status: complete and source/browser verified — 6 November 2026. No native build.**

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

## Verification — completed

Authoritative application/source revision **`4f018d40e9193e8cd916c90a5d0e6b0d3333b5ae`**:
[run 42203316290](https://github.com/Shitwitt/MoneyMate/actions/runs/42203316290), **SUCCESS**.

- **Source `127843696973`: PASS.** Strict non-mutating SDK format, localization generation, analyzer, complete Flutter unit/widget suite, America/New_York calendar/DST reruns and all **15 Python packaging/platform-contract regressions**. New regressions include full 150-record exports, immutable selection, no-income PDF behavior, incoming search query, selected records surviving a later search, recycled-carousel state, narrow 160% LTR/RTL, chart gestures, privacy, pinned controls and unsaved recurring/no-replay behavior.
- **Browser `127844476713`: PASS.** Genuine pointer holds and touch swipes, painter-matched category inspection, exact scoped records, actual CSV/PDF downloads with chooser-count/CSV-row and PDF-header/size checks, calculator expression `2+0.50` saved as **$2.50**, exact saved name/notes through transaction details, context list/grid/scopes/help/grouping/persisted rename, all Spending Health sections and recurring-review cancellation. Calendar hold showed **4 demo posted records, income $1.00, expense $115.44, net −$114.44**, matching its actual scoped records. A held calendar button is not substituted with its tap-to-records action.
- Browser coverage retains the existing Batch 1–3 journeys, all 14 real setup steps, exact saved profile name, theme persistence, offline reload and **zero external runtime requests**. Browser/layout error collection was empty.

| Required Batch 4 evidence | Job | Result |
|---|---|---|
| Categories/allocation/graphs/hold/overview — 9 frames | `127846782379` | PASS |
| Connected transaction form/calculator/metadata/saved detail — 6 | `127846782257` | PASS |
| People/Places help/list/grid/detail — 7 | `127846783557` | PASS |
| Spending Health, real swipe/hold, projection/repeats/draft/help — 13 | `127846782523` | PASS |
| Recurring list/calendar/help — 4 | `127846782241` | PASS |

All **39 full screenshot files** passed the strict presence/JPEG evidence gates. All **39 bounded review copies**, plus the refreshed **27 Batch 3 copies**, were reviewed: 44 are byte-identical to already opened copies and 22 new/changed copies were reopened. [Per-frame byte counts, SHA-256 hashes, job provenance and review inventory](REFERENCE_REVIEW_04.json) record the complete 66-frame set with no missing/unexpected names. Bounded API copies are a layout review, **not full-resolution pixel/font/motion certification**. Full-size captures remain in the run's web artifact.

Refreshed Batch 3 evidence also passed: loans `127846782305` (8), goals `127846782409` (5), labels `127846782921` (4), Analytics `127846783099` (10). Additional historical-reference review `127846782520` passed. Analytics/habit page storage now preserves the actual selected card after vertical list recycling, not just its counter. Normal category/context row names no longer lose half the row to an unnecessarily flexible amount column; narrow/large-text stacking remains intact.

The subsequent [whole-app public-reference audit](PAISA_REFERENCE_AUDIT.md) preserves existing features and records the independent-source/licence boundary, filtered/selected exports and canonical/legacy automation compatibility. No complete Paisa-platform parity is claimed.

**APK hold remains active.** Release job `127844479187` and separate direct-Gradle run `42203316348` were **SKIPPED**. No APK/AAB/native compilation was performed. Physical-device/iOS and native widget/link execution still need platform QA; static platform-contract tests do not certify them. Both native paths remain explicit opt-ins until the user says **“make APK.”**
