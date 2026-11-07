/* ============================================================
   demoStore — single source of truth for the Home Dashboard.
   A tiny observable store (useSyncExternalStore-compatible) so every
   widget re-renders from one place. Later steps (Accounts, Reports,
   Search, Add-Transaction) mutate this same store.
   ============================================================ */

import { toCents, fromCents, loanState } from './engine.js';
import {
  assets as seedAssets,
  billSplitters as seedBills,
  loans as seedLoans,
  DEMO_TODAY,
} from './step3Data.js';

const listeners = new Set();

/* ---------- formatting engine (Indian numbering) ---------- */

export const maskChar = '•';

/** Full Indian grouping: 855933.46 -> 8,55,933.46 */
export function inrGroup(num) {
  const neg = num < 0;
  const [intPart, decPart] = Math.abs(num).toFixed(2).split('.');
  const last3 = intPart.slice(-3);
  const rest = intPart.slice(0, -3);
  const grouped = rest ? `${rest.replace(/\B(?=(\d{2})+(?!\d))/g, ',')},${last3}` : last3;
  return `${neg ? '-' : ''}${grouped}${decPart ? `.${decPart}` : ''}`;
}

/** ₹8,55,933.46 — sign always precedes the symbol: -₹32,476.74 */
export function fmtFull(num) {
  const neg = num < 0;
  return `${neg ? '-' : ''}₹${inrGroup(Math.abs(num))}`;
}

/** Compact Indian KPI: 1480000 -> ₹14.8L , 14800 -> ₹14.8K , 506000 -> ₹5.06L */
export function fmtCompact(num, { decimals } = {}) {
  const neg = num < 0;
  const abs = Math.abs(num);
  let out;
  const trim = (v) => {
    // keep at most 2 decimals, drop trailing zeros
    const s = v.toFixed(2).replace(/\.?0+$/, '');
    return s;
  };
  if (abs >= 1e7) out = `${trim(abs / 1e7)}Cr`;
  else if (abs >= 1e5) out = `${trim(abs / 1e5)}L`;
  else if (abs >= 1e3) out = `${trim(abs / 1e3)}K`;
  else out = trim(abs);
  if (decimals != null && !/[A-Za-z]/.test(out)) out = abs.toFixed(decimals);
  return `${neg ? '-' : ''}₹${out}`;
}

/** ₹0.0 style — always one decimal, for amounts under 1e3 */
export function fmtShort(num, decimals = 1) {
  const neg = num < 0;
  const abs = Math.abs(num);
  let out;
  if (abs >= 1e5) out = `${(abs / 1e5).toFixed(2).replace(/\.?0+$/, '')}L`;
  else if (abs >= 1e3) out = `${(abs / 1e3).toFixed(1).replace(/\.0$/, '')}K`;
  else out = abs.toFixed(decimals);
  return `${neg ? '-' : ''}₹${out}`;
}

/** $14,188.00 — western grouping, used by the Accounts / Reports / Budgets views */
export function usd(num, decimals = 2) {
  const neg = num < 0;
  const abs = Math.abs(num);
  const s = abs.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
  return `${neg ? '-' : ''}$${s}`;
}

export function fmtThousands(num) {
  return `${num < 0 ? '-' : ''}₹${Math.abs(num).toLocaleString('en-IN')}`;
}

const MASK = `₹${'•'.repeat(6)}`;

/** Privacy-aware formatters — used by components via the store. */
export function money(store, fn, ...args) {
  if (store.privacy) {
    const raw = fn(...args);
    return raw.startsWith('-') ? `-${MASK}` : MASK;
  }
  return fn(...args);
}

/* ---------- seed data (mirrors the reference screenshots) ---------- */

