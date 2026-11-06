import React from 'react';
import { renderToString } from 'react-dom/server';
import App from '../src/App.jsx';

const html = renderToString(React.createElement(App));
const checks = [
  ['Total balance', 'Total balance'],
  ['hero amount', '8,55,933.46'],
  ['accounts kpi', '₹14.8L'],
  ['reports kpi', '₹14.8K'],
  ['assets kpi', '₹5.06L'],
  ['loan balance', '-₹79.1K'],
  ['budget spent', '₹24.9K'],
  ['bill splitter', '₹206'],
  ['recurring', '₹568'],
  ['analytics', '₹1.49K'],
  ['weekly', '₹82.00'],
  ['spark', '₹370'],
  ['achievements', 'Day One'],
  ['heatmap month', 'Nov 2026'],
  ['trend', 'Upcoming'],
  ['budget carousel', 'Food Budget'],
  ['remaining', '-₹32,476.74'],
  ['tx eur', '272,00 €'],
  ['tx gbp', '£153.00'],
  ['tx conv', '₹295.65'],
  ['chips', 'Transportation Budget'],
  ['nav', 'Search'],
  ['exit', 'Exit Demo'],
  ['greeting', 'Good late night'],
];
let fail = 0;
for (const [name, needle] of checks) {
  const ok = html.includes(needle);
  if (!ok) { fail += 1; console.log('MISSING:', name, '->', needle); }
}
console.log(`\nrender length ${html.length} | checks ${checks.length - fail}/${checks.length} passed`);
if (fail) process.exit(1);
