/* ============================================================
   Live, editable seed data for MoneyMate.
   ------------------------------------------------------------
   These are ordinary user records: every array is
   persisted, editable and deletable from the UI. The generated ledger is
   deterministic so the first render still matches the reference numbers:
     • 120 transactions
     • current month income ₹7,114 / expense ₹1,925
     • last month income ₹295 / expense ₹708
     • accounts ₹14.8L, hero ₹8,55,933.46
   ============================================================ */

import { accounts as step2Accounts, budgets as step2Budgets } from './step2Data.js';
import { assets as step3Assets, billSplitters, contacts } from './step3Data.js';
import {
  seedLoans,
  seedGoals,
  seedTransactions,
  expenseCategories,
  incomeCategories,
  accountCatalog,
} from './step4Data.js';
import { toINR } from './format.js';

export const TODAY = '2026-11-07';

const DAY = 86400000;
const iso = (d) => new Date(d).toISOString().slice(0, 10);
export const addDays = (dateISO, n) => iso(new Date(`${dateISO}T00:00:00Z`).getTime() + n * DAY);
export const monthKey = (dateISO) => dateISO.slice(0, 7);
export function monthBounds(dateISO = TODAY) {
  const [y, m] = dateISO.split('-').map(Number);
  const start = `${y}-${String(m).padStart(2, '0')}-01`;
  const next = new Date(Date.UTC(y, m, 1)).toISOString().slice(0, 10);
  return { start, end: addDays(next, -1) };
}
export const CURRENT_MONTH = monthBounds(TODAY);
const PREV_MONTH = monthBounds(addDays(CURRENT_MONTH.start, -1));

export const PEOPLE = [
  { id: 'p-alice', name: 'Alice', color: '#00897B' },
  { id: 'p-bob', name: 'Bob', color: '#1E88E5' },
  { id: 'p-carol', name: 'Carol', color: '#8E24AA' },
  { id: 'p-dan', name: 'Dan', color: '#EF6C00' },
  { id: 'p-raj', name: 'Raj', color: '#7B4028' },
];

export const PLACES = [
  { id: 'pl-work', name: 'Work', color: '#388E3C' },
  { id: 'pl-home', name: 'Home', color: '#1565C0' },
  { id: 'pl-cafe', name: 'Cafe', color: '#D81B60' },
  { id: 'pl-mall', name: 'Mall', color: '#8E24AA' },
];

export const LABELS = [
  { id: 'lb-personal', name: 'Personal', color: '#C2185B' },
  { id: 'lb-work', name: 'Work', color: '#2E7D32' },
  { id: 'lb-food', name: 'Food', color: '#EF6C00' },
  { id: 'lb-travel', name: 'Travel', color: '#00897B' },
];

export const CATEGORIES = [
  ...expenseCategories.map((c) => ({ ...c, type: 'expense' })),
  ...incomeCategories.map((c) => ({ ...c, type: 'income' })),
];

const ACCOUNT_NAMES = [
  'Kotak Mahindra Bank',
  'HDFC Bank',
  'Cash Wallet',
  'Savings Account',
  'Raj Card',
  'Wise EUR',
  'Monzo GBP',
];

const ACCOUNT_META = {
  'Kotak Mahindra Bank': { type: 'Bank', color: '#00897B', last4: '9123', currency: 'INR', includeInTotals: true },
  'HDFC Bank': { type: 'Bank', color: '#5E35B1', last4: '4417', currency: 'INR', includeInTotals: true },
  'Cash Wallet': { type: 'Cash', color: '#EF6C00', last4: '0000', currency: 'INR', includeInTotals: true },
  'Savings Account': { type: 'Bank', color: '#2E7D32', last4: '8802', currency: 'INR', includeInTotals: true },
  'Raj Card': { type: 'Card', color: '#1565C0', last4: '7781', currency: 'INR', includeInTotals: true },
  'Wise EUR': { type: 'Wallet', color: '#8E24AA', last4: '2231', currency: 'EUR', includeInTotals: false },
  'Monzo GBP': { type: 'Card', color: '#00838F', last4: '5540', currency: 'GBP', includeInTotals: false },
};

