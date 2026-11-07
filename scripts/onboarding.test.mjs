/**
 * Onboarding / i18n / backup store tests — run with:
 * node scripts/onboarding.test.mjs
 */
const memory = new Map();
global.window = {
  localStorage: {
    getItem: (k) => (memory.has(k) ? memory.get(k) : null),
    setItem: (k, v) => memory.set(k, String(v)),
    removeItem: (k) => memory.delete(k),
  },
  setTimeout: () => 0,
  history: { pushState: () => {}, replaceState: () => {} },
};

const {
  demoStore, STORAGE_KEY, CURRENCIES, CURRENCY_CATALOG,
  LANGUAGES, MORE_LANGUAGES, t, languageBadge,
} = await import('../src/data/demoStore.js');

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

eq('first browser launch starts onboarding', demoStore.getState().onboarding.completed, false);
eq('starts on step one', demoStore.getState().onboarding.step, 1);
eq('nine presentation currencies', CURRENCIES.length, 9);
eq('currency catalog has locale rules', CURRENCY_CATALOG.every((c) => c.locale && c.name && c.compact), true);
eq('35 selectable languages', LANGUAGES.length, 35);
eq('+24 more opens the remaining languages', MORE_LANGUAGES.length, 24);
eq('Hindi navigation translation', t('Accounts', 'hi'), 'खाते');
eq('Punjabi greeting translation', t('Good late night', 'pa'), 'ਸ਼ੁਭ ਰਾਤ');
eq('German hero translation', t('Total balance', 'de'), 'Gesamtsaldo');
eq('language badge', languageBadge('hi'), '🇮🇳 HI');

demoStore.setLanguage('pa');
eq('language persisted', saved().language, 'pa');
demoStore.setProfilePhoto('data:image/png;base64,AAAA');
eq('profile photo persisted', saved().profile.photo, 'data:image/png;base64,AAAA');
demoStore.setOnboardingStep(8);
eq('step 8 persisted', saved().onboarding.step, 8);
demoStore.nextOnboardingStep();
eq('next step', demoStore.getState().onboarding.step, 9);
demoStore.previousOnboardingStep();
eq('previous step', demoStore.getState().onboarding.step, 8);

demoStore.completeOnboarding({ name: 'Aman', photo: 'avatar-data', language: 'de', baseCurrency: 'EUR' });
eq('finish marks onboarding complete', saved().onboarding.completed, true);
eq('finish saves name', saved().profile.name, 'Aman');
eq('finish saves photo', saved().profile.photo, 'avatar-data');
eq('finish saves language', saved().language, 'de');
eq('finish saves currency', saved().profile.baseCurrency, 'EUR');

demoStore.replayOnboarding(3);
eq('replay reopens wizard', demoStore.getState().onboarding.completed, false);
eq('replay uses requested step', demoStore.getState().onboarding.step, 3);

demoStore.startOnboardingFresh();
eq('start fresh clears transactions', demoStore.getState().transactions.length, 0);
eq('start fresh clears accounts', demoStore.getState().accounts.length, 0);
eq('start fresh advances to step 2', demoStore.getState().onboarding.step, 2);
eq('start fresh clears name', demoStore.getState().profile.name, '');

demoStore.tryDemoMode();
eq('demo mode restores 120 transactions', demoStore.getState().transactions.length, 120);
eq('demo mode sets showcase name', demoStore.getState().profile.name, 'Jane Smith');
eq('demo mode advances to step 2', demoStore.getState().onboarding.step, 2);

const backup = demoStore.exportBackup();
ok('backup includes transactions and preferences', backup.includes('"transactions"') && backup.includes('"language"') && backup.includes('"onboarding"'));
demoStore.clearAllData();
eq('data cleared before restore', demoStore.getState().transactions.length, 0);
eq('backup restore succeeds', demoStore.restoreBackup(backup), true);
eq('backup restores transactions', demoStore.getState().transactions.length, 120);
eq('backup returns to home dashboard', demoStore.getState().onboarding.completed, true);
eq('invalid backup rejected', demoStore.restoreBackup('{"not":"money"}'), false);

console.log(`\nONBOARDING: ${pass} passed, ${fail} failed`);
if (fail) process.exit(1);
