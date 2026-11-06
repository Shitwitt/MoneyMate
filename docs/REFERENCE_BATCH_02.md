# Reference batch 2 — Home, Accounts, Reports and Budgets

## Build hold

**Do not compile or publish an APK until the user explicitly requests “make APK.”**
Both Android workflow jobs are opt-in. Ordinary UI/check pushes run SDK checks and
web verification, not either the release APK or direct-Gradle debug APK build.
The separately downloadable Batch 1 APK/source ZIP are unchanged and do **not**
contain this batch's UI. Work continues on `arena/9ea2a134-moneymate`.

## All 20 supplied references

Files are the user's `Screenshot_20261106_*_Paisa.jpg` unless noted. Reference
photos are review inputs only; they are not bundled as app artwork or backdrops.

| Reference | Implementation / behavior |
| --- | --- |
| `035435` | Greeting, profile/tools, hideable balance and previous-month cash flow, spacious paired overview tiles |
| `035453` | Budget usage, assets, bills, loans, goals and labels, all calculated from local records |
| `035500` | Spending analytics, recurring estimate, category totals, actual weekly bars and cumulative 30-day expenses |
| `035506` | Person/place summaries, explicitly record-derived planning indicators, earned badges, usable template strip |
| `035513` | Month activity heatmap and inspectable actual/prior/upcoming net-cash-flow trend |
| `035519` | Tracked-budget carousel and upcoming transaction list |
| `035528` | Further carousel pages, scheduled metadata and native/reference-currency transaction amounts |
| `035617` | Swipeable account card, monthly comparisons and richer transaction rows |
| `035622` | Other account states; optional entered suffix/holder labels and linked-account counts, not invented bank information |
| `035636` | Month selector, period net, income/expense comparisons and genuine Quick Insights |
| `035641` | Actual daily bar/line toggle, income/expense selection, grouping and interactive doughnut |
| `035652` | Category breakdown, five working financial-report destinations and reporting exclusions note |
| `035707` | Shared budget-help sheet: targets, types, modes, periods and categories |
| `035711` | Budget-help continuation: exclusions/subcategories, signed rollover and tracking |
| `035059` | Shared recurring-help presentation with the existing scheduling behavior retained |
| `SmartSelect_20261106_035112_Paisa.jpg` | Recurring end dates, budget links, labels, places and people |
| `035724` | Paged budget allowance/spent/remaining overview, tinted cards and wavy usage |
| `035730` | On-track/warning/exceeded overview, sorting and help |
| `035745` | Budget detail, persisted Show Budget, actual/ideal/limit chart and edit/add/delete |
| `035751` | Real category breakdown and recent matching transactions |

## Data rules, not mock graphs

- `core/data/reporting.dart` builds posted report snapshots. Transfers, opening
  balances, excluded accounts and future-dated records are omitted from period
  income/expense. Conversion uses the user's current manual reference rates;
  neither live nor reconstructed historical market rates are claimed.
- Daily average uses the full selected period; average transaction means average
  expense. A zero income baseline makes savings rate unavailable, not a made-up
  percentage. Peak-day ties use the earlier date. Parent-category totals include
  descendants. Multi-label/person groups can overlap, and the UI explains that.
- Month summary, category breakdown and cash-flow destinations retain the selected
  transaction scope. Goal progress is explicitly current, not reconstructed
  history. Budget performance shows each cycle as of today or the selected range's end,
  whichever is earlier. Its posted amounts exclude future entries/excluded
  accounts, retain non-date transaction filters and retain prior filtered history
  for signed rollover. Cycle dates and this scope are shown on screen; prior edits
  to limits are not reconstructed.
- Forecast previews never save transactions. Upcoming uses saved future entries
  and enabled, non-archived recurrence occurrences, honors end dates, and avoids
  double-counting a materialized rule/date. The Home trend's dashed upcoming
  series is a schedule-only projection, **not** a prediction or bank balance.
  It includes pending occurrences later today. Calendar heatmap counts include
  saved future records, which are labeled as scheduled.
- Actual/prior/scheduled line series, daily bars, doughnut segments and budget
  pace are supplied by these records. Charts have point inspection and accessible
  increase/decrease actions; monetary charts respect Hide amounts. No random
  chart paths, copied numeric totals, artificial user ratings, credit scores or
  fabricated medical/AI assessments are used.

## Budget help is implemented

- Expense allowances and income targets are persisted independently.
- Automatic matching supports selected categories, all categories, overall
  exclusions and optional descendants. Parent links are persisted and validated
  for existence, matching category type and absence of cycles.
