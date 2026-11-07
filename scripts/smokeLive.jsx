import React from 'react';
import { renderToString } from 'react-dom/server';
import { readFileSync } from 'node:fs';

import App from '../src/App.jsx';
import { demoStore, fmtFull } from '../src/data/demoStore.js';
import {
  heroTotals,
  accountBalances,
  monthlyTotals,
  budgetMath,
  budgetCards,
  budgetPace,
  budgetCards as allBudgets,
  loanCards,
  goalCards,
  billCards,
  weeklySeries,
  last30Series,
  calendarHeatmap,
  trendSeries,
  donutGroups,
  reportsData,
  reportMonths,
  upcomingTransactions,
  searchTransactions,
  balanceBreakdown,
  overview,
} from '../src/data/derive.js';
import { billStatus } from '../src/data/engine.js';

let pass = 0;
let fail = 0;

function ok(label, condition, detail = '') {
  if (condition) pass += 1;
  else { fail += 1; console.log(`FAIL ${label}${detail ? ` — ${detail}` : ''}`); }
}
function eq(label, actual, expected) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  ok(label, a === e, `expected ${e}, got ${a}`);
}
function includes(label, html, needle) {
  ok(label, html.includes(needle), `missing “${needle}”`);
}
function absent(label, html, needle) {
  ok(label, !html.includes(needle), `unexpected “${needle}”`);
}
const render = () => renderToString(React.createElement(App));

/* ---------- 1. live home shell & no demo UI ---------- */
const home = render();
includes('home total balance', home, 'Total balance');
includes('home default user', home, 'Raj');
includes('home hero amount', home, '₹8,55,933.46');
includes('home accounts KPI', home, '₹14.8L');
includes('home weekly chart', home, 'Weekly');
includes('home sparkline', home, 'Last 30 days');
includes('home heatmap', home, 'Spending heatmap');
includes('home trend', home, 'Monthly trend');
includes('home templates', home, 'Morning Coffee');
includes('home add template', home, 'Add template');
includes('home budgets', home, 'Track budgets');
includes('home upcoming', home, 'Upcoming transactions');
includes('home future row', home, 'Coffee with team');
absent('no Exit Demo pill', home, 'Exit Demo');
absent('no Demo User', home, 'Demo User');
absent('no DEMO ribbon text', home, '>DEMO<');
ok('interactive chart surfaces', (home.match(/data-scrub="true"/g) || []).length >= 8, `found ${(home.match(/data-scrub="true"/g) || []).length}`);
ok('home rendered length', home.length > 30000, `length ${home.length}`);

/* ---------- 2. SVG maths & pointer scrubbing are in source ---------- */
const charts = readFileSync('src/components/charts/Interactive.jsx', 'utf8');
ok('ring uses dynamic strokeDashoffset', charts.includes('const offset = c - (safe / 100) * c'));
ok('wavy uses sine path', charts.includes('Math.sin') && charts.includes('clipPath'));
ok('touch start/move handlers', charts.includes('onTouchStart') && charts.includes('onTouchMove'));
ok('mouse move scrubbing', charts.includes('onMouseMove'));
ok('floating tooltip + crosshair', charts.includes('chart-tooltip') && charts.includes('chart-crosshair'));

/* ---------- 3. derived seed values ---------- */
let s = demoStore.getState();
eq('seed transactions', s.transactions.length, 120);
eq('seed accounts', s.accounts.length, 7);
eq('seed hero total', heroTotals(s).total, 855933.46);
eq('seed monthly income', monthlyTotals(s, '2026-11').income, 7114);
eq('seed monthly expense', monthlyTotals(s, '2026-11').expense, 1925);
eq('account balances count', accountBalances(s).length, 7);
ok('weekly 7 points', weeklySeries(s).days.length === 7);
ok('last30 30 points', last30Series(s).points.length === 30);
ok('calendar cells', calendarHeatmap(s).cells.length > 30);
ok('trend 31 days', trendSeries(s).days.length === 31);
ok('balance breakdown total', Math.abs(balanceBreakdown(s).total - 855933.46) < 0.01);
ok('overview people alias', overview(s).people.count === 5);
ok('upcoming future rows', upcomingTransactions(s).length > 0);
ok('search finds coffee', searchTransactions(s, 'Morning Coffee').length > 0);
eq('report month labels', reportMonths(s).slice(0, 3), ['Nov 26', 'Oct 26', 'Sep 26']);
ok('all donut dimensions unlock', ['Category', 'Account', 'Label', 'Person', 'Places'].every((d) => Array.isArray(donutGroups(s, 'Nov 26', 'Expense', d))));
ok('budget pace points', budgetPace(s, 'food').points.length > 0);

