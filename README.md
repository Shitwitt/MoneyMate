# MoneyMate

A mobile-first personal finance / expense manager modelled on the **Paisa**
expense manager, with a Material Design 3 warm-terracotta theme and an
expressive dark theme for the bill / loan / goal workspaces.

## Live overhaul — current behaviour

Demo mode is gone. MoneyMate now boots with editable sample records for
**Raj**, stored in one reactive store and persisted to `localStorage` under
`moneymate.live.v1` on every change. There is no `✕ Exit Demo` pill, no
demo ribbon, and no `Demo User`. The top-right profile icon on every screen
opens a profile modal for **User Name**, **Base Currency** (`₹ / $ / € / £`),
an editable liabilities offset, **Restore sample records**, and
**Reset / Clear All Data** (which empties every record and makes all balances
`0`).

Every array — `accounts`, `transactions`, `categories`, `budgets`, `assets`,
`bills`, `loans`, `goals`, `templates`, `people`, `places`, `labels` — is
editable and deletable. Every input is controlled and every button performs a
real state mutation. Balances, hero totals, monthly income/expense, category
totals, budget/loan/goal progress, report values and all charts are derived
from live state on each render.

### Universal Add / Edit Transaction

Any floating `+` or transaction row opens the universal transaction editor:
`Expense | Income | Transfer`, title, `type="number" step="0.01"` amount,
currency with automatic conversion to the base currency, date and time,
dynamic account / from / to selectors, category with inline `⊕ Add Category`,
optional Budget / Loan / Goal links, Person / Place / Label links with inline
create actions, and notes. Editing shows a red delete action that reverses the
balance impact. Future-dated rows appear in **Upcoming transactions** on Home.

### Editors

Account, budget, template, asset, bill, loan and goal editors are all wired to
live records. Budget maths is period-aware: `Spent = matching transactions`,
`Remaining = Limit − Spent`, `Used% = round(Spent / Limit × 100)` and
`Daily Safe Spend = max(0, Remaining) / max(1, Days Left)`. Loan repayments /
charges and goal deposits / withdrawals append linked ledger rows and recompute
paid, total, remaining, saved, still-needed and progress. Bill participant
payments update `Paid`, `Owes`, progress, the `[✓ Settled]` badge and the
Active / Settled tabs.

### Interactive SVG charts

`src/components/charts/Interactive.jsx` is the shared chart system. Every
visualization supports touch-hold/drag (`onTouchStart` / `onTouchMove`) and
mouse hover/move (`onMouseMove`) scrubbing, with floating tooltips and
crosshairs:

1. Home 7-day capsule bars (this week vs last week)
2. Home last-30-days stepped green area sparkline
3. Calendar heatmap (tap/hover summary + add-transaction-on-date)
4. Cumulative monthly trend (last month, this month, projected)
5. Dynamic circular rings (`strokeDashoffset = C − pct/100 × C`)
6. Sinusoidal wavy progress clipped to exact percentage
7. Reports dual-mode bar / node-line chart + multi-dimension donut
   (`Category / Account / Label / Person / Places`)
8. Budget Detail pace chart (actual, ideal pace, limit)

The Reports month pills (`Nov 26 … Jul 26`) filter every report value, insight,
chart and donut slice; the `Expense ▾` toggle switches live Expense / Income
data. Donut slices and breakdown rows expand and update the centre readout.

## Run

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # production bundle in dist/
npm test         # pure engine + live-state/localStorage tests
```

## Stack

- **React 18 + Vite 5** — mobile-first, `max-width: 460px` app shell
- **Plus Jakarta Sans** (self-hosted via `@fontsource`)
- **lucide-react** icons
- **`demoStore`** — one observable store with a cached-shallow selector hook;
  pure selectors in `src/data/derive.js` compute all screen values
- **Capacitor 6** — offline Android WebView build

## Layout map

| Area | File |
| --- | --- |
| Shell, route map, modals, toast | `src/App.jsx` |
| Live seed records + default profile | `src/data/liveData.js` |
| Observable store + all CRUD actions | `src/data/demoStore.js` |
| Pure derived selectors / live maths | `src/data/derive.js` |
| Currency conversion + formatting | `src/data/format.js` |
| Shared interactive SVG charts, rings, waves, donut | `src/components/charts/Interactive.jsx` |
| Universal modal suite (transaction, account, budget, profile, payment, etc.) | `src/components/LiveModals.jsx` |
| Clickable transaction row | `src/components/LiveTransactionRow.jsx` |
| Home toolbar / greeting / hero / bento / templates / charts / budgets / upcoming | `src/components/*.jsx` |
| Accounts, Reports, Budgets, Budget Detail, Assets, Asset Editor | `src/views/*.jsx` |
| Bill Splitter, Bill Details, Bill Editor, Loans, Goals editors/details | `src/views/*.jsx` |
| Search screen | `src/views/SearchView.jsx` |
| Warm / dark / modal / chart styles | `src/styles/*.css` |
| Engine tests, live-state tests, SSR smokes | `scripts/*` |

## Number formatting

All money renders through `src/data/format.js` (re-exported by the store):

| Helper | Output |
| --- | --- |
| `fmtFull(855933.46)` | `₹8,55,933.46` |
| `fmtFull(100, 'USD')` | `$100.00` |
| `fmtCompact(1480000)` | `₹14.8L` |
| `fmtCompact(14800)` | `₹14.8K` |
| `fmtCompact(-79100)` | `-₹79.1K` |
| `fmtShort(24900)` | `₹24.9K` |
| `fmtThousands(206)` | `₹206` |

Stored amounts are Numbers; each transaction also carries `baseAmount` in INR,
so changing the base currency re-renders every figure without rewriting data.
Seed exchange rates: INR 1, USD 83.15, EUR 90.2, GBP 105.4 per INR unit.

## State & persistence

`demoStore.set()` persists the user-data slices and notifies subscribers after
every mutation. Transient UI (modals, toasts, route stack) is intentionally not
persisted. `clearAllData()` empties all records and liabilities;
`restoreSampleData()` re-seeds the deterministic sample while keeping the
current name and base currency.

## Testing

```bash
node scripts/engine.test.mjs        # cent-exact pure maths
node scripts/liveData.test.mjs      # live store, currency conversion, localStorage

# server-rendered screen + interaction checks
rm -rf .smoke .smoke2 .smoke3 .smoke4 .live
for f in smoke smoke2 smoke3 smoke4 smokeLive; do
  npx vite build --ssr scripts/$f.jsx --outDir .$f --logLevel error \
    && node .$f/$f.js
done
```

`scripts/smokeLive.jsx` is the comprehensive overhaul suite: it renders every
view and modal, asserts the absence of demo UI, checks all eight interactive
chart surfaces and drives live CRUD for transactions, accounts, budgets,
templates, collections, loans, goals, bills, profile, month filters and reset.
Remove the `.smoke*` / `.live` output directories before each SSR rebuild.

## Android

The app ships as a Capacitor project. `npm run android:apk` builds locally;
`.github/workflows/build-apk.yml` runs the tests, builds the web bundle,
assembles the debug APK in CI, publishes it to the `apk-builds` branch and
attaches it as a workflow artifact. See `INSTALL-APK.md`.