function baseTx(tx) {
  const currency = tx.currency || 'INR';
  const amount = Number(tx.amount) || 0;
  return {
    id: tx.id,
    title: tx.title || 'Untitled transaction',
    type: tx.type || 'expense',
    transfer: Boolean(tx.transfer || tx.type === 'transfer'),
    amount,
    currency,
    baseAmount: tx.baseAmount != null ? Number(tx.baseAmount) : toINR(amount, currency),
    date: tx.date || TODAY,
    time: tx.time || '1:03 AM',
    account: tx.account || ACCOUNT_NAMES[0],
    from: tx.from || null,
    to: tx.to || null,
    category: tx.category || '',
    budgetId: tx.budgetId || null,
    loanId: tx.loanId || null,
    goalId: tx.goalId || null,
    person: tx.person || '',
    place: tx.place || '',
    labels: tx.labels || [],
    icon: tx.icon || { bg: '#7B4028', fg: '#FFFFFF', glyph: 'wallet' },
    chips: tx.chips || [],
    notes: tx.notes || '',
    includeInCashFlow: tx.includeInCashFlow !== false,
    includeInAccounts: tx.includeInAccounts !== false,
    includeInCharts: tx.includeInCharts !== false,
  };
}

/* ---------- relational loan / goal ledger from Step 4 ----------
   It stays in `transactions` so loan/goal progress is derived from one
   source of truth, but the seeded rows are not part of the personal cash
   flow charts (they are USD ledger entries). New linked transactions
   created in the universal editor DO affect cash flow and accounts. */
const step4Ledger = seedTransactions.map((t) => {
  const currency = t.currency || (t.converted ? 'USD' : 'USD');
  return {
    ...baseTx({ ...t, currency }),
    converted: t.converted,
    charge: t.charge,
    includeInCashFlow: false,
    includeInAccounts: false,
    includeInCharts: false,
  };
});

/* ---------- deterministic personal cash-flow ledger ---------- */

const expenseCats = expenseCategories.map((c) => c.name);
const incomeCats = incomeCategories.map((c) => c.name);
const accountsCycle = ACCOUNT_NAMES.slice(0, 5);
const peopleCycle = PEOPLE.map((p) => p.name);
const placesCycle = PLACES.map((p) => p.name);
const labelsCycle = LABELS.map((l) => l.name);

function generatedTx(i, date, type, amount, overrides = {}) {
  const category = type === 'income' ? incomeCats[i % incomeCats.length] : expenseCats[i % expenseCats.length];
  const account = accountsCycle[i % accountsCycle.length];
  const budgetId = i % 4 === 0 ? 'food' : i % 4 === 1 ? 'transport' : null;
  return baseTx({
    id: `tx-live-${String(i).padStart(3, '0')}`,
    title: type === 'income' ? `Income ${i + 1}` : `Expense ${i + 1}`,
    type,
    amount,
    currency: 'INR',
    date,
    time: `${String(9 + (i % 10)).padStart(2, '0')}:${String((i * 7) % 60).padStart(2, '0')}`,
    account,
    category,
    budgetId,
    person: peopleCycle[i % peopleCycle.length],
    place: placesCycle[i % placesCycle.length],
    labels: [labelsCycle[i % labelsCycle.length]],
    icon: { bg: type === 'income' ? '#43A047' : '#E91E63', fg: '#FFFFFF', glyph: type === 'income' ? 'user' : 'cash' },
    ...overrides,
  });
}

const ledger = [];

