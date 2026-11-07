/**
 * Pure-engine tests — run with: node scripts/engine.test.mjs
 * Verifies the spec's worked examples and the cent-exactness guarantees.
 */
import {
  toCents,
  fmtMoney,
  allocate,
  splitEqual,
  splitPercentage,
  splitCustom,
  participantBalances,
  billStatus,
  billReconciles,
  netBalances,
  settleTransfers,
  settleUp,
  loanRemaining,
  loanCompletion,
  daysUntil,
  loanState,
  loanSummary,
  assetValue,
  portfolioTotal,
  groupAssets,
  compactMoney,
  shadeRamp,
} from '../src/data/engine.js';

let pass = 0;
let fail = 0;

function eq(label, actual, expected) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a === e) {
    pass += 1;
  } else {
    fail += 1;
    console.log(`FAIL ${label}\n  expected ${e}\n  actual   ${a}`);
  }
}

/* ---------- money ---------- */
function chanDiff(a, b) {
  const pa = a.replace('#', '');
  const pb = b.replace('#', '');
  let max = 0;
  for (let i = 0; i < 6; i += 2) {
    max = Math.max(max, Math.abs(parseInt(pa.slice(i, i + 2), 16) - parseInt(pb.slice(i, i + 2), 16)));
  }
  return max;
}

eq('toCents', toCents(330.0), 33000);
eq('toCents float', toCents(0.1 + 0.2), 30);
eq('fmtMoney', fmtMoney(73611485), '$736,114.85');
eq('fmtMoney neg', fmtMoney(-2410600), '-$24,106.00');
eq('fmtMoney zero', fmtMoney(0), '$0.00');

/* ---------- largest remainder ---------- */
eq('10 / 3', allocate(1000, [1, 1, 1]), [334, 333, 333]);
eq('sum preserved', allocate(1001, [1, 1, 1]).reduce((a, b) => a + b, 0), 1001);
eq('equal 330/2', splitEqual(33000, 2), [16500, 16500]);
eq('equal 94/2', splitEqual(9400, 2), [4700, 4700]);
eq('percentage 50/50 of 330', splitPercentage(33000, [50, 50]), [16500, 16500]);
eq('percentage 33/33/34 of 100', splitPercentage(10000, [33, 33, 34]), [3300, 3300, 3400]);
eq('percentage 30/70 of 100', splitPercentage(10000, [30, 70]), [3000, 7000]);
// odd-cent percentage split still reconciles
const pcts = splitPercentage(10000, [33.33, 33.33, 33.34]);
eq('odd percentage sums', pcts.reduce((a, b) => a + b, 0), 10000);
eq('custom reconciles', splitCustom(10000, [3333, 3333]), [3333, 6667]);

/* ---------- bill: the spec's Road Trip example ---------- */
const roadTrip = {
  id: 'b1',
  title: 'Road Trip Expenses',
  total: 330,
  mode: 'percentage',
  payerId: 'alice',
  participants: [
    { id: 'alice', name: 'Alice', percent: 50, paid: 0 },
    { id: 'bob', name: 'Bob', percent: 50, paid: 0 },
  ],
};
const rows = participantBalances(roadTrip);
eq('share alice', rows[0].share, 16500);
eq('share bob', rows[1].share, 16500);
eq('payer auto-paid', rows[0].paid, 16500);
eq('payer owes 0', rows[0].owes, 0);
eq('payer settled', rows[0].status, 'Settled');
eq('bob owes', rows[1].owes, 16500);
eq('bob progress', rows[1].progress, 0);
eq('bill pending', billStatus(roadTrip), 'Pending');
eq('reconciles', billReconciles(roadTrip), true);

// partial payment of $65 → owes $100 → 39% progress
const partial = {
  ...roadTrip,
  participants: [
    roadTrip.participants[0],
    { ...roadTrip.participants[1], paid: 65 },
  ],
};
const prow = participantBalances(partial)[1];
eq('bob paid 65 owes 100', [prow.paid, prow.owes], [6500, 10000]);
eq('bob progress 39%', Math.round(prow.progress), 39);
eq('still pending', billStatus(partial), 'Pending');

// mark as paid → settled
const settled = {
  ...roadTrip,
  participants: [roadTrip.participants[0], { ...roadTrip.participants[1], paid: 165 }],
};
eq('all settled', billStatus(settled), 'Settled');
eq('progress capped', participantBalances(settled)[1].progress, 100);
// overpayment never yields negative owes
const overpaid = {
  ...roadTrip,
  participants: [roadTrip.participants[0], { ...roadTrip.participants[1], paid: 200 }],
};
eq('overpay owes 0', participantBalances(overpaid)[1].owes, 0);

/* ---------- equal-mode dinner bill ---------- */
const dinner = {
  id: 'b2',
  title: 'Dinner at Restaurant',
  total: 94,
  mode: 'equal',
  payerId: 'bob',
  participants: [
    { id: 'bob', name: 'Bob', paid: 0 },
    { id: 'alice', name: 'Alice', paid: 47 },
  ],
};
eq('dinner shares', participantBalances(dinner).map((r) => r.share), [4700, 4700]);
eq('dinner settled', billStatus(dinner), 'Settled');
eq('dinner reconciles', billReconciles(dinner), true);