const initialState = {
  privacy: false,
  user: { name: 'Demo User' },
  greeting: 'Good late night',
  status: { backup: true, notifications: false, rating: true, recurring: 2 },

  balance: {
    total: 855933.46,
    income: { now: 7114.0, prev: 295.0, deltaPct: 2312 },
    expense: { now: 1925.0, prev: 708.0, deltaPct: 172 },
  },

  overview: {
    accounts: { count: 5, total: 1480000 },
    reports: { count: 120, total: 14800 },
    budgets: {
      count: 2,
      slide: 0,
      detail: { total: 0, remaining: -24900, spent: 24900 },
    },
    assets: { count: 2, total: 506000 },
    billSplitter: { bills: 2, active: 1, total: 206 },
    loans: { lending: 0, borrowing: 2, balance: -79100 },
    goals: { active: 2, progressed: -36400, target: 49800 },
    labels: { count: 2, top: 'Personal', topTotal: 353 },
    analyticsMonth: { value: 1490, deltaPct: 169.9 },
    recurring: { active: 2, monthly: 568 },
    categories: {
      count: 15,
      top: [
        { label: 'Entertainment', total: 0, icon: 'user', color: '#1976D2' },
        { label: 'Health & Fitness', total: 0, icon: 'dollar', color: '#7B4028' },
        { label: 'Personal Care', total: 0, icon: 'wallet', color: '#7B1FA2' },
      ],
    },
    weekly: {
      thisWeek: 82.0,
      lastWeek: 69.0,
      days: [
        { d: 'Mon', v: 18 },
        { d: 'Tue', v: 95 },
        { d: 'Wed', v: 18 },
        { d: 'Thu', v: 18 },
        { d: 'Fri', v: 18 },
        { d: 'Sat', v: 18 },
        { d: 'Sun', v: 38 },
      ],
      highlight: 'Sat',
    },
    last30: { total: 370, deltaPct: -53, series: [8, 34, 34, 62, 62, 84, 84, 100] },
    places: { count: 2, top: 'Work', topTotal: 200 },
    person: { count: 2, top: 'Bob', topTotal: 296 },
    habit: { score: 60, streakDays: 7, legend: [
      { label: 'Water', color: '#D32F2F' },
      { label: 'Phone', color: '#388E3C' },
      { label: 'Gas', color: '#388E3C' },
    ] },
    achievements: {
      unlocked: 6,
      total: 37,
      pct: 16,
      last: { title: 'Day One', date: 'Nov 7' },
    },
  },

  templates: [
    { id: 't1', name: 'Morning Coffee', amount: 4.5, type: 'expense', color: '#7D6054' },
    { id: 't2', name: 'Grocery Run', amount: 65.0, type: 'expense', color: '#43A047' },
    { id: 't3', name: 'Metro Card', amount: 0, type: 'expense', color: '#1E88E5' },
  ],

  heatmap: {
    month: 'Nov 2026',
    today: 7,
    octoberTail: [
      [2, 3, 4],
      [9, 10, 11],
      [16, 17, 18],
      [23, 24, 25],
      [30, 31, null],
    ],
    octLevels: { 2: 1, 3: 0, 4: 0, 9: 0, 10: 0, 11: 0, 16: 0, 17: 1, 18: 0, 23: 0, 24: 0, 25: 1, 30: 0, 31: 0 },
    // week rows for Nov: leading blanks then day numbers
    november: [
      [null, null, null, null, null, null, 1],
      [2, 3, 4, 5, 6, 7, 8],
      [9, 10, 11, 12, 13, 14, 15],
      [16, 17, 18, 19, 20, 21, 22],
      [23, 24, 25, 26, 27, 28, 29],
      [30, null, null, null, null, null, null],
    ],
    novLevels: {
      1: 1, 2: 1, 3: 1, 4: 1, 5: 0, 6: 0, 7: 0, 8: 1, 9: 0, 10: 0, 11: 1, 12: 1,
      13: 2, 14: 1, 15: 0, 16: 1, 17: 1, 18: 1, 19: 0, 20: 1, 21: 0, 22: 2,
      23: 0, 24: 1, 25: 1, 26: 0, 27: 0, 28: 1, 29: 0, 30: 0,
    },
  },

  trend: {
    yLabels: [25000, 20000, 15000, 10000, 5000, 0, -5000],
    today: 7,
    thisMonth: { from: 1, to: 7, value: 6500 },
    upcoming: [6500, 6500, 8300, 8300, 8300, 8300, 9200, 9200, 9200, 10400, 10400, 10400, 11600, 11600, 13200, 14500, 14500, 15700, 15700, 16800],
  },

  budgets: {
    slide: 0,
    items: [
      {
        id: 'b1',
        name: 'Food Budget',
        period: 'Monthly',
        status: 'Over budget',
        accent: '#FB8C00',
        pct: 100,
        ringColor: '#E53935',
        budget: 2602.0,
        spent: 96.0,
        remaining: -32476.74,
      },
      {
        id: 'b2',
        name: 'Transportation Budget',
        period: 'Monthly',
        status: 'Over budget',
        accent: '#E53935',
        pct: 100,
        ringColor: '#E53935',
        budget: 4180.0,
        spent: 4180.0,
        remaining: -1285.5,
      },
    ],
  },

  upcoming: [
    {
      id: 'u1',
      title: 'Coffee with team',
      time: '12:00 AM',
      when: 'Tomorrow',
      account: 'Demo Bank',
      accountTone: 'orange',
      icon: 'piggy',
      iconBg: '#FB8C00',
      iconFg: '#1F1F1F',
      amount: 18.0,
      currency: 'INR',
      chips: [
        { label: 'Food Budget', bg: '#F9E7C8', fg: '#7A5A20' },
        { label: 'Home', bg: '#E8D7F1', fg: '#5B3B6E' },
        { label: 'Personal', bg: '#D9E2F8', fg: '#31456B', icon: 'bank' },
        { label: 'Work', bg: '#C8ECE5', fg: '#1F5A4E', icon: 'trend' },
      ],
    },
    {
      id: 'u2',
      title: 'Uber ride',
      time: '12:56 AM',
      when: 'Nov 11',
      account: 'Wise EUR',
      accountTone: 'red',
      icon: 'calc',
      iconBg: '#E91E63',
      iconFg: '#FFFFFF',
      amount: 272.0,
      currency: 'EUR',
      converted: 295.65,
      chips: [
        { label: 'Transportation Budget', bg: '#FADAD8', fg: '#8C2B26' },
        { label: 'Car Loan', bg: '#F8D7DA', fg: '#8C2B26' },
        { label: 'Bob', bg: '#D4EDDA', fg: '#256029' },
      ],
    },
    {
      id: 'u3',
      title: 'Fuel refill',
      time: '12:00 AM',
      when: 'Nov 12',
      account: 'Demo Bank',
      accountTone: 'orange',
      icon: 'arrow',
      iconBg: '#4CAF50',
      iconFg: '#FFFFFF',
      amount: 72.0,
      currency: 'INR',
      chips: [
        { label: 'Transportation Budget', bg: '#FADAD8', fg: '#8C2B26' },
        { label: 'Personal', bg: '#D9E2F8', fg: '#31456B', icon: 'bank' },
        { label: 'Work', bg: '#C8ECE5', fg: '#1F5A4E', icon: 'trend' },
      ],
    },
    {
      id: 'u4',
      title: 'Movie tickets',
      time: '12:56 AM',
      when: 'Nov 13',
      account: 'Monzo GBP',
      accountTone: 'blue',
      icon: 'wallet',
      iconBg: '#8E24AA',
      iconFg: '#FFFFFF',
      amount: 153.0,
      currency: 'GBP',
      converted: 193.67,
      chips: [
        { label: 'Work', bg: '#DCE4EC', fg: '#31456B' },
        { label: 'Alice', bg: '#D4EDDA', fg: '#256029' },
        { label: 'Personal', bg: '#D9E2F8', fg: '#31456B', icon: 'bank' },
        { label: 'Work', bg: '#C8ECE5', fg: '#1F5A4E', icon: 'trend' },
      ],
    },
  ],

  nav: { active: 'home', tabs: ['home', 'accounts', 'reports', 'search'] },

  /* ---------- Step 2 view state ---------- */
  route: { view: 'home', params: {} }, // home | accounts | reports | budgets | budgetDetail
  reportsUi: {
    month: 'Nov 26',
    chartMode: 'bars', // bars | line
    dimension: 'Category', // Category | Account | Label | Person | Places
    type: 'Expense', // Expense | Income
    menuOpen: false,
    donutExpanded: true,
  },
  accountsUi: { slide: 0 },
  budgetsUi: { slide: 0, showOnHome: true },

  /* ---------- Step 3 ---------- */
  theme: 'light', // light | dark
  assets: seedAssets,
  assetsUi: { howOpen: false, editor: null },
  bills: seedBills,
  billsUi: { tab: 'active', howOpen: false, balancesOpen: false, menuFor: null, editOpen: false, editId: null },
  loans: seedLoans,
  loansUi: { tab: 'lending', howOpen: false, sort: 'name', addOpen: false, editId: null, payFor: null },
  today: DEMO_TODAY,
  toast: null,
  howBudgetsOpen: false,
};

