import React from 'react';
import { renderToString } from 'react-dom/server';

import { demoStore } from '../src/data/demoStore.js';
import App from '../src/App.jsx';

function normalize(html) {
  return html
    .replace(/<!--.*?-->/g, '')
    .replace(/&#x27;/g, "'")
    .replace(/&#39;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&#x2F;/g, '/');
}

const render = () => normalize(renderToString(React.createElement(App)));

let fails = 0;
function check(label, needles) {
  const html = render();
  let miss = 0;
  needles.forEach((n) => {
    if (!html.includes(n)) {
      console.log(`  MISS [${label}] ${n}`);
      miss += 1;
    }
  });
  console.log(`${label}: ${needles.length - miss}/${needles.length} ok (${html.length} chars)`);
  fails += miss;
  return html;
}

const state = () => demoStore.getState();

/* ============================================================
   1 — LOAN DETAILS
   ============================================================ */
demoStore.go('loanDetails', { id: 'ln-car' });
check('loanDetails', [
  'Car Loan',
  'Lending',
  '377 days left',
  'Amount Lent',
  '$17,336.00',
  'Repayment Progress',
  'Paid',
  '$421.00',
  'Amount',
  '$16,619.00',
  'Total',
  '$17,757.00',
  'Loan Details',
  'Lent to',
  'Alice',
  'Start date',
  '08/13/2026',
  'End date',
  '11/19/2027',
  'Notes',
  'Demo loan for Car Loan',
  'Mark as Done',
  'Payment History',
  // the six linked rows
  'Bi-weekly pay',
  '$372.00',
  'Transfer 107',
  '$76.00',
  'Morning coffee',
  '$391.00',
  '$287.50',
  'Monthly salary',
  '$49.00',
  'Metro card',
  '$290.00',
  'Fast food order',
  '£457.00',
  '$578.48',
  // meta lines + chips
  '1:03 AM',
  'Feb 15',
  'Cash Wallet',
  'Car Loan',
  'Food Budget',
  'Transportation Budget',
  // fab
  'Edit',
]);

/* paid/charges derive from the ledger */
const car = state().transactions.filter((t) => t.loanId === 'ln-car');
console.log('  car linked rows:', car.length);
console.log('  charges:', car.filter((t) => t.type === 'expense' && !t.transfer).length);

/* mark as done pays the remainder and completes the loan */
demoStore.markLoanDone('ln-car');
const after = state();
const carMath = after.transactions
  .filter((t) => t.loanId === 'ln-car')
  .reduce((a, t) => a + (t.type === 'income' && !t.transfer ? t.amount : 0), 0);
console.log(`  paid after done: ${carMath.toFixed(2)} (want 17757.00)`);
if (Math.abs(carMath - 17757) > 0.001) {
  console.log('  MISS [markDone] paid did not reach the total');
  fails += 1;
}
check('loanDetails done', ['$0.00', 'Mark as Done']);
if (after.loans.find((l) => l.id === 'ln-car')?.status !== 'completed') {
  console.log('  MISS [markDone] loan status did not become completed');
  fails += 1;
}
demoStore.go('loans');
check('summary after markDone', ['$0.00', '-$24,106.00', '$24,106.00', 'Net Loan Balance']);
demoStore.setLoansTab('completed');
check('markDone completed tab', ['Car Loan', '100%', 'Paid']);

demoStore.resetDemo();
demoStore.go('loanDetails', { id: 'ln-car' });

/* ============================================================
   2 — QUICK LOG (+)
   ============================================================ */
demoStore.openQuickLog(true);
check('quickLog', ['Log transaction', 'Received from', 'outstanding', 'Full remaining', 'Half']);
demoStore.recordLoanPayment('ln-car', 100, { account: 'HDFC Bank' });
const paidNow = state()
  .transactions.filter((t) => t.loanId === 'ln-car')
  .reduce((a, t) => a + (t.type === 'income' && !t.transfer ? t.amount : 0), 0);
console.log(`  paid after +100: ${paidNow.toFixed(2)} (want 521.00)`);
if (Math.abs(paidNow - 521) > 0.001) fails += 1;
check('afterPayment', ['$521.00', '$17,236.00']);
demoStore.resetDemo();

/* ============================================================
   3 — LOAN EDITOR
   ============================================================ */
demoStore.go('loanEditor', { id: 'ln-car' });
check('loanEditor', [
  'Lending',
  'Borrowing',
  'Car Loan',
  '16619.0',
  'Demo loan for Car Loan',
  'Start date',
  '08/13/2026',
  'End date',
  '11/19/2027',
  'Person',
  'Alice',
  'Account',
  'Kotak Mahindra Bank',
  'HDFC Bank',
  'Cash Wallet',
  'Savings Account',
  'Category',
  'Update Loan',
  'Colors',
  'Primary',
  'Accent',
  'Wheel',
  '0xFF3F51B5',
]);
/* lending shows expense categories, never income ones */
const lendHtml = render();
['Bills & Utilities', 'Education', 'Transportation'].forEach((n) => {
  if (!lendHtml.includes(n)) {
    console.log(`  MISS [loanEditor lending] ${n}`);
    fails += 1;
  }
});

/* ============================================================
   4 — BORROWING SWAPS THE CATEGORY SET
   ============================================================ */
demoStore.saveLoan({
  id: 'ln-test',
  title: 'Test Loan',
  kind: 'borrowing',
  person: 'Bob',
  amount: 500,
  account: 'HDFC Bank',
  category: 'Salary',
  start: '2026-01-01',
  end: '2026-12-31',
  notes: '',
  color: '#3F51B5',
  accent: '#FF9C27',
});
demoStore.go('loanEditor', { id: 'ln-test' });
const borrowHtml = check('loanEditor borrowing', [
  'Business',
  'Freelance',
  'Investments',
  'Other Income',
  'Salary',
  'Update Loan',
]);
/* when editing a borrowing loan the income set must replace the expense set */
console.log(
  `  borrowing shows Business: ${borrowHtml.includes('Business')} / hides Food & Dining: ${!borrowHtml.includes(
    'Food & Dining',
  )}`,
);
if (borrowHtml.includes('Food & Dining')) {
  console.log('  MISS [loanEditor] expense categories leaked into borrowing');
  fails += 1;
}
demoStore.deleteLoan('ln-test');

/* new loan = "Add Loan" */
demoStore.go('loanEditor', {});
check('loanEditor new', ['Add Loan']);

/* ============================================================
   5 — GOALS LIST
   ============================================================ */
demoStore.go('goals');
check('goals', [
  'Goals',
  '2/2',
  '2 goals',
  'Active',
  'Completed',
  'Archived',
  'Emergency Fund',
  '12/26/2026',
  '48 days',
  'Saved',
  '$5,950.00',
  'Remaining',
  '$29,654.00',
  'Goal: $35,604.00',
  '17%',
  'Vacation Fund',
  '07/25/2027',
  '259 days',
  '-$947.00',
  '$48,642.00',
  'Goal: $47,695.00',
  '-2%',
]);

/* tabs switch the visible set */
demoStore.setGoalsTab('completed');
check('goals completed', ['2/2', 'No completed goals yet', 'Completed']);
demoStore.setGoalsTab('archived');
check('goals archived', ['2/2', 'No archived goals yet']);
demoStore.setGoalsTab('active');

/* status changes move a goal between tabs and update the count */
demoStore.setGoalStatus('gl-vacation', 'completed');
demoStore.setGoalsTab('completed');
check('goals after status change', ['Vacation Fund', '1 goal', '2/2']);
demoStore.setGoalStatus('gl-vacation', 'active');
demoStore.setGoalsTab('active');

/* sorting by saved puts the biggest first */
demoStore.setGoalSort('saved');
const sortHtml = render();
console.log(`  sort by saved -> Emergency before Vacation: ${sortHtml.indexOf('Emergency Fund') < sortHtml.indexOf('Vacation Fund')}`);
demoStore.setGoalSort('name');

/* ============================================================
   6 — HOW GOALS WORK
   ============================================================ */
demoStore.openGoalsHow(true);
check('howGoals', [
  'How Goals Work',
  'Goals help you save toward specific targets by tracking your progress.',
  'Goal Types',
  'Set a target amount and deadline for anything you want to save for.',
  'Linked Account',
  'Progress',
  'Status',
  'Tracking',
  'Got it',
]);
demoStore.openGoalsHow(false);

/* ============================================================
   7 — GOAL DETAILS
   ============================================================ */
demoStore.go('goalDetails', { id: 'gl-emergency' });
check('goalDetails', [
  'Goal Details',
  'Expense Goal',
  'Emergency Fund',
  '17% completed',
  '$5,950.00 by $35,604.00',
  'Started',
  '12/26/2025',
  'End date',
  '12/26/2026',
  'Remaining',
  '1 month left',
  'Still needed',
  '$29,654.00',
  'Transactions',
  'Sat, Dec 19',
  '$0.00',
  'Sat, Nov 28',
  '-$226.00',
  'Transfer 64',
  'Drive-through meal',
  '$226.00',
  'Transfer 1',
  'Daily',
  'Weekly',
  'Monthly',
  'Yearly',
  'Edit',
]);

/* period tabs regroup the ledger */
demoStore.setGoalDetailsTab('monthly');
const monthHtml = render();
console.log(`  monthly grouping: ${monthHtml.includes('December 2026')} ${monthHtml.includes('November 2026')}`);
if (!monthHtml.includes('December 2026')) {
  console.log('  MISS [goalDetails monthly] December 2026 group');
  fails += 1;
}
demoStore.setGoalDetailsTab('yearly');
if (!render().includes('2026')) {
  console.log('  MISS [goalDetails yearly]');
  fails += 1;
}
demoStore.setGoalDetailsTab('daily');

/* a contribution recomputes saved + progress */
demoStore.addGoalTransaction('gl-emergency', { amount: 1546, type: 'income', date: '2026-11-07' });
check('goalContribution', ['$7,496.00', '21%']);
demoStore.resetDemo();

/* ============================================================
   8 — GOAL EDITOR
   ============================================================ */
demoStore.go('goalEditor', { id: 'gl-emergency' });
check('goalEditor', [
  'Goal',
  'Emergency Fund',
  '35604.0',
  '12/26/2025',
  '12/26/2026',
  'Select account',
  'Kotak Mahindra Bank',
  'Colors',
  '0xFF9C27',
  'Update Goal',
]);
/* the checkmark swatch tracks the goal's own primary */
console.log(`  goal primary swatch present: ${render().includes('#9C27B0')}`);
if (!render().includes('#9C27B0')) {
  console.log('  MISS [goalEditor] primary colour not applied');
  fails += 1;
}
demoStore.go('goalEditor', {});
check('goalEditor new', ['Add goal', 'Ex: Trip to Japan', '0xFFF443']);

/* ============================================================
   9 — EXIT DEMO DIALOG
   ============================================================ */
demoStore.go('home');
demoStore.exitDemo();
check('exitDemo', [
  'Leave the demo?',
  'Start Fresh',
  'My Own Data — clears every demo record',
  'Keep Demo Data & Edit Freely',
  'Everything stays, fully editable',
  'Cancel',
]);
demoStore.openExitDialog(false);

/* keep demo data -> records survive */
const before = state().loans.length;
demoStore.exitDemo();
demoStore.keepDemoData();
console.log(`  keep demo: ${state().loans.length} loans (was ${before})`);
if (state().loans.length !== before) fails += 1;

/* start fresh -> everything clears and totals zero out */
demoStore.exitDemo();
demoStore.startFresh();
const fresh = state();
const empty =
  fresh.transactions.length === 0 &&
  fresh.loans.length === 0 &&
  fresh.goals.length === 0 &&
  fresh.assets.length === 0 &&
  fresh.bills.length === 0 &&
  (fresh.budgets?.items?.length || 0) === 0 &&
  (fresh.accounts?.list?.length || 0) === 0 &&
  fresh.upcoming.length === 0 &&
  fresh.templates.length === 0 &&
  fresh.overview.reports.count === 0 &&
  fresh.overview.labels.count === 0;
console.log(`  start fresh empties records: ${empty}`);
if (!empty) fails += 1;
check('freshHome', ['₹0.00']);
demoStore.resetDemo();

/* ============================================================
   10 — STEP 1–3 STILL INTACT
   ============================================================ */
demoStore.go('home');
check('home', ['₹8,55,933.46', 'Overview', 'Goals']);
demoStore.go('assets');
check('assets', ['$736,114.85']);
demoStore.go('billSplitter');
check('billSplitter', ['Bill Splitter']);
demoStore.go('loans');
check('loans', ['Loans', 'Net Loan Balance', '$41,442.00']);

console.log(fails === 0 ? '\nALL STEP 4 CHECKS PASSED' : `\n${fails} FAILURES`);
if (fails) process.exit(1);
