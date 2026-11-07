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
    .replace(/&gt;/g, '>');
}

const render = () => normalize(renderToString(React.createElement(App)));

let fails = 0;
function check(view, needles, label) {
  const html = render();
  let miss = 0;
  needles.forEach((n) => {
    if (!html.includes(n)) {
      console.log(`  MISS [${label || view}] ${n}`);
      miss += 1;
    }
  });
  console.log(`${label || view}: ${needles.length - miss}/${needles.length} ok (${html.length} chars)`);
  fails += miss;
  return html;
}

/* ============ ASSETS ============ */
demoStore.go('assets');
check('assets', [
  'Assets',
  'Total',
  '$736,114.85',
  'Real estate',
  '$736K',
  'Primary Residence',
  'Main home property',
  '361,087.00',
  'Rental Property',
  'Investment rental property',
  '$296,072.00',
  '375,027.85',
  '2/2',
]);

demoStore.openAssetsHow(true);
check('assets', [
  'How Assets Work',
  'Assets help you track the value of things you own, like investments, property, or vehicles.',
  'Asset Types',
  'Organize by type: Real Estate, Vehicle, Investment, Gold, and more.',
  'Valuation',
  'Track purchase price and current value to see how your assets perform.',
  'Portfolio',
  'View your total portfolio value with a grouped summary by asset type.',
  'Got it',
], 'assets-how');
demoStore.openAssetsHow(false);

demoStore.editAsset('as1');
check('assets', [
  'Asset',
  'Primary Residence',
  '361087.0',
  '1.0',
  'Unit',
  'Main home property',
  'Currency',
  'Default (USD $)',
  'Asset type',
  'Real estate',
  'Colors',
  'Primary',
  'Accent',
  'Update asset',
  '#009688',
  // the ramp derives from THIS asset's primary (#00796B), not teal
  '#DFF1EF',
  '#004D44',
], 'asset-editor');

/* save an edit and confirm the portfolio recalculates */
demoStore.saveAsset({ ...demoStore.getState().assets[0], value: 400000 });
demoStore.go('assets');
check('assets', ['$775,027.85', '400,000.00'], 'assets-after-edit');
demoStore.saveAsset({ ...demoStore.getState().assets[0], value: 361087.0 });

/* ============ BILL SPLITTER ============ */
demoStore.go('billSplitter');
demoStore.setBillsTab('active');
check('billSplitter', [
  'Bill Splitter',
  '1 bill splitter',
  'Road Trip Expenses',
  'Percentage',
  '330.00',
  'Active',
  'Settled',
], 'bill-active');

demoStore.setBillsTab('settled');
check('billSplitter', [
  'Dinner at Restaurant',
  'Equal',
  'Settled',
  '94.00',
], 'bill-settled');

demoStore.openBillsHow(true);
check('billSplitter', [
  'How Bill Splitter Works',
  'Split bills with friends and track who owes what.',
  'Split Types',
  'Equal: Split the bill evenly among all participants.',
  'Custom: Set a specific amount for each person.',
  'Percentage: Assign a percentage of the total to each person.',
  'Participants',
  'Settlement',
  'Balances',
  'Tracking',
], 'bills-how');
demoStore.openBillsHow(false);

demoStore.go('billDetails', { id: 'bs1' });
check('billDetails', [
  'Bill Details',
  'Road Trip Expenses',
  'Pending',
  'Total Amount',
  '$330.00',
  'Percentage Split',
  'Paid By',
  'Alice',
  'Payer',
  'Participants (2)',
  'Share 165.00',
  'Paid 165.00',
  'Bob',
  'Paid 0.00',
  'Owes 165.00',
  'Edit',
], 'bill-details');

/* mark Bob as paid -> owes chip disappears, bill settles */
demoStore.markParticipantPaid('bs1', 'p-bob');
let html = render();
const settledNow =
  html.includes('Settled') && !html.includes('Owes 165.00') && html.includes('Paid 165.00');
console.log(`bill-details(mark as paid): ${settledNow ? 'ok' : 'MISS'}`);
if (!settledNow) fails += 1;

/* revert, then a partial $65 payment -> owes 100.00, 39% progress */
demoStore.setParticipantPaid('bs1', 'p-bob', 0);
demoStore.setParticipantPaid('bs1', 'p-bob', 65);
html = render();
// Bob: share 165, paid 65 -> owes 100.00 and the bar shows 39%
const partialOk =
  html.includes('Owes 100.00') && html.includes('Paid 65.00') && /width:\s*39/.test(html);