/* ---------- store core ---------- */

let state = initialState;
const history = [];

function emit() {
  listeners.forEach((l) => l(state));
}

export const demoStore = {
  getState: () => state,
  subscribe(fn) {
    listeners.add(fn);
    return () => listeners.delete(fn);
  },
  /** shallow-merge patch at the top level */
  set(patch) {
    history.push(state);
    state = { ...state, ...(typeof patch === 'function' ? patch(state) : patch) };
    emit();
  },
  /** deep-ish setter by dotted path: demoStore.setIn('overview.budgets.slide', 1) */
  setIn(path, value) {
    history.push(state);
    const keys = path.split('.');
    const clone = { ...state };
    let cursor = clone;
    for (let i = 0; i < keys.length - 1; i += 1) {
      cursor[keys[i]] = { ...cursor[keys[i]] };
      cursor = cursor[keys[i]];
    }
    cursor[keys[keys.length - 1]] = value;
    state = clone;
    emit();
  },
  undo() {
    const prev = history.pop();
    if (prev) {
      state = prev;
      emit();
    }
  },

  /* ---- actions ---- */
  togglePrivacy() {
    demoStore.setIn('privacy', !state.privacy);
  },
  setNav(tab) {
    demoStore.setIn('nav.active', tab);
  },

  /* ---------- routing ---------- */
  go(view, params = {}) {
    demoStore.set({ route: { view, params } });
    if (view === 'accounts') demoStore.setIn('nav.active', 'accounts');
    if (view === 'reports') demoStore.setIn('nav.active', 'reports');
    if (view === 'home') demoStore.setIn('nav.active', 'home');
  },
  back() {
    const v = state.route.view;
    if (v === 'budgetDetail') return demoStore.go('budgets');
    if (v === 'assetEditor') return demoStore.go('assets');
    if (v === 'billDetails') return demoStore.go('billSplitter');
    if (v === 'billEditor') return demoStore.go('billSplitter');
    if (v === 'loanDetails') return demoStore.go('loans');
    if (v === 'loanEditor') return demoStore.go('loans');
    return demoStore.go('home');
  },

  /* ---------- reports ---------- */
  setReportMonth(month) {
    demoStore.setIn('reportsUi.month', month);
  },
  setChartMode(mode) {
    demoStore.setIn('reportsUi.chartMode', mode);
  },
  toggleCategoryMenu() {
    demoStore.setIn('reportsUi.menuOpen', !state.reportsUi.menuOpen);
  },
  setDimension(dim) {
    demoStore.set({
      reportsUi: { ...state.reportsUi, dimension: dim, menuOpen: false },
    });
  },
  toggleReportType() {
    const next = state.reportsUi.type === 'Expense' ? 'Income' : 'Expense';
    demoStore.setIn('reportsUi.type', next);
  },
  toggleDonut() {
    demoStore.setIn('reportsUi.donutExpanded', !state.reportsUi.donutExpanded);
  },

  /* ---------- accounts / budgets ---------- */
  setAccountSlide(i) {
    demoStore.setIn('accountsUi.slide', i);
  },
  setBudgetSlide(i) {
    demoStore.setIn('budgetsUi.slide', i);
  },
  toggleShowBudget() {
    demoStore.setIn('budgetsUi.showOnHome', !state.budgetsUi.showOnHome);
  },
  cycleBudgetBento() {
    const next = state.overview.budgets.slide === 0 ? 1 : 0;
    demoStore.setIn('overview.budgets.slide', next);
  },
  cycleBudgetCarousel() {
    const next = state.budgets.slide === 0 ? 1 : 0;
    demoStore.setIn('budgets.slide', next);
  },
  toast(message) {
    demoStore.setIn('toast', { message, at: Date.now() });
    const at = Date.now();
    setTimeout(() => {
      if (state.toast && state.toast.at === at) demoStore.setIn('toast', null);
    }, 2200);
  },
  addTransaction(tx) {
    demoStore.setIn('upcoming', [tx, ...state.upcoming]);
  },
  openHowBudgets(open = true) {
    demoStore.setIn('howBudgetsOpen', open);
  },
  /* ---------- theme ---------- */
  toggleTheme() {
    const next = state.theme === 'light' ? 'dark' : 'light';
    demoStore.setIn('theme', next);
  },

  /* ---------- assets ---------- */
  openAssetsHow(open = true) {
    demoStore.setIn('assetsUi.howOpen', open);
  },
  editAsset(id) {
    demoStore.set({
      route: { view: 'assetEditor', params: { id } },
      assetsUi: { ...state.assetsUi, editor: id },
    });
  },
  newAsset() {
    demoStore.set({
      route: { view: 'assetEditor', params: {} },
      assetsUi: { ...state.assetsUi, editor: null },
    });
  },
  saveAsset(asset) {
    const exists = state.assets.some((a) => a.id === asset.id);
    const next = exists
      ? state.assets.map((a) => (a.id === asset.id ? asset : a))
      : [...state.assets, asset];
    demoStore.set({ assets: next });
    demoStore.go('assets');
    demoStore.toast(exists ? 'Asset updated' : 'Asset added');
  },
  deleteAsset(id) {
    demoStore.set({ assets: state.assets.filter((a) => a.id !== id) });
    demoStore.go('assets');
    demoStore.toast('Asset deleted');
  },

  /* ---------- bill splitters ---------- */
  setBillsTab(tab) {
    demoStore.setIn('billsUi.tab', tab);
  },
  openBillsHow(open = true) {
    demoStore.setIn('billsUi.howOpen', open);
  },
  openNetBalances(open = true) {
    demoStore.setIn('billsUi.balancesOpen', open);
  },
  openParticipantMenu(id) {
    demoStore.setIn('billsUi.menuFor', state.billsUi.menuFor === id ? null : id);
  },
  closeParticipantMenu() {
    demoStore.setIn('billsUi.menuFor', null);
  },
  /** Mark a participant as having paid their full share. */
  markParticipantPaid(billId, participantId) {
    demoStore.set({
      bills: state.bills.map((b) => {
        if (b.id !== billId) return b;
        return {
          ...b,
          participants: b.participants.map((p) => {
            if (p.id !== participantId) return p;
            const share =
              b.mode === 'equal'
                ? fromCents(Math.round((toCents(b.total) / b.participants.length)))
                : toCents(p.share) / 100;
            return { ...p, paid: share };
          }),
        };
      }),
    });
    demoStore.setIn('billsUi.menuFor', null);
  },
  /** Record a custom payment for one participant. */
  setParticipantPaid(billId, participantId, amount) {
    demoStore.set({
      bills: state.bills.map((b) =>
        b.id === billId
          ? {
              ...b,
              participants: b.participants.map((p) =>
                p.id === participantId ? { ...p, paid: Number(amount) || 0 } : p,
              ),
            }
          : b,
      ),
    });
  },
  settleBill(billId) {
    demoStore.set({
      bills: state.bills.map((b) =>
        b.id === billId
          ? {
              ...b,
              participants: b.participants.map((p) => {
                const share =
                  b.mode === 'equal'
                    ? fromCents(Math.round(toCents(b.total) / b.participants.length))
                    : toCents(p.share) / 100;
                return { ...p, paid: share };
              }),
            }
          : b,
      ),
    });
    demoStore.toast('Bill settled');
  },
  deleteBill(billId) {
    demoStore.set({ bills: state.bills.filter((b) => b.id !== billId) });
    demoStore.go('billSplitter');
    demoStore.toast('Bill deleted');
  },
  saveBill(bill) {
    const exists = state.bills.some((b) => b.id === bill.id);
    demoStore.set({
      bills: exists ? state.bills.map((b) => (b.id === bill.id ? bill : b)) : [bill, ...state.bills],
    });
    demoStore.go('billSplitter');
    demoStore.toast(exists ? 'Bill updated' : 'Bill created');
  },

  /* ---------- loans ---------- */
  setLoansTab(tab) {
    demoStore.setIn('loansUi.tab', tab);
  },
  openLoansHow(open = true) {
    demoStore.setIn('loansUi.howOpen', open);
  },
  toggleLoanSort() {
    demoStore.setIn('loansUi.sort', state.loansUi.sort === 'name' ? 'amount' : 'name');
  },
  /** Record a payment; auto-completes the loan when fully paid. */
  recordLoanPayment(loanId, amount) {
    demoStore.set({
      loans: state.loans.map((l) => {
        if (l.id !== loanId) return l;
        const nextPaid = Math.min(toCents(l.total), toCents(l.paid) + toCents(amount));
        return { ...l, paid: fromCents(nextPaid) };
      }),
    });
    demoStore.setIn('loansUi.payFor', null);
    const loan = state.loans.find((l) => l.id === loanId);
    const after = loanState({ ...loan, paid: toCents(loan.paid) / 100 + (Number(amount) || 0) }, state.today);
    demoStore.toast(after.completed ? 'Loan completed 🎉' : 'Payment recorded');
  },
  deleteLoan(loanId) {
    demoStore.set({ loans: state.loans.filter((l) => l.id !== loanId) });
    demoStore.go('loans');
    demoStore.toast('Loan deleted');
  },
  saveLoan(loan) {
    const exists = state.loans.some((l) => l.id === loan.id);
    demoStore.set({
      loans: exists ? state.loans.map((l) => (l.id === loan.id ? loan : l)) : [loan, ...state.loans],
    });
    demoStore.go('loans');
    demoStore.toast(exists ? 'Loan updated' : 'Loan created');
  },

  exitDemo() {
    demoStore.set({ privacy: false });
    demoStore.toast('Demo mode — data stays local');
  },
};

export { initialState };