/* ---------- 4. universal transaction CRUD recomputes everything ---------- */
const baseHero = heroTotals(s).total;
const foodBefore = budgetMath(s.budgets.find((b) => b.id === 'food'), s).spent;
demoStore.saveTransaction({
  id: 'live-test-exp', title: 'Smoke test expense', type: 'expense', amount: 100,
  currency: 'INR', date: s.today, time: '10:30', account: 'Kotak Mahindra Bank',
  category: 'Food & Dining', budgetId: 'food',
});
s = demoStore.getState();
eq('expense lowers hero', heroTotals(s).total, baseHero - 100);
eq('expense raises food spent', budgetMath(s.budgets.find((b) => b.id === 'food'), s).spent, foodBefore + 100);
eq('expense raises monthly expense', monthlyTotals(s, '2026-11').expense, 2025);
demoStore.openTransactionEditor('live-test-exp');
s = demoStore.getState();
eq('editing modal id', s.ui.modalData.id, 'live-test-exp');
eq('editing flag', s.ui.modalData.editing, true);
const editModal = render();
includes('edit modal delete', editModal, 'Delete');
includes('edit modal update', editModal, 'Update transaction');
demoStore.saveTransaction({ ...s.ui.modalData, amount: 200 });
s = demoStore.getState();
eq('update lowers hero again', heroTotals(s).total, baseHero - 200);
eq('update food spent', budgetMath(s.budgets.find((b) => b.id === 'food'), s).spent, foodBefore + 200);
demoStore.deleteTransaction('live-test-exp');
s = demoStore.getState();
eq('delete restores hero', heroTotals(s).total, baseHero);
eq('delete restores food spent', budgetMath(s.budgets.find((b) => b.id === 'food'), s).spent, foodBefore);
demoStore.closeModal();

/* ---------- 5. account CRUD, budget CRUD, templates, collections ---------- */
demoStore.saveAccount({ id: 'live-test-ac', name: 'Test Account', holder: 'Raj', balance: 1000, last4: '0001', type: 'Bank', color: '#123456', currency: 'INR', includeInTotals: true });
s = demoStore.getState();
eq('add account raises hero', heroTotals(s).total, baseHero + 1000);
demoStore.saveAccount({ id: 'live-test-ac', name: 'Test Account', holder: 'Raj', balance: 2000, last4: '0001', type: 'Bank', color: '#123456', currency: 'INR', includeInTotals: true });
s = demoStore.getState();
eq('edit account raises hero', heroTotals(s).total, baseHero + 2000);
demoStore.deleteAccount('live-test-ac');
s = demoStore.getState();
eq('delete account restores hero', heroTotals(s).total, baseHero);

demoStore.saveBudget({ id: 'live-test-bd', name: 'Smoke Budget', limit: 1000, for: 'Expense', type: 'Category', mode: 'Automatic', period: 'Monthly', start: s.today, end: s.today, categories: ['Only For Smoke'], color: '#3949AB' });
s = demoStore.getState();
const testBudget = s.budgets.find((b) => b.id === 'live-test-bd');
eq('new budget spent', budgetMath(testBudget, s).spent, 0);
eq('new budget remaining', budgetMath(testBudget, s).remaining, 1000);
eq('new budget used pct', budgetMath(testBudget, s).usedPct, 0);
demoStore.saveTransaction({ id: 'live-test-bd-tx', title: 'Budget smoke', type: 'expense', amount: 250, currency: 'INR', date: s.today, account: 'Kotak Mahindra Bank', category: 'Only For Smoke', budgetId: 'live-test-bd' });
s = demoStore.getState();
eq('linked tx budget spent', budgetMath(s.budgets.find((b) => b.id === 'live-test-bd'), s).spent, 250);
eq('linked tx budget remaining', budgetMath(s.budgets.find((b) => b.id === 'live-test-bd'), s).remaining, 750);
eq('linked tx budget used pct', budgetMath(s.budgets.find((b) => b.id === 'live-test-bd'), s).usedPct, 25);
ok('daily safe spend positive', budgetMath(s.budgets.find((b) => b.id === 'live-test-bd'), s).dailySafeSpend > 0);
demoStore.deleteTransaction('live-test-bd-tx');
demoStore.deleteBudget('live-test-bd');
s = demoStore.getState();
eq('budget deleted', s.budgets.some((b) => b.id === 'live-test-bd'), false);