- Manual mode counts only explicitly linked transactions. Explicit links also
  override automatic category selection. The transaction editor offers budgets
  even with no labels, filters them by income/expense and resets on type changes.
  Recurring processing preserves the chosen budget and tags.
- Daily, week-start-aligned weekly, original-day-anchored monthly, yearly and
  inclusive custom date ranges are supported. Month-end and leap-day anchors do
  not drift. Starts are calendar dates, not accidental time-of-day cutoffs.
- Rollover retains the **signed** previous allowance minus matched usage, so
  overspending reduces the next allowance. For income targets, unmet targets
  increase the next target and surplus reduces it. Custom ranges do not repeat.
  The calculation is bounded by record count rather than iterating a century of
  daily periods. Each plan counts its own matches, so overlapping plans can count
  the same record in their aggregate usage.
- Saved future entries reserve part of an active budget allowance; its chart
  plots only posted activity and distinguishes future dates. Projections of an
  unsaved recurring occurrence do not spend the budget before processing it.
- Before a plan starts, its first anchored period is shown as Upcoming, not a
  spendable allowance in a period before its start. Historical Budget Performance
  identifies plans that had not started in the selected period.
- Show Budget persists the Home-carousel preference. Deleting a budget clears
  links but preserves transactions and recurrence history. Income targets cannot
  earn the expense-only balanced-budget badge just by remaining below target.

## Preservation and adaptations

The Tink name/head/sparkle identity and licensed offline TinkRounded/Noto fonts
are retained. The unknown proprietary reference font and timing cannot honestly
be certified pixel-identical. No simulated OS status bars or private photo/chat
bubbles are added. Counts and milestones use Tink's real existing records/catalog,
not the screenshot's particular totals or 37-badge denominator.

Existing account skins/images and the grouped tablet/master-detail account view
remain accessible. Entered last digits are optional, at most four, and never a
full bank/card number. Linked-account labels do not merge balances or connect a
bank. Advanced reports, longer comparisons, CSV, Pro-simulated PDF/printing,
filters and existing destinations are retained alongside the new primary view.

UI revision 3 appends the four newly introduced Home sections to Batch 1 settings
once, without reordering saved cards or changing hidden cards/custom navigation.
Current-revision layouts remain exactly as saved. Demo remains memory-only and
exit remains available on deep routes. The 14-step tour still mounts real feature
widgets in independent providers. Editor validation/save/publication and awaited
route/controller disposal are retained.

Finite chart/ring/wave transitions honor reduced motion. Narrow/large text and
RTL are regression-tested; contrast figures describe specific pairs, not a blanket
accessibility certification. Dynamic/custom tints still need contextual checks.
Data and backups remain unencrypted; PIN/biometrics are interface locks, not
storage encryption. Pro is a persisted local simulation, never a payment.

## Verification status

- [Source check 42165662511](https://github.com/Shitwitt/MoneyMate/actions/runs/42165662511/job/127721439255)
  at `3fe13ab`: **PASS** — strict, non-mutating SDK formatting; localization
  generation; analyzer; the complete Flutter suite; calendar/DST reruns; Python
  regressions; and runnable source packaging. Flutter stable 3.47.9 is pinned.
- Coverage includes budget hierarchy/type/modes/period anchors and signed
  rollover, future starts, manual links without labels, account metadata,
  reporting exclusions/manual FX, retained filtered rollover history, read-only
  recurring projection, 320px / 160% LTR and RTL traversal of all five financial
  reports and primary screens, chart inspection/privacy, and persistence failure
  rollback. The 14-step live tour and full Home traversal pass.
- Calendar date targets retain at least 48px width/height and use contextual
  black/white date ink. Additional regression coverage now verifies 48px
  icon-only dock targets and the functional New → layout shortcut. Tracked rings
  use finite thicker status-colored waves; income achievement is not treated as
  expense overspending. The tablet navigation scale also honors reduced motion.
- The first Batch 2 browser attempt compiled successfully and reported **no app
  runtime/layout errors**, but its new inspector timed out on a Flutter heading
  exposed as an ARIA group instead of DOM text. It is **not** a browser pass.
  The driver now handles either representation, frames the section below the
  toolbar, and asserts that account/budget swipes actually change visible pages.
  First Home/grid renders were reviewed; the complete browser rerun is pending.
- Full-size fictional-data captures remain artifacts. Twelve bounded review
  thumbnails plus a failure thumbnail fit within the API annotation budget.
- Both native jobs are **SKIPPED** under the build hold. **No Batch 2 APK, Android
  device, signing, installation or iOS verification is claimed.**