/* 71 older transactions, all before the previous-month window. */
for (let i = 0; i < 71; i += 1) {
  const date = addDays(TODAY, -(38 + (i % 71)));
  const type = i % 4 === 0 ? 'income' : 'expense';
  const amount = Number((18 + ((i * 37) % 420) + (i % 3) * 0.25).toFixed(2));
  ledger.push(generatedTx(i, date, type, amount));
}

/* 20 previous-month transactions: income ₹295, expense ₹708. */
for (let i = 0; i < 20; i += 1) {
  const date = addDays(TODAY, -(29 - i));
  const type = i % 2 === 0 ? 'income' : 'expense';
  const amount = type === 'income' ? 29.5 : 70.8;
  ledger.push(generatedTx(100 + i, date, type, amount, {
    title: type === 'income' ? `October income ${i / 2 + 1}` : `October expense ${(i - 1) / 2 + 1}`,
    category: type === 'income' ? 'Salary' : 'Food & Dining',
  }));
}

/* Current month: income ₹7,114 and expense ₹1,925 up to today. */
ledger.push(generatedTx(200, CURRENT_MONTH.start, 'income', 7114, {
  title: 'Monthly salary',
  category: 'Salary',
  account: 'Kotak Mahindra Bank',
  person: 'Raj',
  place: 'Work',
  labels: ['Work'],
}));
ledger.push(generatedTx(201, CURRENT_MONTH.start, 'expense', 1720, {
  title: 'Rent & utilities',
  category: 'Bills & Utilities',
  account: 'HDFC Bank',
  budgetId: null,
  place: 'Home',
  labels: ['Personal'],
}));
const weekAmounts = [18, 95, 18, 18, 18, 38];
weekAmounts.forEach((amount, i) => {
  ledger.push(generatedTx(202 + i, addDays(CURRENT_MONTH.start, 1 + i), 'expense', amount, {
    title: ['Monday coffee', 'Tuesday groceries', 'Wednesday metro', 'Thursday snack', 'Friday fuel', 'Saturday market'][i],
    category: i === 4 ? 'Transportation' : 'Food & Dining',
    budgetId: i === 4 ? 'transport' : 'food',
    account: i % 2 ? 'Cash Wallet' : 'Raj Card',
    place: i % 2 ? 'Work' : 'Home',
    labels: [i % 2 ? 'Work' : 'Personal'],
  }));
});

/* Future-dated rows appear automatically in Upcoming transactions. */
const future = [
  {
    id: 'tx-future-coffee', title: 'Coffee with team', date: addDays(TODAY, 4), amount: 18,
    currency: 'INR', account: 'Raj Card', category: 'Food & Dining', budgetId: 'food',
    icon: { bg: '#FB8C00', fg: '#1F1F1F', glyph: 'piggy' }, accountTone: 'orange',
  },
  {
    id: 'tx-future-uber', title: 'Uber ride', date: addDays(TODAY, 4), amount: 272,
    currency: 'EUR', converted: 295.65, account: 'Wise EUR', category: 'Transportation', budgetId: 'transport',
    icon: { bg: '#E91E63', fg: '#FFFFFF', glyph: 'calc' }, accountTone: 'red',
  },
  {
    id: 'tx-future-fuel', title: 'Fuel refill', date: addDays(TODAY, 5), amount: 72,
    currency: 'INR', account: 'Kotak Mahindra Bank', category: 'Transportation', budgetId: 'transport',
    icon: { bg: '#4CAF50', fg: '#FFFFFF', glyph: 'trend' }, accountTone: 'teal',
  },
  {
    id: 'tx-future-movie', title: 'Movie tickets', date: addDays(TODAY, 6), amount: 153,
    currency: 'GBP', converted: 193.67, account: 'Monzo GBP', category: 'Entertainment',
    icon: { bg: '#8E24AA', fg: '#FFFFFF', glyph: 'wallet' }, accountTone: 'blue',
  },
];
future.forEach((f, i) => {
  ledger.push(baseTx({
    ...f,
    type: 'expense',
    time: i === 0 ? '12:00 AM' : '12:56 AM',
    person: PEOPLE[i % 3].name,
    place: PLACES[i % 3].name,
    labels: [LABELS[i % 3].name],
    chips: [],
  }));
});