demoStore.saveTemplate({ id: 'live-test-tpl', name: 'Smoke Template', amount: 42, type: 'expense', category: 'Food & Dining', color: '#7B4028' });
s = demoStore.getState();
ok('template created', s.templates.some((t) => t.id === 'live-test-tpl'));
demoStore.deleteTemplate('live-test-tpl');
s = demoStore.getState();
ok('template deleted', !s.templates.some((t) => t.id === 'live-test-tpl'));

['categories', 'people', 'places', 'labels'].forEach((collection) => {
  const id = `live-test-${collection}`;
  demoStore.saveCollectionItem(collection, { id, name: `Smoke ${collection}`, color: '#7B4028', type: 'expense' });
  s = demoStore.getState();
  ok(`${collection} inline create`, s[collection].some((x) => x.id === id));
  demoStore.deleteCollectionItem(collection, id);
  s = demoStore.getState();
  ok(`${collection} delete`, !s[collection].some((x) => x.id === id));
});

/* ---------- 6. loans, goals, bills, profile, month filter, reset ---------- */
s = demoStore.getState();
const carBefore = loanCards(s).find((l) => l.id === 'ln-car');
demoStore.recordLoanPayment('ln-car', 100, { type: 'repayment' });
s = demoStore.getState();
const carAfter = loanCards(s).find((l) => l.id === 'ln-car');
eq('loan payment raises paid', carAfter.paid, carBefore.paid + 100);
eq('loan payment lowers remaining', carAfter.remaining, carBefore.remaining - 100);
ok('loan history appended', s.transactions.some((t) => t.loanId === 'ln-car' && t.title.includes('Repayment')));

const emergencyBefore = goalCards(s).find((g) => g.id === 'gl-emergency');
demoStore.addGoalTransaction('gl-emergency', { amount: 100, type: 'income' });
s = demoStore.getState();
const emergencyAfter = goalCards(s).find((g) => g.id === 'gl-emergency');
eq('goal deposit raises saved', emergencyAfter.saved, emergencyBefore.saved + 100);
eq('goal deposit lowers still needed', emergencyAfter.remaining, emergencyBefore.remaining - 100);

const roadTrip = () => demoStore.getState().bills.find((b) => b.id === 'bs1');
ok('bill starts pending', billStatus(roadTrip()) === 'Pending');
demoStore.markParticipantPaid('bs1', 'p-bob');
s = demoStore.getState();
ok('mark paid settles bill', billStatus(roadTrip()) === 'Settled');
ok('settled tab derived', billCards(s).find((b) => b.id === 'bs1').settled === true);

demoStore.setReportMonth('Oct 26');
s = demoStore.getState();
eq('report month persisted', s.reportsUi.month, 'Oct 26');
eq('report month filters', reportsData(s).month, 'Oct 26');
demoStore.setDimension('Places');
s = demoStore.getState();
eq('dimension unlock', s.reportsUi.dimension, 'Places');
demoStore.toggleReportType();
s = demoStore.getState();
eq('report type toggle', s.reportsUi.type, 'Income');

demoStore.setProfile({ name: 'Asha', baseCurrency: 'USD' });
s = demoStore.getState();
eq('profile name editable', s.profile.name, 'Asha');
eq('base currency editable', s.profile.baseCurrency, 'USD');
ok('USD formatter', fmtFull(100, 'USD').includes('$'));
demoStore.setProfile({ name: 'Raj', baseCurrency: 'INR' });

