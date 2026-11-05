# Release / real-device QA checklist

Automated finance, persistence, parsing, backup/security and basic widget tests are in `test/`. The APK and web compilation workflows are the source of truth for a particular revision. Passing tests does not prove every native behavior or edge case. Before trusting a new release with important data:

## Build and install
- Run `flutter analyze`, `flutter test`, both Android workflows and an optimized web build.
- Sideload debug and release APKs on Android 7/API 24 and a current Android release; test gesture navigation/edge-to-edge, keyboard insets and 200% OS font size.
- Sign twice with the SAME persistent keystore, increase version code and install the second with `adb install -r`; verify retained data. Test the expected failure for a different signing key without deleting the only data copy.
- Build iOS on a Mac, configure both targets' team/App Group, archive and test on a real iPhone/iPad. Do not treat a Linux Android build as iOS verification.

## Ledger and isolation
- Empty onboarding; invalid name/amount; demo in a NEW profile; switch/rename/delete inactive and active profiles.
- Income, expense, edit, delete, bulk delete, future/past dates, decimal and expression calculator, repeat-add, template create/edit/apply/remove.
- Same-currency and USD↔JPY/KWD transfers; edit receiving amount; edit/delete transfer and verify BOTH balances. Deny self-transfer and deletion/currency change of used accounts.
- Negative credit opening balance, archived/excluded accounts, optional images; last-active account/last visible category guards.
- Create/change/delete category, labels, people, places; verify counts, references, autocomplete, history filters and all reports.

## Plans and reports
- Weekly/monthly/yearly/custom budgets, 31st, leap year, signed rollover, overspend and month boundaries. Check combined category scope and transfer exclusion.
- Manual, linked-account and tagged-income goal progress; completion confetti, milestones, remove contribution, delete tagged goal. Ensure no net-worth double counting.
- Lent/borrowed loans with/without interest/disbursement, partial/full repayments with/without ledger entry; outstanding balance and net-worth consistency. Deny overpayment.
- Exact/equal/percent/share bills, zero shares, one-cent rounding across many people, one payer, mark settled only once, optional loan conversion, overall net suggestions.
- Assets purchase/value history; update to zero, edits and deletion, avoid double counting investment accounts.
- Recurring all frequencies/intervals, Jan 31→Feb→Mar, leap day, optional end, pause/resume/skip, reminder-only, catch-up once and twice. Check no false promise of closed-app posting.
- Every transaction/report filter, sort, custom date end 23:59, multi-tag totals, line/bar/pie touch, no-data charts, heatmap/week start, historical selection. Hide amounts must hide tooltips too.
- Enforce free limits through repository calls and UI. Unlock/restart, test free downgrade without data loss. Verify advanced/PDF/theme gates.

## Files and recovery
- Camera/gallery receipts up to five; denied permission, >2 MB image, rotation, pinch zoom and share from iPad.
- ZIP and JSON round-trip every model/photo across devices AND currencies; restore multiple profiles with preview. Preserve the current lock; exclude source PIN material. Confirm permissions/notifications reviewed.
- Deliberately corrupt checksum, references, future schema, repeated IDs, invalid amounts/dates and oversized archive. Current database must remain unchanged.
- Reopen Hive after a real process kill. Simulate low storage/write failure. Startup recovery uses previous snapshot or verified import, never silent reset.
- CSV comma/semicolon, UTF-8/BOM, quotes/newlines, mapped headers, invalid rows, unknown accounts/categories, duplicates, same file twice. Check spreadsheet formula neutralization in exported text.
- PDF with long report/tables and names in Hindi/Punjabi/Arabic/Tamil; inspect shaping and printed results. Share/save cancelled, provider unavailable and permission denied; export timestamp is an attempt indicator, not proof of an off-device copy.

## Security / platform services
- Cold-launch PIN, wrong PIN five times, cooldown, PIN change/disable confirmation, resume while another pushed route/editor/receipt viewer is open.
- Biometric success, cancel, unavailable/not enrolled, OS interruption, fallback PIN, app background snapshot, no accidental biometric re-entrancy.
- Notifications explicit opt-in, denied Android 13+, DND/battery policy, reboot, timezone change, 50/80/100 budget thresholds once per period, loan due, reminder-only overdue, master/per-type toggles, profile switching and pending cap.
- Add all three Android widgets, resize, launcher pin unsupported, switch profile/edit/hide/lock/restart. Ensure current totals and privacy. Test all three WidgetKit entries after configuring App Groups.
- `paisa://quick_add`, confirmation add, invalid links, unknown IDs, external calls while locked/onboarding, default silence OFF, explicit allowed silent mode, duplicate initial/stream delivery. Test owned-domain verified links separately if configured.

## Web / accessibility
- Serve the final build over HTTPS, let service-worker installation finish, disconnect then reload. No remote font/renderer request should be necessary. Test update cache cleanup without deleting finance storage.
- Persistence across reload; origin changes and clearing site data explained. Backup restore in another browser. Camera/download/share fallbacks, storage quota failure.
- Phone portrait/landscape, narrow widths, tablet rail/list detail, keyboard-only, screen reader labels, high-contrast/Midnight, 200% system text, reduced motion and Arabic RTL.
- All 13 shell languages and fallback English strings. No chart/tooltip/progress amount leak when amounts are hidden.

Record device model, OS, app version, signing certificate fingerprint and test date in your own release notes. Do not attach private databases, backups or screenshots with real account details to public issues.

## Tink 1.2 editorial/glass design and upgrade checks
- Visit each of the six intro pages by both Next and swipe; Skip, restore, finish real account setup, add a profile without reseeding another, and replay from Help.
- Check native launcher/adaptive/monochrome icons, Android 12 splash, app/permission labels, iOS/web icons and widget branding.
- Verify the same backup format and database/app identifiers; use the same signing key for an actual in-place upgrade.
- Compare Safe to spend with its information sheet, future income/expenses, weekly rules, period start, excluded/savings/investment accounts, goal allocations and due debts. It must never silently stand in for net worth.
- Verify Instrument Serif / Source Serif 4 and all Noto language fallbacks without connectivity. Check tabular figures, money hiding, chart summaries/tooltips and semantic plus/minus/transfer indicators.
- Check 390px and narrow screens with 160–200% text, RTL, keyboard and screen reader; buttons have 48px minimum targets. Examine contrast against actual card backgrounds, not only white.
- Check reduced motion, finite save states, progress/chart entrances, section reordering via the ellipsis handle and local Pro toggles. No animation should prevent completing a form.

- Check all seven account types in all six finishes, long names, opening-balance/currency edits and local images; keep the same account IDs/transactions through backup/restore. No card may imply a real issuer or show a fabricated card number.
- Inspect the pulse information sheet and unknown/zero/future-date cases; do not label it a credit or medical score. Verify exact category amounts and that selectable petals match the list.
- Check thirteen-week activity calendar around spring/fall DST changes. Verify linked cashflow panels describe their independent units and selected month.
- Check the 160% account monthly in/out summaries, home account carousel, separate More control, custom tab ordering, icon-only nav and all theme modes with reduced motion both on and off.