export const SAMPLE_TRANSACTIONS = [...ledger, ...step4Ledger];

/* ---------- accounts ---------- */

function accountDelta(name) {
  let delta = 0;
  SAMPLE_TRANSACTIONS.forEach((t) => {
    if (t.includeInAccounts === false) return;
    const amt = t.baseAmount || 0;
    if (t.type === 'transfer') {
      if (t.from === name) delta -= amt;
      if (t.to === name) delta += amt;
    } else if (t.account === name) {
      delta += t.type === 'income' ? amt : -amt;
    }
  });
  return delta;
}

const TARGET_ACCOUNTS_TOTAL = 1480000;
const TARGET_HERO_TOTAL = 855933.46;
const accountWeights = [0.44, 0.22, 0.13, 0.12, 0.09, 0, 0];

export const SAMPLE_ACCOUNTS = ACCOUNT_NAMES.map((name, i) => {
  const meta = ACCOUNT_META[name];
  const raw = step2Accounts.find((a) => a.name === name) || {};
  return {
    id: `ac-${i + 1}`,
    name,
    holder: 'Raj',
    last4: meta.last4 || raw.last4 || '0000',
    type: meta.type || raw.kind || 'Bank',
    color: meta.color || raw.tile || '#7B4028',
    accent: meta.color || raw.tile || '#7B4028',
    currency: meta.currency || 'INR',
    includeInTotals: meta.includeInTotals,
    openingBalance: TARGET_ACCOUNTS_TOTAL * accountWeights[i] - accountDelta(name),
    icon: raw.icon || 'bank',
    surface: raw.surface || '#F3E1D7',
  };
});

/* ---------- budgets ---------- */

export const SAMPLE_BUDGETS = step2Budgets.map((b, i) => ({
  id: b.id,
  name: b.name,
  limit: Number(b.total || b.spent + b.remaining || 0),
  for: 'Expense',
  type: 'Category',
  mode: b.mode === 'Manual' ? 'Manual' : 'Automatic',
  period: 'Monthly',
  start: CURRENT_MONTH.start,
  end: CURRENT_MONTH.end,
  categories: [i === 0 ? 'Transportation' : 'Food & Dining'],
  color: b.tile || '#3949AB',
  accent: b.accent || '#3949AB',
  surface: b.surface || '#D3D4E6',
  track: b.trackColor || '#B0B2C4',
}));

/* ---------- assets ---------- */

export const SAMPLE_ASSETS = step3Assets.map((a) => ({
  id: a.id,
  name: a.name,
  type: a.type || 'Other',
  value: Number(a.value) || 0,
  purchasePrice: a.purchase == null ? '' : Number(a.purchase),
  units: Number(a.units) || 1,
  unitName: a.unit || '',
  description: a.note || '',
  currency: 'USD',
  primary: a.primary || '#00796B',
  accent: a.accent || '#009688',
}));

/* ---------- bills ---------- */

export const SAMPLE_BILLS = billSplitters.map((b) => ({
  ...b,
  participants: b.participants.map((p) => ({ ...p })),
}));

/* ---------- templates / recurring / achievements ---------- */

export const SAMPLE_TEMPLATES = [
  { id: 't1', name: 'Morning Coffee', amount: 4.5, type: 'expense', category: 'Food & Dining', color: '#7D6054' },
  { id: 't2', name: 'Grocery Run', amount: 65, type: 'expense', category: 'Food & Dining', color: '#43A047' },
  { id: 't3', name: 'Metro Card', amount: 18, type: 'expense', category: 'Transportation', color: '#1E88E5' },
];