demoStore.clearAllData();
s = demoStore.getState();
eq('clear all hero zero', heroTotals(s).total, 0);
eq('clear all accounts', s.accounts.length, 0);
eq('clear all transactions', s.transactions.length, 0);
eq('clear all budgets', s.budgets.length, 0);
eq('clear all assets', s.assets.length, 0);
eq('clear all bills', s.bills.length, 0);
eq('clear all loans', s.loans.length, 0);
eq('clear all goals', s.goals.length, 0);
eq('clear all templates', s.templates.length, 0);
const freshHome = render();
includes('fresh home zero', freshHome, '₹0.00');
absent('fresh home demo', freshHome, 'Exit Demo');

demoStore.restoreSampleData();
s = demoStore.getState();
eq('restore seed hero', heroTotals(s).total, 855933.46);
eq('restore seed tx', s.transactions.length, 120);

/* ---------- 7. every view renders against live state ---------- */
const views = [
  ['reports', {}, 'Reports'],
  ['accounts', {}, 'Accounts'],
  ['budgets', {}, 'Budgets'],
  ['budgetDetail', { id: 'food' }, 'Pace chart'],
  ['assets', {}, 'Assets'],
  ['assetEditor', { id: 'as1' }, 'Current Value'],
  ['billSplitter', {}, 'Bill Splitter'],
  ['billDetails', { id: 'bs1' }, 'Bill Details'],
  ['billEditor', {}, 'Split type'],
  ['loans', {}, 'Loans'],
  ['loanDetails', { id: 'ln-car' }, 'Car Loan'],
  ['loanEditor', {}, 'Lending'],
  ['goals', {}, 'Goals'],
  ['goalDetails', { id: 'gl-emergency' }, 'completed'],
  ['goalEditor', {}, 'Goal'],
  ['search', { query: '' }, 'live results'],
];
views.forEach(([view, params, needle]) => {
  demoStore.go(view, params);
  let html;
  try { html = render(); } catch (err) {
    ok(`render ${view}`, false, err.message);
    return;
  }
  ok(`render ${view}`, html.length > 1000, `length ${html.length}`);
  includes(`render ${view} content`, html, needle);
  absent(`render ${view} no demo`, html, 'Exit Demo');
});

/* ---------- 8. every modal renders with controlled fields ---------- */
demoStore.go('home', {});
demoStore.openTransactionEditor();
includes('transaction modal', render(), 'Save transaction');
includes('transaction number input', render(), 'type="number"');
demoStore.openProfile();
includes('profile modal reset', render(), 'Reset App Data (Start Fresh)');
includes('profile base currency', render(), 'Base currency');
demoStore.openAccountEditor();
includes('account modal holder', render(), 'Account holder name');
demoStore.openBudgetEditor();
includes('budget modal for', render(), 'Budget for');
includes('budget modal period', render(), 'Period');
demoStore.openTemplateEditor();
includes('template modal', render(), 'Save template');
demoStore.openCollection('templates');
includes('collection manager', render(), 'Morning Coffee');
demoStore.openLayout();
includes('layout modal', render(), 'Customize dashboard');
demoStore.openFeedback();
includes('feedback modal', render(), 'Feedback');
demoStore.saveFeedback('Live smoke feedback');
eq('feedback saved', demoStore.getState().status.feedback, 'Live smoke feedback');
demoStore.openBalance();
includes('balance modal', render(), 'Balance breakdown');
demoStore.openReportDetail('Monthly');
includes('report detail modal', render(), 'report');
demoStore.openPaymentEditor('bs1', 'p-bob', 'markPaid');
includes('payment modal', render(), 'Record payment');
demoStore.openQuickLog('ln-car');
includes('loan payment modal', render(), 'Record loan payment / charge');
demoStore.openGoalDeposit('gl-emergency');
includes('goal deposit modal', render(), 'Add savings');
demoStore.closeModal();

console.log(`\nLIVE OVERHAUL: ${pass} passed, ${fail} failed`);
if (fail) process.exit(1);