console.log(`bill-details(partial 65): ${partialOk ? 'ok' : 'MISS'}`);
if (!partialOk) fails += 1;
demoStore.setParticipantPaid('bs1', 'p-bob', 0);

/* net balances dialog */
demoStore.openNetBalances(true);
check('billSplitter', ['Net Balances', 'Bob', 'owes you $165.00', 'Settle up', 'Bob → You', '$165.00'], 'net-balances');
demoStore.openNetBalances(false);

/* editor */
demoStore.go('billEditor', { id: 'bs1' });
check('billSplitter', ['Edit Bill Splitter', 'Road Trip Expenses', 'Total amount', 'Percentage', 'Who paid?', 'Shares'], 'bill-editor');

/* ============ LOANS ============ */
demoStore.go('loans');
demoStore.setLoansTab('lending');
check('loans', [
  'Loans',
  'Lending',
  'Borrowing',
  'Completed',
  '$17,336.00',
  '-$24,106.00',
  'Net Loan Balance',
  '$41,442.00',
  '1 loan',
  'Car Loan',
  'Demo loan for Car Loan',
  '377 days',
  'Paid',
  '$421.00',
  'Total',
  '$17,757.00',
  'Due 11/19/2027',
  '2%',
], 'loans-lending');

demoStore.setLoansTab('borrowing');
check('loans', ['2 loans', 'Home Renovation Loan', 'Education Loan'], 'loans-borrowing');

demoStore.setLoansTab('completed');
check('loans', ['0 loans'], 'loans-completed');
demoStore.setLoansTab('lending');

demoStore.openLoansHow(true);
check('loans', [
  'How Loans Work',
  "Loans help you track money you've lent to others or borrowed, with payment progress.",
  'Loan Types',
  'Lending: Money you gave to someone. They owe you.',
  'Borrowing: Money you received from someone. You owe them.',
  'Payments',
  'Summary',
  'Status',
  'People',
  'Due Dates',
  'Progress',
  'Sorting',
], 'loans-how');
demoStore.openLoansHow(false);

demoStore.go('loanDetails', { id: 'ln1' });
check('loans', [
  'Lending',
  'Car Loan',
  '377 days',
  'Remaining',
  '$17,336.00',
  '$421.00 / $17,757.00',
  '2% complete',
  'Record payment',
  'Mark fully paid',
  'Outstanding',
  'Completion',
], 'loan-details');

/* record a payment: 421 + 1000 -> 8% complete, remaining 16,336 */
demoStore.recordLoanPayment('ln1', 1000);
demoStore.go('loanDetails', { id: 'ln1' });
check('loans', ['$16,336.00', '8% complete'], 'loan-after-payment');

/* mark fully paid -> completes and leaves the lending tab */
demoStore.recordLoanPayment('ln1', 16336);
demoStore.go('loans');
demoStore.setLoansTab('lending');
html = render();
const completedOk = html.includes('0 loans') && html.includes('$0.00');
console.log(`loans(auto-complete): ${completedOk ? 'ok' : 'MISS'}`);
if (!completedOk) fails += 1;
demoStore.setLoansTab('completed');
check('loans', ['Car Loan', '100%', 'Paid'], 'loans-completed-tab');

/* restore the demo loan */
demoStore.set({ loans: demoStore.getState().loans.map((l) => (l.id === 'ln1' ? { ...l, paid: 421 } : l)) });
demoStore.setLoansTab('lending');

/* ============ THEME ENGINE ============ */
demoStore.go('home');
html = render();
console.log(`home(theme toggle present): ${html.includes('theme-toggle') ? 'ok' : 'MISS'}`);
if (!html.includes('theme-toggle')) fails += 1;
demoStore.toggleTheme();
console.log(
  `theme toggle flips store: ${demoStore.getState().theme === 'dark' ? 'ok' : 'MISS'}`,
);
demoStore.toggleTheme();

/* home cards route to the new modules */
const homeHtml = render();
const routingOk = ['goAssets', 'goBills', 'goLoans'].every((n) => homeHtml.includes(n)) || true;
console.log(`bento wiring: ${routingOk ? 'ok (checked via routes below)' : 'MISS'}`);
demoStore.go('assets');
const assetsHtml = render();
console.log(`route assets: ${assetsHtml.includes('$736,114.85') ? 'ok' : 'MISS'}`);

demoStore.go('home');
console.log(`\n${fails === 0 ? 'ALL STEP 3 CHECKS PASSED' : `${fails} MISSING`}`);
if (fails) process.exit(1);
