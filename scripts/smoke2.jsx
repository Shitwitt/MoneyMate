import React from 'react';
import { renderToString } from 'react-dom/server';

import { demoStore } from '../src/data/demoStore.js';
import App from '../src/App.jsx';

/** React inserts <!-- --> between adjacent text nodes and escapes entities —
    normalise so assertions can match the user-visible text. */
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

function check(view, needles) {
  demoStore.go(view, { id: 'transport' });
  const html = render();
  let miss = 0;
  needles.forEach((n) => {
    if (!html.includes(n)) {
      console.log(`  MISS [${view}] ${n}`);
      miss += 1;
    }
  });
  console.log(`${view}: ${needles.length - miss}/${needles.length} ok (${html.length} chars)`);
  return miss;
}

let fails = 0;

/* ---------- Home still intact ---------- */
fails += check('home', ['Total balance', '₹8,55,933.46', 'Overview', 'Calendar heatmap', 'Track budgets']);

/* ---------- Accounts ---------- */
fails += check('accounts', [
  'Accounts',
  'Kotak Mahindra Bank',
  'Demo User',
  '9123',
  '$14,188.00',
  'Total balance',
  'Card',
  'Income',
  '$6,809.00',
  '3813.22%',
  'Compared to $174.00 last month',
  '$511.00',
  '100.00%',
  'Compared to $0.00 last month',
  'Transactions',
  'Transfer 64',
  'Cash Wallet',
  '$290.00',
  'Drive-through meal',
  '$226.00',
  'Transfer 1',
  '$6.00',
  'Transfer to family wallet',
  '$500.00',
  'Dec 19',
  'Nov 28',
  'Nov 25',
]);

/* ---------- Reports ---------- */
fails += check('reports', [
  'Reports',
  'Nov 26',
  'Oct 26',
  'Sep 26',
  'Aug 26',
  'Jul 26',
  'Total balance',
  '$6,436.00',
  'Income',
  '+3813%',
  '$6,500.00',
  'was $174.00',
  'Expense',
  '+421%',
  '$64.00',
  'was $190.82',
  'Quick Insights',
  '2 Transactions',
  'Savings Rate',
  '+99.0%',
  '+$6,436.00',
  'Avg. Daily',
  '$2.13',
  '0.1 / day',
  'Average Transaction',
  '1 Expense',
  'Peak Spending Day',
  'Tue, Nov 3',
  'Top Category',
  'Bills & Utilities',
  '100.0%',
  'Largest Expense',
  'Internet bill',
  'Nov 3, 2026',
  'Category',
  'Bills & Utilities (100.0%)',
  'Includes sub-categories',
  'Financial Reports',
  'Month Summary',
  'Category Breakdown',
  'Budget Performance',
  'Cash Flow Analysis',
  'Goal Progress',
  '*Note',
  'Initial account balances can be viewed in Accounts section.',
]);

/* ---------- Reports: line mode + month switch ---------- */
demoStore.setChartMode('line');
demoStore.setReportMonth('Oct 26');
{
  const html = render();
  const ok = html.includes('Groceries') && html.includes('36.8');
  console.log(`reports(oct, line chart): ${ok ? 'ok' : 'MISS'}`);
  if (!ok) fails += 1;
}
demoStore.setChartMode('bars');
demoStore.setReportMonth('Nov 26');

/* ---------- Reports: dimension menu ---------- */
demoStore.toggleCategoryMenu();
{
  const html = render();
  const ok = ['Category', 'Account', 'Label', 'Person', 'Places'].every((d) => html.includes(d));
  console.log(`reports(dropdown menu): ${ok ? 'ok' : 'MISS'}`);
  if (!ok) fails += 1;
}
demoStore.toggleCategoryMenu();

/* ---------- Budgets ---------- */
fails += check('budgets', [
  'Budgets',
  '2/2',
  '12%',
  'Spent',
  'Total',
  '$4,275.00',
  '$515.00',
  'Remaining',
  '$3,760.00',
  '2 budgets',
  'Transportation Budget',
  'Monthly',
  'Category',
  'Automatic',
  '17%',
  '$497.00',
  '$2,937.00',
  'You can spend $135.56/day for 18 more days',
  '$2,440.00',
  'Food Budget',
  'Manual',
  '1%',
  '$18.00',
  '$1,338.00',
  'You can spend $165.00/day for 8 more days',
  '$1,320.00',
]);

/* ---------- How budgets work modal ---------- */
demoStore.go('budgets');
demoStore.openHowBudgets(true);
{
  const html = render();
  const needles = [
    'How Budgets Work',
    "Budgets help you set spending limits and track your expenses. Here's how to get started.",
    'Budget For',
    'Expense Budget: Set limits on how much you spend.',
    'Budget Type',
    'Budget Mode',
    'Budget Period',
    'Categories',
    'Rolling Budget',
    'Tracking',
    'Got it',
  ];
  let miss = 0;
  needles.forEach((n) => {
    if (!html.includes(n)) {
      console.log(`  MISS [modal] ${n}`);
      miss += 1;
    }
  });
  console.log(`modal: ${needles.length - miss}/${needles.length} ok`);
  fails += miss;
}
demoStore.openHowBudgets(false);

/* ---------- Budget detail ---------- */
fails += check('budgetDetail', [
  'Budget',
  'Transportation Budget',
  'Good',
  '17% Used',
  '$497.00 of $2,937.00',
  'Remaining',
  '$2,440.00',
  'Spent',
  'You can spend $135.56/day for 18 more days',
  'Show Budget',
  'Track this budget on home screen',
  'Budget Progress',
  'Limit',
  'Ideal Pace',
  'Expense',
  'Category Breakdown',
  'Transportation',
  '17%',
  'Recent transactions',
  'Fuel refill',
  '$72.00',
  'Electricity bill',
  '$425.00',
  'Nov 12',
  'Tomorrow',
  'HDFC Bank',
  'Edit',
]);

/* ---------- budget detail for the food budget ---------- */
demoStore.go('budgetDetail', { id: 'food' });
{
  const html = render();
  const ok = html.includes('Food Budget') && html.includes('$1,320.00');
  console.log(`budgetDetail(food): ${ok ? 'ok' : 'MISS'}`);
  if (!ok) fails += 1;
}

demoStore.go('home');
console.log(`\n${fails === 0 ? 'ALL STEP 2 CHECKS PASSED' : `${fails} MISSING STRINGS`}`);
if (fails) process.exit(1);