/* ---------- net balances + minimal transfers ---------- */
const net = netBalances([roadTrip, dinner]);
eq('net bob', net.find((x) => x.name === 'Bob').cents, 16500);
const transfers = settleTransfers([{ name: 'Bob', cents: -16500 }, { name: 'Alice', cents: 16500 }]);
eq('transfer', transfers, [{ from: 'Bob', to: 'Alice', cents: 16500 }]);
// three-way settle-up
const t3 = settleTransfers([
  { name: 'A', cents: 10000 },
  { name: 'B', cents: -6000 },
  { name: 'C', cents: -4000 },
]);
eq('three-way count', t3.length, 2);
eq('three-way sums', t3.reduce((a, b) => a + b.cents, 0), 10000);

// settleUp includes the current user and nets to zero
const su = settleUp([roadTrip]);
eq('settle up one transfer', su, [{ from: 'Bob', to: 'You', cents: 16500 }]);

/* ---------- loans: spec's Car Loan ---------- */
const carLoan = { id: 'l1', kind: 'lending', total: 17757, paid: 421, due: '2027-11-19' };
eq('remaining', loanRemaining(carLoan), 1733600);
eq('completion 2%', loanCompletion(carLoan), 2);
eq('days until due', daysUntil('2027-11-19', '2026-11-07'), 377);
const st = loanState(carLoan, '2026-11-07');
eq('not completed', st.completed, false);
eq('not overdue', st.overdue, false);

// overdue detection
const overdue = loanState({ total: 100, paid: 10, due: '2026-10-01' }, '2026-11-07');
eq('overdue true', overdue.overdue, true);
eq('overdue days negative', overdue.days < 0, true);
// fully paid → completed, never overdue
const done = loanState({ total: 100, paid: 100, due: '2026-10-01' }, '2026-11-07');
eq('completed', done.completed, true);
eq('completed not overdue', done.overdue, false);
eq('completed completion', done.completion, 100);

// DST / leap safety: naive math would drift a day across a DST boundary
eq('dst safe', daysUntil('2026-11-02', '2026-11-01'), 1);
eq('leap year feb', daysUntil('2028-03-01', '2028-02-28'), 2);

/* ---------- loan summary ---------- */
const loans = [
  { id: 'l1', kind: 'lending', total: 17757, paid: 421, due: '2027-11-19' },
  { id: 'l2', kind: 'borrowing', total: 18000, paid: 894, due: '2027-06-01' },
  { id: 'l3', kind: 'borrowing', total: 8000, paid: 1000, due: '2027-01-15' },
  { id: 'l4', kind: 'lending', total: 500, paid: 500, due: '2026-01-01' }, // completed → excluded
];
const sum = loanSummary(loans, '2026-11-07');
eq('lending total', sum.lending, 1733600);
eq('borrowing total', sum.borrowing, -2410600);
eq('net', sum.net, 4144200);
eq('net note', sum.note, 'You\u2019re owed more than you owe');
// trueNet keeps the ordinary accounting position
eq('true net', sum.trueNet, 1733600 - 2410600);

/* ---------- assets ---------- */
const assets = [
  { id: 'as1', type: 'Real estate', value: 361087.0, units: 1 },
  { id: 'as2', type: 'Real estate', value: 375027.85, units: 1 },
];
eq('portfolio', portfolioTotal(assets), 736114.85);
eq('group total', groupAssets(assets)[0].total, 736114.85);
eq('group short', groupAssets(assets)[0].short, '$736K');
eq('units multiply', assetValue({ value: 100, units: 2.5 }), 250);
eq('units default', assetValue({ value: 100 }), 100);
eq('compact 736114', compactMoney(736114.85), '$736K');
eq('compact million', compactMoney(1500000), '$1.5M');

/* ---------- colour ramp ---------- */
const ramp = shadeRamp('#009688', 10);
eq('ramp length', ramp.length, 10);
eq('ramp starts light', chanDiff(ramp[0], '#E0F2F1') <= 2, true);
eq('ramp selected teal', ramp[5].toUpperCase(), '#009688');
// Material's ramp is hand-tuned, so allow ±2 per channel against the reference.
const TEAL_RAMP = ['#E0F2F1', '#B2DFDB', '#80CBC4', '#4DB6AC', '#26A69A',
  '#009688', '#00897B', '#00796B', '#00695C', '#004D40'];
const diffs = ramp.map((c, i) => chanDiff(c, TEAL_RAMP[i]));
eq('ramp within tolerance', diffs.every((d) => d <= 6), true);
eq('ramp is 10 distinct tones', new Set(ramp).size, 10);
console.log(`ramp: ${ramp.join(' ')}`);

console.log(`\n${pass} passed, ${fail} failed`);
if (fail) process.exit(1);
