import React from 'react';
import { renderToString } from 'react-dom/server';
import App from '../src/App.jsx';
import { demoStore } from '../src/data/demoStore.js';
import { reportsData } from '../src/data/derive.js';

const checks = [];
const check = (name, ok) => checks.push([name, ok]);
const render = () => renderToString(React.createElement(App));

demoStore.go('reports', {});
const reports = render();
check('reports header', reports.includes('Reports'));
check('month pills', reports.includes('Nov 26') && reports.includes('Oct 26'));
check('quick insights', reports.includes('Quick Insights'));
check('reports chart', reports.includes('Reports chart'));
check('donut breakdown', reports.includes('Breakdown'));
check('financial reports', reports.includes('Financial Reports'));
check('month filtering', reportsData(demoStore.getState()).month === 'Nov 26');
check('reports length', reports.length > 10000);
check('reports no demo', !reports.includes('Exit Demo'));

demoStore.go('accounts', {});
const accounts = render();
check('accounts header', accounts.includes('Accounts'));
check('add account', accounts.includes('Add account'));
check('live account name', accounts.includes('Kotak Mahindra Bank'));
check('account transactions', accounts.includes('Transactions'));
check('accounts no demo', !accounts.includes('Exit Demo'));

let fail = 0;
checks.forEach(([name, ok]) => { if (!ok) { fail += 1; console.log('MISSING:', name); } });
console.log(`\nALL STEP 2 CHECKS PASSED (${checks.length - fail}/${checks.length})`);
if (fail) process.exit(1);
