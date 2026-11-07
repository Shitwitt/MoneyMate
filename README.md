# MoneyMate

A pixel-perfect personal finance / expense manager modelled on the **Paisa**
expense manager (Material Design 3 "Material You" warm terracotta theme).

**Step 1 — Home Dashboard** is complete: hero balance card, all 17 Bento‑grid
widgets, templates row, calendar heatmap, trend chart, track-budgets carousel,
multi-currency upcoming transactions and the floating navigation system.

**Step 2 — Accounts, Reports & Budgets** is complete: swipeable accounts screen,
Reports & Analytics (insights, bar/line chart, filter menus, donut breakdown,
Financial Reports directory), Budgets overview with tinted summary pills, the
*How Budgets Work* modal and the single-budget detail view.

**Step 3 — Assets, Bill Splitter & Loans** is complete: asset portfolio with a
dual-grid colour editor, a cent-exact bill splitter (equal / percentage /
custom) with participant payment tracking and net balances, and a loan manager
with partial payments, auto-completion and due-date countdowns — plus an
expressive dark theme engine.

## Run

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # production bundle in dist/
```

## Stack

- **React 18 + Vite 5** — mobile-first, `max-width: 460px` app shell
- **Plus Jakarta Sans** (self-hosted via `@fontsource`) — Material You typography
- **lucide-react** icons
- **`demoStore`** — a tiny observable store (`useSyncExternalStore`) that is the
  single source of truth for every number on the screen, ready for the
  Accounts / Reports / Search / Add‑Transaction screens in later steps.

## Layout map

| Area | File |
| --- | --- |
| Shell + section order | `src/App.jsx` |
| Top bar (Exit Demo, New, layout, avatar) | `src/components/TopBar.jsx` |
| Contextual greeting (interactive tokens) | `src/components/Greeting.jsx` |
| Hero balance + privacy toggle | `src/components/HeroCard.jsx` |
| 17-card Bento grid | `src/components/BentoGrid.jsx` |
| Last-30-days sparkline | `src/components/Sparkline.jsx` |
| Templates quick-add row | `src/components/Templates.jsx` |
| Calendar heatmap | `src/components/CalendarHeatmap.jsx` |
| Trend chart (Oct / this month / upcoming) | `src/components/TrendChart.jsx` |
| Track-budgets carousel | `src/components/BudgetCarousel.jsx` |
| Upcoming transactions (INR / EUR / GBP) | `src/components/UpcomingTransactions.jsx` |
| FAB + floating pill nav | `src/components/FloatingNav.jsx` |
| Step 2 seed data | `src/data/step2Data.js` |
| Accounts screen | `src/views/AccountsView.jsx` |
| Reports & Analytics screen | `src/views/ReportsView.jsx` |
| Budgets overview | `src/views/BudgetsView.jsx` |
| Single budget detail | `src/views/BudgetDetailView.jsx` |
| How Budgets Work modal | `src/views/HowBudgetsModal.jsx` |
| Step 2 styles | `src/styles/step2.css` |
| Financial engine (pure maths) | `src/data/engine.js` |
| Step 3 seed data | `src/data/step3Data.js` |
| Assets view + editor + modal | `src/views/AssetsView.jsx`, `AssetEditorView.jsx`, `HowAssetsModal.jsx` |
| Bill splitter | `src/views/BillSplitterView.jsx`, `BillDetailsView.jsx`, `BillEditorView.jsx`, `BillModals.jsx` |
| Loans | `src/views/LoansView.jsx`, `LoanDetailsView.jsx`, `LoanEditorView.jsx`, `HowLoansModal.jsx` |
| Theme tokens (light + dark) | `src/styles/theme3.css` |
| Step 3 styles | `src/styles/step3.css` |
| State store + Indian formatting engine | `src/data/demoStore.js` |
| Design tokens | `src/styles/tokens.css` |
| Component styles | `src/styles/app.css` |

## Number formatting engine

All money renders through helpers in `src/data/demoStore.js`:

| Helper | Output |
| --- | --- |
| `fmtFull(855933.46)` | `₹8,55,933.46` |
| `fmtCompact(1480000)` | `₹14.8L` |
| `fmtCompact(14800)` | `₹14.8K` |
| `fmtCompact(-79100)` | `-₹79.1K` |
| `fmtShort(24900)` | `₹24.9K` |
| `fmtShort(0)` | `₹0.0` |
| `fmtThousands(206)` | `₹206` |

Full amounts use the Indian grouping system (last 3 digits, then pairs).
Foreign entries convert at the seed rates (EUR → ₹295.65, GBP → ₹193.67).

## Interactions wired up in Step 1

- **Eye / eye-off** on the hero card toggles privacy mode → every currency on
  the screen masks to `₹••••••`.
- **Budgets bento card** — tap *or* swipe switches between the count slide and
  the Total / Remaining / Spent breakdown; pagination dots follow.
- **Track budgets carousel** — tap or swipe between Food and Transportation
  budget cards with a sliding transition and dots (tapping a card opens its
  budget detail).
- **Routing** — `demoStore.go(view, params)` drives `home | accounts | reports |
  budgets | budgetDetail`; bottom nav, bento cards, carousel cards, back arrows
  and the browser/Android back button all go through it.
- **Reports** — month strip, chart mode toggle (bars/line), Expense⇄Income and
  Category dropdown (with locked Account/Label/Person/Places rows), and the
  breakdown accordion all update from the store.
- Greeting tokens (backup, notification, rating, recurring) toggle state /
  raise contextual toasts; the notification token flips its own boolean.
- Bottom nav, FAB, chevrons and "See all" buttons raise placeholder toasts and
  route through the store, so Step 2 only needs to swap in real screens.

## Android

The app ships as a Capacitor project. `npm run android:apk` builds locally;
`.github/workflows/build-apk.yml` assembles the debug APK in CI, publishes it to
the `apk-builds` branch and attaches it as a workflow artifact.
See `INSTALL-APK.md`.

## Testing

Three layers, all runnable offline:

```bash
node scripts/engine.test.mjs          # 66 pure maths assertions
                                      #   (largest-remainder splitting, loan
                                      #   countdown/DST, portfolio, ramps)

# render + interaction checks per step
npx vite build --ssr scripts/smoke3.jsx --outDir .smoke && node .smoke/smoke3.js
```

`smoke.jsx` (24), `smoke2.jsx` (141) and `smoke3.jsx` (~120) server-render every
screen and drive the interactive flows (mark as paid, partial payments, edits,
theme toggle) against the spec's exact strings.

## Money maths notes

All currency is held in **integer cents** and proportional splits use the
**largest-remainder (Hare–Niemeyer)** method, so participant shares always sum
to the bill total with zero drifting pennies. Loan day-countdowns compare UTC
midnights (DST- and leap-year-safe). See `src/data/engine.js`.

## Next steps

Step 3+ will add Search and the Add-Transaction flow on top of `demoStore`.
