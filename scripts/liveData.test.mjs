/**
 * Live-state tests — run with: node scripts/liveData.test.mjs
 * A tiny localStorage shim proves every mutation is persisted automatically.
 */
const memory = new Map();
global.window = {
  localStorage: {
    getItem: (k) => (memory.has(k) ? memory.get(k) : null),
    setItem: (k, v) => memory.set(k, String(v)),
    removeItem: (k) => memory.delete(k),
  },
  setTimeout: () => 0,
  history: { pushState: () => {} },
};

const { demoStore, STORAGE_KEY, convert, fmtFull, fmtCompact, CURRENCIES } = await import('../src/data/demoStore.js');
const { heroTotals, reportsData, accountBalances } = await import('../src/data/derive.js');

let pass = 0;
let fail = 0;
function eq(label, actual, expected) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a === e) pass += 1;
  else { fail += 1; console.log(`FAIL ${label}\n  expected ${e}\n  actual   ${a}`); }
}
function ok(label, condition) {
  if (condition) pass += 1;
  else { fail += 1; console.log(`FAIL ${label}`); }
}
const saved = () => JSON.parse(memory.get(STORAGE_KEY) || '{}');

eq('nine currencies', CURRENCIES, ['INR', 'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'AED', 'CHF']);
eq('USD to INR conversion', convert(100, 'USD', 'INR'), 8315);
eq('full INR grouping', fmtFull(855933.46, 'INR'), '₹8,55,933.46');
eq('full USD grouping', fmtFull(100, 'USD'), '$100.00');
eq('compact base currency', fmtCompact(1480000, 'INR'), '₹14.8L');
ok('storage starts empty', !memory.has(STORAGE_KEY));

demoStore.saveTransaction({
  id: 'persist-test', title: 'Persistence test', type: 'expense', amount: 50,
  currency: 'INR', date: demoStore.getState().today, account: 'Kotak Mahindra Bank',
});
eq('transaction persisted', saved().transactions.some((t) => t.id === 'persist-test'), true);
eq('hero recomputed in memory', heroTotals(demoStore.getState()).total, 855883.46);
eq('account balance recomputed', accountBalances(demoStore.getState())[0].balance, 651150);

demoStore.setProfile({ name: 'Riya', baseCurrency: 'USD' });
eq('profile name persisted', saved().profile.name, 'Riya');
eq('currency persisted', saved().profile.baseCurrency, 'USD');
eq('user greeting name synced', saved().user.name, 'Riya');
ok('USD hero formatting', fmtFull(heroTotals(demoStore.getState()).total, 'USD').startsWith('$'));
demoStore.setProfile({ name: 'Raj', baseCurrency: 'INR' });

demoStore.saveFeedback('Persisted feedback');
eq('status feedback persisted', saved().status.feedback, 'Persisted feedback');
demoStore.setReportMonth('Sep 26');
eq('report month stored in UI state', demoStore.getState().reportsUi.month, 'Sep 26');
ok('reports month filter works', reportsData(demoStore.getState()).month === 'Sep 26');

demoStore.clearAllData();
eq('clear persisted transactions', saved().transactions.length, 0);
eq('clear persisted accounts', saved().accounts.length, 0);
eq('clear persisted profile offset', saved().profile.liabilitiesOffset, 0);
eq('clear hero zero', heroTotals(demoStore.getState()).total, 0);

demoStore.restoreSampleData();
eq('restore persisted transactions', saved().transactions.length, 120);
eq('restore persisted accounts', saved().accounts.length, 7);
eq('restore hero', heroTotals(demoStore.getState()).total, 855933.46);

console.log(`\nLIVE DATA: ${pass} passed, ${fail} failed`);
if (fail) process.exit(1);
