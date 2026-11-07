import React from 'react';
import { renderToString } from 'react-dom/server';
import App from '../src/App.jsx';
import { demoStore } from '../src/data/demoStore.js';
import { goalCards, loanCards, budgetPace } from '../src/data/derive.js';

const checks = [];
const check = (name, ok) => checks.push([name, ok]);
const render = () => renderToString(React.createElement(App));
const state = () => demoStore.getState();

demoStore.go('loans', {});
const loans = render();
check('loans header', loans.includes('Loans'));
check('car loan', loans.includes('Car Loan'));
check('loan summary', loans.includes('Net Loan Balance'));
check('loan math', loanCards(state()).find((l) => l.id === 'ln-car').total === 17757);

demoStore.go('loanDetails', { id: 'ln-car' });
const loanDetails = render();
check('loan details', loanDetails.includes('Car Loan'));
check('loan log +', loanDetails.includes('Log transaction'));

demoStore.go('goals', {});
const goals = render();
check('goals header', goals.includes('Goals'));
check('emergency goal', goals.includes('Emergency Fund'));
check('goal math', goalCards(state()).find((g) => g.id === 'gl-emergency').saved === 5950);

demoStore.go('goalDetails', { id: 'gl-emergency' });
const goalDetails = render();
check('goal details', goalDetails.includes('completed'));
check('still needed', goalDetails.includes('Still needed'));
check('savings button', goalDetails.includes('Add savings / deposit'));

demoStore.go('budgetDetail', { id: 'food' });
const budgetDetail = render();
check('pace chart', budgetDetail.includes('Pace chart'));
check('daily safe spend', budgetDetail.includes('Daily Safe Spend'));
check('pace points', budgetPace(state(), 'food').points.length > 0);

demoStore.go('home', {});
demoStore.openProfile();
const profile = render();
check('profile modal', profile.includes('Your profile'));
check('reset data', profile.includes('Reset / Clear All Data'));
check('base currency', profile.includes('Base currency'));
check('no demo dialog', !profile.includes('Leave the demo'));

let fail = 0;
checks.forEach(([name, ok]) => { if (!ok) { fail += 1; console.log('MISSING:', name); } });
console.log(`\nALL STEP 4 CHECKS PASSED (${checks.length - fail}/${checks.length})`);
if (fail) process.exit(1);