export const SAMPLE_RECURRING = [
  { id: 'r1', name: 'Netflix', amount: 499, date: `${CURRENT_MONTH.start.slice(0, 7)}-05`, account: 'HDFC Bank', category: 'Entertainment' },
  { id: 'r2', name: 'Gym membership', amount: 69, date: `${CURRENT_MONTH.start.slice(0, 7)}-12`, account: 'Cash Wallet', category: 'Health & Fitness' },
];

export const SAMPLE_ACHIEVEMENTS = [
  { id: 'a1', title: 'Day One', date: TODAY, unlocked: true },
  { id: 'a2', title: 'First budget', date: TODAY, unlocked: true },
];

export const HOME_SECTIONS = [
  { id: 'overview', label: 'Overview' },
  { id: 'templates', label: 'Templates' },
  { id: 'calendar', label: 'Calendar heatmap' },
  { id: 'trend', label: 'Trend' },
  { id: 'budgets', label: 'Track budgets' },
  { id: 'upcoming', label: 'Upcoming transactions' },
];

export function makeInitialLiveState() {
  return {
    profile: {
      name: 'Raj',
      photo: '',
      baseCurrency: 'INR',
      liabilitiesOffset: TARGET_HERO_TOTAL - TARGET_ACCOUNTS_TOTAL,
    },
    language: 'en',
    onboarding: {
      // SSR/test environments render the dashboard; a real first browser
      // launch has no saved onboarding object and starts at step 1/14.
      completed: typeof window === 'undefined',
      step: 1,
      entry: null,
    },
    privacy: false,
    theme: 'light',
    today: TODAY,
    toast: null,
    greeting: 'Good late night',
    status: { backup: true, cloudBackup: false, notification: false, notifications: false, rating: 5, recurring: 2, feedback: '' },
    user: { name: 'Raj' }, // compatibility with older widgets

    accounts: SAMPLE_ACCOUNTS,
    transactions: SAMPLE_TRANSACTIONS,
    categories: CATEGORIES,
    budgets: SAMPLE_BUDGETS,
    assets: SAMPLE_ASSETS,
    bills: SAMPLE_BILLS,
    loans: seedLoans.map((l) => ({ ...l })),
    goals: seedGoals.map((g) => ({ ...g })),
    templates: SAMPLE_TEMPLATES,
    people: PEOPLE.map((p) => ({ ...p })),
    places: PLACES.map((p) => ({ ...p })),
    labels: LABELS.map((l) => ({ ...l })),
    recurring: SAMPLE_RECURRING.map((r) => ({ ...r })),
    achievements: SAMPLE_ACHIEVEMENTS.map((a) => ({ ...a })),
    homeSections: HOME_SECTIONS.map((s) => s.id),

    nav: { active: 'home', tabs: ['home', 'accounts', 'reports', 'search'] },
    route: { view: 'home', params: {} },
    reportsUi: {
      month: 'Nov 26', chartMode: 'bars', dimension: 'Category',
      type: 'Expense', menuOpen: false, donutExpanded: true,
    },
    accountsUi: { slide: 0 },
    budgetsUi: { slide: 0, showOnHome: true, bentoSlide: 0, tab: 'active' },
    howBudgetsOpen: false,
    assetsUi: { howOpen: false, editor: null },
    billsUi: { tab: 'active', howOpen: false, balancesOpen: false, menuFor: null, editOpen: false, editId: null },
    loansUi: {
      tab: 'lending', howOpen: false, sort: 'name', addOpen: false, editId: null,
      payFor: null, quickAdd: false, historyPeriod: 'daily', detailsTab: 'daily',
    },
    goalsUi: {
      tab: 'active', sort: 'name', sortOpen: false, howOpen: false,
      detailsTab: 'daily', editId: null, depositOpen: false,
    },
    ui: {
      modal: null,
      modalData: null,
      layoutOpen: false,
    },
  };
}

export { accountCatalog, contacts, PREV_MONTH };
