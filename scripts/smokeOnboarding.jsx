import React from 'react';
import { renderToString } from 'react-dom/server';

import App from '../src/App.jsx';
import { demoStore } from '../src/data/demoStore.js';

let pass = 0;
let fail = 0;
function ok(label, condition, detail = '') {
  if (condition) pass += 1;
  else { fail += 1; console.log(`FAIL ${label}${detail ? ` — ${detail}` : ''}`); }
}
function includes(label, html, needle) {
  ok(label, html.includes(needle), `missing “${needle}”`);
}
function absent(label, html, needle) {
  ok(label, !html.includes(needle), `unexpected “${needle}”`);
}
const render = () => renderToString(React.createElement(App));

/* ---------- 1/14: first-run entry ---------- */
demoStore.replayOnboarding(1);
const step1 = render();
includes('wizard shell', step1, 'data-testid="onboarding-wizard"');
includes('step counter 1/14', step1, '1/14');
includes('language pill', step1, '🇺🇸 EN');
includes('entry title', step1, 'Set up Paisa');
includes('Google Drive Backup', step1, 'Google Drive Backup');
includes('Restore Local Backup', step1, 'Restore Local Backup');
includes('Try Demo Mode', step1, 'Try Demo Mode');
includes('Start fresh', step1, 'Start fresh');
includes('wallet SVG', step1, 'ob-wallet-logo');

/* ---------- 2/14: exact phone showcase ---------- */
demoStore.setOnboardingStep(2);
const step2 = render();
includes('step counter 2/14', step2, '2/14');
includes('welcome footer', step2, 'Welcome to Paisa');
includes('phone screenshot', step2, '/onboarding/step2.jpg');
includes('get started button', step2, 'Get started');
includes('phone frame', step2, 'ob-phone');

/* ---------- 8/14: language engine ---------- */
demoStore.setOnboardingStep(8);
const step8 = render();
includes('language footer', step8, 'Support for 35+ Languages');
includes('Hindi pill', step8, 'हिन्दी');
includes('Deutsch pill', step8, 'Deutsch');
includes('+24 more', step8, '+24 more');
demoStore.setLanguage('hi');
includes('Hindi updates badge', render(), '🇮🇳 HI');
demoStore.setLanguage('en');

/* ---------- 9/14 + skip-to-setup tour slides ---------- */
demoStore.setOnboardingStep(9);
includes('reports phone screenshot', render(), '/onboarding/step9.jpg');
demoStore.setOnboardingStep(10);
const step10 = render();
includes('tour slide', step10, 'Split Bills Effortlessly');
includes('skip link', step10, 'Skip to Setup');

/* ---------- 13/14: profile photo + validation ---------- */
demoStore.setOnboardingStep(13);
const step13 = render();
includes('name step title', step13, 'What should we call you?');
includes('name input', step13, 'Enter user name');
includes('avatar uploader', step13, 'data-testid="avatar-uploader"');
includes('disabled next button', step13, 'disabled');
includes('ID card icon', step13, 'lucide-id-card');

/* ---------- 14/14: currency catalog ---------- */
demoStore.setOnboardingStep(14);
const step14 = render();
includes('currency title', step14, 'Select your currency');
includes('currency search', step14, 'Search currency (e.g., INR, USD, EUR)...');
includes('INR option', step14, 'Indian Rupee');
includes('USD option', step14, 'US Dollar');
includes('JPY option', step14, 'Japanese Yen');
includes('finish disabled until selected', step14, 'disabled');

/* ---------- finish opens the live dashboard ---------- */
demoStore.completeOnboarding({ name: 'Aman', photo: 'data:image/svg+xml,%3Csvg%2F%3E', language: 'hi', baseCurrency: 'USD' });
const home = render();
absent('wizard gone after finish', home, 'data-testid="onboarding-wizard"');
includes('saved user name', home, 'Aman');
includes('Hindi hero label', home, 'कुल शेष');
includes('USD hero amount', home, '$');
includes('uploaded avatar', home, 'data:image/svg+xml,%3Csvg%2F%3E');

/* ---------- profile settings expose every setup control ---------- */
demoStore.openProfile();
const settings = render();
includes('profile language select', settings, 'App language');
includes('profile currency select', settings, 'Base currency');
includes('profile photo control', settings, 'Profile photo');
includes('theme control', settings, 'Expressive dark mode');
includes('export backup', settings, 'Export local backup');
includes('restore backup', settings, 'Restore local backup');
includes('replay onboarding', settings, 'Replay Onboarding Tour (1/14)');
includes('reset data', settings, 'Reset App Data (Start Fresh)');
demoStore.closeModal();

console.log(`\nONBOARDING SSR: ${pass} passed, ${fail} failed`);
if (fail) process.exit(1);
