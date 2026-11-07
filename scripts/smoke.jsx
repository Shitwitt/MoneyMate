import React from 'react';
import { renderToString } from 'react-dom/server';
import App from '../src/App.jsx';
import { demoStore } from '../src/data/demoStore.js';
import { heroTotals } from '../src/data/derive.js';

demoStore.go('home', {});
const html = renderToString(React.createElement(App));
const state = demoStore.getState();
const checks = [
  ['total balance', html.includes('Total balance')],
  ['default user Raj', html.includes('Raj')],
  ['hero amount', html.includes('₹8,55,933.46')],
  ['hero derivation', heroTotals(state).total === 855933.46],
  ['accounts KPI', html.includes('₹14.8L')],
  ['weekly chart', html.includes('Weekly')],
  ['sparkline', html.includes('Last 30 days')],
  ['calendar', html.includes('Spending heatmap')],
  ['trend', html.includes('Monthly trend')],
  ['templates', html.includes('Morning Coffee')],
  ['budgets', html.includes('Track budgets')],
  ['upcoming', html.includes('Upcoming transactions')],
  ['future row', html.includes('Coffee with team')],
  ['interactive surfaces', (html.match(/data-scrub="true"/g) || []).length >= 8],
  ['no Exit Demo', !html.includes('Exit Demo')],
  ['no Demo User', !html.includes('Demo User')],
  ['render length', html.length > 30000],
];
let fail = 0;
for (const [name, ok] of checks) {
  if (!ok) { fail += 1; console.log('MISSING:', name); }
}
console.log(`\nrender length ${html.length} | checks ${checks.length - fail}/${checks.length} passed`);
if (fail) process.exit(1);
