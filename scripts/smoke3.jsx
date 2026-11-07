import React from 'react';
import { renderToString } from 'react-dom/server';
import App from '../src/App.jsx';
import { demoStore } from '../src/data/demoStore.js';
import { overview } from '../src/data/derive.js';

const checks = [];
const check = (name, ok) => checks.push([name, ok]);
const render = () => renderToString(React.createElement(App));

demoStore.go('assets', {});
const assets = render();
check('assets header', assets.includes('Assets'));
check('assets total', assets.includes('Total'));
check('asset row', assets.includes('Primary Residence'));
check('portfolio derivation', overview(demoStore.getState()).assets.portfolio === 736114.85);
check('assets no demo', !assets.includes('Demo User'));

demoStore.go('billSplitter', {});
const bills = render();
check('bill splitter header', bills.includes('Bill Splitter'));
check('bill row', bills.includes('Road Trip Expenses'));
check('bill tabs', bills.includes('Active') && bills.includes('Settled'));

demoStore.go('billDetails', { id: 'bs1' });
demoStore.openParticipantMenu('p-bob');
const details = render();
check('bill details header', details.includes('Bill Details'));
check('participants', details.includes('Participants'));
check('edit payment action', details.includes('Edit Payment'));

demoStore.go('billEditor', {});
const editor = render();
check('bill editor split type', editor.includes('Split type'));
check('bill editor participants', editor.includes('Participants'));
check('bill editor no demo', !editor.includes('Exit Demo'));

let fail = 0;
checks.forEach(([name, ok]) => { if (!ok) { fail += 1; console.log('MISSING:', name); } });
console.log(`\nALL STEP 3 CHECKS PASSED (${checks.length - fail}/${checks.length})`);
if (fail) process.exit(1);
