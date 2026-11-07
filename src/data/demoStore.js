/* ============================================================
   MoneyMate live store.
   One observable state object, persisted to localStorage on every
   change. No component owns a copy of a record: screens consume pure
   selectors from `derive.js` and call these CRUD actions.
   ============================================================ */

import { makeInitialLiveState, TODAY } from './liveData.js';
import { toINR, fromINR } from './format.js';
import { loanMath, goalMath } from './engine.js';
import { LANGUAGE_BY_CODE, languageDirection } from './i18n.js';
import { DEFAULT_AVATAR } from './avatars.js';

export * from './format.js';
export * from './i18n.js';
export * from './avatars.js';
export {
  accountCatalog,
  expenseCategories,
  incomeCategories,
  PERSON_COLORS,
} from './step4Data.js';

export const STORAGE_KEY = 'moneymate.live.v1';
export const BACKUP_VERSION = 1;
export const initialState = makeInitialLiveState();

const listeners = new Set();
const history = [];
let uid = 0;

/** Stable-enough id for newly created records. */
export function makeId(prefix = 'id') {
  uid += 1;
  return `${prefix}-${Date.now().toString(36)}${uid.toString(36)}`;
}

function storage() {
  try {
    if (typeof window === 'undefined' || !window.localStorage) return null;
    return window.localStorage;
  } catch (err) {
    return null;
  }
}

/** Slices that represent user data and therefore get saved. */
const PERSISTED = [
  'profile', 'privacy', 'theme', 'user', 'status', 'language', 'onboarding',
  'accounts', 'transactions', 'categories', 'budgets', 'assets',
  'bills', 'loans', 'goals', 'templates', 'people', 'places',
  'labels', 'recurring', 'achievements', 'homeSections',
];

export function loadPersisted(base = initialState) {
  const ls = storage();
  if (!ls) return base;
  try {
    const raw = ls.getItem(STORAGE_KEY);
    if (!raw) return base;
    const saved = JSON.parse(raw);
    if (!saved || typeof saved !== 'object') return base;
    const next = { ...base, routeStack: [] };
    PERSISTED.forEach((k) => {
      if (saved[k] !== undefined) next[k] = saved[k];
    });
    next.profile = { ...base.profile, ...(saved.profile || {}) };
    next.user = { ...base.user, ...(saved.user || {}), name: next.profile.name };
    next.onboarding = { ...base.onboarding, ...(saved.onboarding || {}) };
    return next;
  } catch (err) {
    return base;
  }
}

let state = loadPersisted(initialState);

function persist(next) {
  const ls = storage();
  if (!ls) return;
  try {
    const payload = {};
    PERSISTED.forEach((k) => {
      if (next[k] !== undefined) payload[k] = next[k];
    });
    ls.setItem(STORAGE_KEY, JSON.stringify(payload));
  } catch (err) {
    /* quota or private mode — the app keeps working in memory */
  }
}

function emit() {
  listeners.forEach((fn) => fn(state));
}

function nowTime() {
  if (typeof window === 'undefined') return '09:00';
  return new Date().toTimeString().slice(0, 5);
}

/** Normalize a transaction so balances/charts never depend on missing fields. */
function normalizeTransaction(tx, base) {
  const amount = Number(tx.amount) || 0;
  const currency = tx.currency || base;
  const inr = toINR(amount, currency);
  const type = tx.type || 'expense';
  return {
    id: tx.id || makeId('tx'),
    title: tx.title || 'Untitled transaction',
    type,
    transfer: type === 'transfer' || Boolean(tx.transfer),
    amount,
    currency,
    baseAmount: inr,
    converted: currency === base ? null : fromINR(inr, base),
    date: tx.date || state.today,
    time: tx.time || nowTime(),
    account: type === 'transfer' ? tx.from || tx.account || state.accounts[0]?.name || '' : tx.account || state.accounts[0]?.name || '',
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
    accountTone: tx.accountTone || 'orange',
    includeInCashFlow: tx.includeInCashFlow !== false,
    includeInAccounts: tx.includeInAccounts !== false,
    includeInCharts: tx.includeInCharts !== false,
  };
}

function clonePath(obj, keys, value) {
  if (!keys.length) return value;
  const [head, ...tail] = keys;
  const base = obj && typeof obj === 'object' ? obj : {};
  return {
    ...(Array.isArray(base) ? [...base] : { ...base }),
    [head]: clonePath(base[head], tail, value),
  };
}

function replaceById(list, item) {
  const exists = list.some((x) => x.id === item.id);
  return exists ? list.map((x) => (x.id === item.id ? item : x)) : [item, ...list];
}

const PARENT_VIEW = {
  budgetDetail: 'budgets', assetEditor: 'assets', billDetails: 'billSplitter',
  billEditor: 'billSplitter', loanDetails: 'loans', loanEditor: 'loans',
  goalDetails: 'goals', goalEditor: 'goals',
};

export const demoStore = {
  getState: () => state,
  subscribe(fn) {
    listeners.add(fn);
    return () => listeners.delete(fn);
  },
  /** Shallow-merge patch at the top level; every call persists + notifies. */
  set(patch) {
    history.push(state);
    state = { ...state, ...(typeof patch === 'function' ? patch(state) : patch) };
    persist(state);
    emit();
  },
  /** Deep-ish setter by dotted path. */
  setIn(path, value) {
    const next = clonePath(state, path.split('.'), value);
    demoStore.set(next);
  },
  undo() {
    if (!history.length) return;
    state = history.pop();
    persist(state);
    emit();
  },

  /* ---------- shell / navigation ---------- */
  togglePrivacy() {
    demoStore.setIn('privacy', !state.privacy);
  },
  toggleTheme() {
    demoStore.setIn('theme', state.theme === 'dark' ? 'light' : 'dark');
  },
  setNav(tab) {
    demoStore.setIn('nav.active', tab);
  },
  go(view, params = {}) {
    const stack = view === state.route.view ? state.routeStack || [] : [...(state.routeStack || []), state.route];
    demoStore.set({
      route: { view, params },
      routeStack: stack,
      nav: { ...state.nav, active: ['home', 'accounts', 'reports', 'search'].includes(view) ? view : 'home' },
    });
    if (typeof window !== 'undefined' && view !== 'home') {
      try { window.history.pushState({ view }, '', `#${view}`); } catch (err) { /* ignore */ }
    }
  },
  back() {
    const stack = state.routeStack || [];
    const previous = stack[stack.length - 1];
    demoStore.set({
      route: previous || { view: 'home', params: {} },
      routeStack: previous ? stack.slice(0, -1) : [],
      nav: { ...state.nav, active: previous && ['home', 'accounts', 'reports', 'search'].includes(previous.view) ? previous.view : 'home' },
    });
  },
  toast(message) {
    demoStore.set({ toast: { message, at: Date.now() } });
    if (typeof window !== 'undefined') {
      window.setTimeout(() => {
        if (state.toast?.message === message) demoStore.set({ toast: null });
      }, 2600);
    }
  },

  /* ---------- generic modal router ---------- */
  openModal(name, data = null) {
    demoStore.set({ ui: { ...state.ui, modal: name, modalData: data } });
  },
  closeModal() {
    demoStore.set({ ui: { ...state.ui, modal: null, modalData: null } });
  },
  openProfile() {
    demoStore.openModal('profile');
  },
  openLayout() {
    demoStore.openModal('layout');
  },
  openFeedback() {
    demoStore.openModal('feedback');
  },
  saveFeedback(text) {
    demoStore.set({ status: { ...state.status, feedback: text } });
  },
  openBalance() {
    demoStore.openModal('balance');
  },
  openCollection(name) {
    demoStore.openModal('collection', { name });
  },
  openReportDetail(id) {
    demoStore.openModal('reportDetail', { id });
  },
  openSearch(query = '') {
    demoStore.go('search', { query });
  },
  setSearchQuery(query) {
    demoStore.set({ route: { view: 'search', params: { query } } });
  },

  /* ---------- profile + data lifecycle ---------- */
  setProfile(patch) {
    const profile = { ...state.profile, ...patch };
    demoStore.set({ profile, user: { ...state.user, name: profile.name } });
  },
  setBaseCurrency(currency) {
    demoStore.setProfile({ baseCurrency: currency });
  },
  setLanguage(code) {
    const language = LANGUAGE_BY_CODE[code] ? code : 'en';
    demoStore.set({ language });
    if (typeof document !== 'undefined') {
      document.documentElement.lang = language;
      document.documentElement.dir = languageDirection(language);
    }
  },
  setProfilePhoto(photo) {
    demoStore.setProfile({ photo: photo || '' });
  },
  setCloudBackup(enabled) {
    demoStore.set({ status: { ...state.status, cloudBackup: Boolean(enabled) } });
  },

  /* ---------- onboarding lifecycle ---------- */
  setOnboarding(patch = {}) {
    demoStore.set({ onboarding: { ...state.onboarding, ...patch } });
  },
  setOnboardingStep(step) {
    const clean = Math.max(1, Math.min(14, Number(step) || 1));
    demoStore.setOnboarding({ step: clean });
  },
  nextOnboardingStep() {
    demoStore.setOnboardingStep(state.onboarding.step + 1);
  },
  previousOnboardingStep() {
    demoStore.setOnboardingStep(state.onboarding.step - 1);
  },
  replayOnboarding(step = 1) {
    demoStore.set({
      onboarding: { completed: false, step: Math.max(1, Math.min(14, Number(step) || 1)), entry: 'profile' },
      route: { view: 'home', params: {} },
      routeStack: [],
      ui: { ...state.ui, modal: null, modalData: null },
    });
  },
  completeOnboarding(patch = {}) {
    if (patch.name != null || patch.photo != null || patch.baseCurrency != null) {
      demoStore.setProfile({
        ...(patch.name != null ? { name: String(patch.name).trim() || 'Raj' } : {}),
        ...(patch.photo != null ? { photo: patch.photo } : {}),
        ...(patch.baseCurrency != null ? { baseCurrency: patch.baseCurrency } : {}),
      });
    }
    if (patch.language) demoStore.setLanguage(patch.language);
    if (patch.theme) demoStore.set({ theme: patch.theme });
    demoStore.set({
      onboarding: { ...state.onboarding, completed: true, step: 14 },
      route: { view: 'home', params: {} },
      routeStack: [],
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Setup complete — welcome to Paisa');
  },
  startOnboardingFresh() {
    demoStore.clearAllData();
    demoStore.setProfile({ name: '', photo: '', baseCurrency: 'INR' });
    demoStore.set({
      onboarding: { completed: false, step: 2, entry: 'fresh' },
      theme: 'light',
      ui: { ...state.ui, modal: null, modalData: null },
    });
  },
  tryDemoMode() {
    demoStore.restoreSampleData();
    demoStore.setProfile({ name: 'Jane Smith', photo: DEFAULT_AVATAR, baseCurrency: 'USD' });
    demoStore.set({
      language: 'en',
      onboarding: { completed: false, step: 2, entry: 'demo' },
      theme: 'light',
      ui: { ...state.ui, modal: null, modalData: null },
    });
  },

  /* ---------- local JSON backup ---------- */
  exportBackup() {
    const data = {};
    PERSISTED.forEach((k) => { data[k] = state[k]; });
    return JSON.stringify({
      app: 'MoneyMate',
      version: BACKUP_VERSION,
      exportedAt: new Date().toISOString(),
      state: data,
    }, null, 2);
  },
  downloadBackup() {
    if (typeof document === 'undefined') return false;
    const blob = new Blob([demoStore.exportBackup()], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `moneymate-backup-${state.today || 'today'}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.setTimeout(() => URL.revokeObjectURL(url), 500);
    demoStore.toast('Local backup exported');
    return true;
  },
  restoreBackup(raw) {
    let backup = raw;
    if (typeof raw === 'string') {
      try { backup = JSON.parse(raw); } catch (err) { return false; }
    }
    const incoming = backup?.state && typeof backup.state === 'object' ? backup.state : backup;
    if (!incoming || typeof incoming !== 'object' || !Array.isArray(incoming.transactions)) return false;
    const fresh = makeInitialLiveState();
    const next = { ...fresh, routeStack: [] };
    PERSISTED.forEach((k) => {
      if (incoming[k] !== undefined) next[k] = incoming[k];
    });
    next.profile = { ...fresh.profile, ...(incoming.profile || {}) };
    next.user = { ...fresh.user, ...(incoming.user || {}), name: next.profile.name };
    next.onboarding = { ...fresh.onboarding, ...(incoming.onboarding || {}), completed: true, step: 14 };
    next.route = { view: 'home', params: {} };
    next.ui = { ...fresh.ui, modal: null, modalData: null };
    demoStore.set(next);
    demoStore.setLanguage(next.language || 'en');
    demoStore.toast('Backup restored — welcome back');
    return true;
  },
  clearAllData() {
    const profile = { ...state.profile, liabilitiesOffset: 0 };
    demoStore.set({
      profile,
      user: { ...state.user, name: profile.name },
      accounts: [],
      transactions: [],
      categories: [],
      budgets: [],
      assets: [],
      bills: [],
      loans: [],
      goals: [],
      templates: [],
      people: [],
      places: [],
      labels: [],
      recurring: [],
      achievements: [],
      ui: { ...state.ui, modal: null, modalData: null, dataMode: 'live' },
    });
    demoStore.go('home');
    demoStore.toast('All data cleared — start fresh');
  },
  restoreSampleData() {
    const fresh = makeInitialLiveState();
    const profile = { ...fresh.profile, name: state.profile.name, baseCurrency: state.profile.baseCurrency };
    demoStore.set({
      ...fresh,
      profile,
      user: { ...fresh.user, name: profile.name },
      privacy: state.privacy,
      theme: state.theme,
      ui: { ...fresh.ui, modal: null, modalData: null },
      route: { view: 'home', params: {} },
      routeStack: [],
    });
    const ls = storage();
    if (ls) { try { ls.removeItem(STORAGE_KEY); } catch (err) { /* ignore */ } }
    persist(state);
    demoStore.toast('Sample records restored');
  },
  startFresh() {
    demoStore.clearAllData();
  },
  toggleHomeSection(id) {
    const has = state.homeSections.includes(id);
    demoStore.set({ homeSections: has ? state.homeSections.filter((x) => x !== id) : [...state.homeSections, id] });
  },

  /* ---------- universal transaction editor ---------- */
  openTransactionEditor(prefill = {}) {
    let data;
    if (typeof prefill === 'string') {
      const existing = state.transactions.find((t) => t.id === prefill);
      data = existing ? { ...existing, editing: true } : { editing: false };
    } else if (prefill?.id && state.transactions.some((t) => t.id === prefill.id)) {
      const existing = state.transactions.find((t) => t.id === prefill.id);
      data = { ...existing, ...prefill, editing: true };
    } else {
      data = {
        editing: false,
        type: 'expense',
        title: '',
        amount: '',
        currency: state.profile.baseCurrency,
        date: state.today,
        time: nowTime(),
        account: state.accounts[0]?.name || '',
        from: state.accounts[0]?.name || '',
        to: state.accounts[1]?.name || state.accounts[0]?.name || '',
        category: '',
        budgetId: null,
        loanId: null,
        goalId: null,
        person: '',
        place: '',
        labels: [],
        ...prefill,
      };
    }
    demoStore.openModal('transaction', data);
  },
  saveTransaction(tx) {
    const clean = normalizeTransaction(tx, state.profile.baseCurrency);
    const exists = state.transactions.some((t) => t.id === clean.id);
    demoStore.set({
      transactions: exists
        ? state.transactions.map((t) => (t.id === clean.id ? clean : t))
        : [clean, ...state.transactions],
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast(exists ? 'Transaction updated' : 'Transaction added');
  },
  addTransaction(tx) {
    demoStore.saveTransaction(tx);
  },
  deleteTransaction(txId) {
    demoStore.set({
      transactions: state.transactions.filter((t) => t.id !== txId),
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Transaction deleted');
  },
  setTransactionType(txId, type) {
    const tx = state.transactions.find((t) => t.id === txId);
    if (tx) demoStore.saveTransaction({ ...tx, type });
  },

  /* ---------- accounts ---------- */
  openAccountEditor(prefill = {}) {
    const existing = typeof prefill === 'string'
      ? state.accounts.find((a) => a.id === prefill)
      : prefill?.id ? state.accounts.find((a) => a.id === prefill.id) : null;
    demoStore.openModal('account', {
      id: existing?.id || makeId('ac'),
      name: existing?.name || '',
      holder: existing?.holder || state.profile.name,
      balance: existing?.openingBalance ?? 0,
      last4: existing?.last4 || '',
      type: existing?.type || 'Bank',
      color: existing?.color || '#00897B',
      currency: existing?.currency || state.profile.baseCurrency,
      includeInTotals: existing?.includeInTotals !== false,
      editing: Boolean(existing),
    });
  },
  saveAccount(account) {
    const clean = {
      id: account.id || makeId('ac'),
      name: account.name || 'New account',
      holder: account.holder || state.profile.name,
      last4: String(account.last4 || '').slice(-4),
      type: account.type || 'Bank',
      color: account.color || '#00897B',
      accent: account.color || '#00897B',
      currency: account.currency || state.profile.baseCurrency,
      includeInTotals: account.includeInTotals !== false,
      openingBalance: Number(account.balance) || 0,
      icon: account.icon || 'bank',
      surface: account.surface || '#F3E1D7',
    };
    demoStore.set({
      accounts: replaceById(state.accounts, clean),
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Account saved');
  },
  deleteAccount(accountId) {
    demoStore.set({
      accounts: state.accounts.filter((a) => a.id !== accountId),
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Account deleted');
  },

  /* ---------- budgets ---------- */
  openBudgetEditor(prefill = {}) {
    const existing = typeof prefill === 'string'
      ? state.budgets.find((b) => b.id === prefill)
      : prefill?.id ? state.budgets.find((b) => b.id === prefill.id) : null;
    demoStore.openModal('budget', {
      id: existing?.id || makeId('bd'),
      name: existing?.name || '',
      limit: existing?.limit ?? '',
      for: existing?.for || 'Expense',
      type: existing?.type || 'Category',
      mode: existing?.mode || 'Automatic',
      period: existing?.period || 'Monthly',
      start: existing?.start || state.today,
      end: existing?.end || state.today,
      categories: existing?.categories || [],
      color: existing?.color || '#3949AB',
      editing: Boolean(existing),
    });
  },
  saveBudget(budget) {
    const clean = {
      id: budget.id || makeId('bd'),
      name: budget.name || 'New budget',
      limit: Number(budget.limit) || 0,
      for: budget.for || 'Expense',
      type: budget.type || 'Category',
      mode: budget.mode || 'Automatic',
      period: budget.period || 'Monthly',
      start: budget.start || state.today,
      end: budget.end || state.today,
      categories: budget.categories || [],
      color: budget.color || '#3949AB',
      accent: budget.color || '#3949AB',
      surface: `${budget.color || '#3949AB'}22`,
      track: `${budget.color || '#3949AB'}55`,
    };
    demoStore.set({
      budgets: replaceById(state.budgets, clean),
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Budget saved');
  },
  deleteBudget(budgetId) {
    demoStore.set({
      budgets: state.budgets.filter((b) => b.id !== budgetId),
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Budget deleted');
  },

  /* ---------- templates + generic collections ---------- */
  openTemplateEditor(prefill = {}) {
    const existing = typeof prefill === 'string'
      ? state.templates.find((t) => t.id === prefill)
      : prefill?.id ? state.templates.find((t) => t.id === prefill.id) : null;
    demoStore.openModal('template', {
      id: existing?.id || makeId('tpl'),
      name: existing?.name || '',
      amount: existing?.amount ?? '',
      type: existing?.type || 'expense',
      category: existing?.category || '',
      color: existing?.color || '#7B4028',
      editing: Boolean(existing),
    });
  },
  saveTemplate(template) {
    const clean = {
      id: template.id || makeId('tpl'),
      name: template.name || 'New template',
      amount: Number(template.amount) || 0,
      type: template.type || 'expense',
      category: template.category || '',
      color: template.color || '#7B4028',
    };
    demoStore.set({
      templates: replaceById(state.templates, clean),
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Template saved');
  },
  deleteTemplate(templateId) {
    demoStore.set({
      templates: state.templates.filter((t) => t.id !== templateId),
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Template deleted');
  },
  saveCollectionItem(collection, item) {
    const key = collection === 'categories' ? 'categories'
      : collection === 'people' ? 'people'
      : collection === 'places' ? 'places'
      : collection === 'labels' ? 'labels'
      : collection === 'recurring' ? 'recurring'
      : collection === 'templates' ? 'templates' : null;
    if (!key) return;
    const clean = { ...item, id: item.id || makeId(key.slice(0, 2)) };
    if (key === 'categories' && !clean.type) clean.type = 'expense';
    if (!clean.name && key !== 'recurring') clean.name = clean.label || 'New item';
    demoStore.set({ [key]: replaceById(state[key], clean) });
    demoStore.toast('Saved');
  },
  deleteCollectionItem(collection, id) {
    const key = {
      categories: 'categories', people: 'people', places: 'places',
      labels: 'labels', recurring: 'recurring', templates: 'templates',
    }[collection];
    if (!key) return;
    demoStore.set({ [key]: state[key].filter((x) => x.id !== id) });
    demoStore.toast('Deleted');
  },
  addCategory(category) {
    demoStore.saveCollectionItem('categories', {
      id: makeId('cat'), name: category.name, type: category.type || 'expense',
      color: category.color || '#7B4028', icon: category.icon || 'wallet',
    });
  },
  savePerson(person) { demoStore.saveCollectionItem('people', person); },
  savePlace(place) { demoStore.saveCollectionItem('places', place); },
  saveLabel(label) { demoStore.saveCollectionItem('labels', label); },

  /* ---------- assets (route-based legacy editor still supported) ---------- */
  openAssetsHow(open = true) { demoStore.setIn('assetsUi.howOpen', open); },
  editAsset(id) { demoStore.go('assetEditor', { id }); },
  newAsset() { demoStore.go('assetEditor', {}); },
  saveAsset(asset) {
    const clean = {
      id: asset.id || makeId('as'),
      name: asset.name || 'New asset',
      type: asset.type || 'Other',
      value: Number(asset.value) || 0,
      purchasePrice: asset.purchasePrice === '' || asset.purchasePrice == null ? null : Number(asset.purchasePrice),
      units: Number(asset.units) || 1,
      unitName: asset.unitName || '',
      description: asset.description || '',
      currency: asset.currency || 'USD',
      primary: asset.primary || '#00796B',
      accent: asset.accent || '#009688',
    };
    demoStore.set({ assets: replaceById(state.assets, clean) });
    demoStore.go('assets');
    demoStore.toast('Asset saved');
  },
  deleteAsset(id) {
    demoStore.set({ assets: state.assets.filter((a) => a.id !== id) });
    demoStore.go('assets');
    demoStore.toast('Asset deleted');
  },

  /* ---------- bills ---------- */
  setBillsTab(tab) { demoStore.setIn('billsUi.tab', tab); },
  openBillsHow(open = true) { demoStore.setIn('billsUi.howOpen', open); },
  openNetBalances(open = true) { demoStore.setIn('billsUi.balancesOpen', open); },
  openParticipantMenu(id) { demoStore.setIn('billsUi.menuFor', id); },
  closeParticipantMenu() { demoStore.setIn('billsUi.menuFor', null); },
  openPaymentEditor(billId, participantId, mode = 'edit') {
    demoStore.openModal('payment', { billId, participantId, mode });
  },
  setParticipantPaid(billId, participantId, amount) {
    const paid = Math.max(0, Number(amount) || 0);
    demoStore.set({
      bills: state.bills.map((b) => b.id === billId
        ? { ...b, participants: b.participants.map((p) => p.id === participantId ? { ...p, paid } : p) }
        : b),
      billsUi: { ...state.billsUi, menuFor: null },
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast('Payment recorded');
  },
  markParticipantPaid(billId, participantId) {
    const bill = state.bills.find((b) => b.id === billId);
    const share = bill?.participants.find((p) => p.id === participantId)?.share || 0;
    demoStore.setParticipantPaid(billId, participantId, share);
  },
  settleBill(billId) {
    demoStore.set({
      bills: state.bills.map((b) => b.id === billId
        ? { ...b, participants: b.participants.map((p) => ({ ...p, paid: p.share })) }
        : b),
    });
    demoStore.toast('Bill settled');
  },
  deleteBill(billId) {
    demoStore.set({ bills: state.bills.filter((b) => b.id !== billId) });
    demoStore.go('billSplitter');
    demoStore.toast('Bill deleted');
  },
  saveBill(bill) {
    const clean = {
      ...bill,
      id: bill.id || makeId('bs'),
      total: Number(bill.total) || 0,
      participants: (bill.participants || []).map((p) => ({ ...p, paid: Number(p.paid) || 0 })),
    };
    demoStore.set({ bills: replaceById(state.bills, clean) });
    demoStore.go('billSplitter');
    demoStore.toast('Bill saved');
  },

  /* ---------- loans ---------- */
  setLoansTab(tab) { demoStore.setIn('loansUi.tab', tab); },
  openLoansHow(open = true) { demoStore.setIn('loansUi.howOpen', open); },
  toggleLoanSort() { demoStore.setIn('loansUi.sort', state.loansUi.sort === 'name' ? 'amount' : 'name'); },
  setLoanDetailsTab(tab) { demoStore.setIn('loansUi.detailsTab', tab); },
  setLoanHistoryPeriod(period) { demoStore.setIn('loansUi.historyPeriod', period); },
  loanMathFor(loanId) {
    const loan = state.loans.find((l) => l.id === loanId);
    return loan ? loanMath(loan, state.transactions) : null;
  },
  openQuickLog(loanIdOrOpen = true, open = true) {
    // Backwards compatible: openQuickLog(true/false) uses the current route.
    const shouldOpen = typeof loanIdOrOpen === 'boolean' ? loanIdOrOpen : open;
    if (!shouldOpen) { demoStore.closeModal(); return; }
    const loanId = typeof loanIdOrOpen === 'string'
      ? loanIdOrOpen
      : state.route.params?.id || state.loans[0]?.id;
    const loan = state.loans.find((l) => l.id === loanId) || state.loans[0];
    demoStore.openModal('loanPayment', {
      id: makeId('loan-payment'),
      loanId: loan?.id || '',
      amount: '',
      date: state.today,
      account: loan?.account || state.accounts[0]?.name || '',
      type: 'repayment',
    });
  },
  recordLoanPayment(loanId, amount, { date, account, note, type = 'repayment' } = {}) {
    const loan = state.loans.find((l) => l.id === loanId);
    if (!loan) return;
    const cents = Math.round((Number(amount) || 0) * 100);
    if (cents <= 0) return;
    const before = loanMath(loan, state.transactions);
    const payCents = type === 'charge' ? cents : Math.min(cents, before.remaining || cents);
    const tx = normalizeTransaction({
      id: makeId('tx'),
      title: note || (type === 'charge' ? `${loan.title} additional charge` : `${loan.kind === 'lending' ? 'Repayment from' : 'Repayment to'} ${loan.person}`),
      date: date || state.today,
      time: nowTime(),
      type: type === 'charge' ? 'expense' : 'income',
      amount: payCents / 100,
      currency: 'USD',
      account: account || loan.account,
      loanId,
      category: type === 'charge' ? (loan.category || 'Miscellaneous') : 'Repayment',
      icon: { bg: type === 'charge' ? '#E91E63' : '#43A047', fg: '#FFFFFF', glyph: 'user' },
      chips: [{ label: loan.title, bg: '#1F2A4A', fg: '#9FA8DA' }],
    }, state.profile.baseCurrency);
    const remaining = Math.max(0, before.remaining - (type === 'charge' ? 0 : payCents));
    demoStore.set({
      transactions: [tx, ...state.transactions],
      loans: state.loans.map((l) => l.id === loanId ? { ...l, status: remaining <= 0 ? 'completed' : l.status } : l),
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast(type === 'charge' ? 'Charge recorded' : remaining <= 0 ? 'Loan completed' : 'Payment recorded');
  },
  markLoanDone(loanId) {
    const loan = state.loans.find((l) => l.id === loanId);
    if (!loan) return;
    const m = loanMath(loan, state.transactions);
    if (m.remaining > 0) {
      const tx = normalizeTransaction({
        id: makeId('tx'),
        title: `${loan.title} settled`,
        date: state.today,
        time: nowTime(),
        type: 'income',
        amount: m.remaining / 100,
        currency: 'USD',
        account: loan.account,
        loanId,
        icon: { bg: '#43A047', fg: '#FFFFFF', glyph: 'user' },
      }, state.profile.baseCurrency);
      demoStore.set({
        transactions: [tx, ...state.transactions],
        loans: state.loans.map((l) => l.id === loanId ? { ...l, status: 'completed' } : l),
      });
    } else {
      demoStore.set({ loans: state.loans.map((l) => l.id === loanId ? { ...l, status: 'completed' } : l) });
    }
    demoStore.toast('Loan completed');
  },
  reopenLoan(loanId) {
    demoStore.set({ loans: state.loans.map((l) => l.id === loanId ? { ...l, status: 'active' } : l) });
  },
  deleteLoan(loanId) {
    demoStore.set({
      loans: state.loans.filter((l) => l.id !== loanId),
      transactions: state.transactions.filter((t) => t.loanId !== loanId),
    });
    demoStore.go('loans');
    demoStore.toast('Loan deleted');
  },
  saveLoan(loan) {
    const clean = {
      ...loan,
      id: loan.id || makeId('ln'),
      amount: Number(loan.amount) || 0,
      kind: loan.kind || 'lending',
      status: loan.status || 'active',
    };
    demoStore.set({ loans: replaceById(state.loans, clean) });
    demoStore.go('loans');
    demoStore.toast('Loan saved');
  },

  /* ---------- goals ---------- */
  setGoalsTab(tab) { demoStore.setIn('goalsUi.tab', tab); },
  setGoalSort(sort) { demoStore.setIn('goalsUi.sort', sort); },
  toggleGoalSortMenu(open) { demoStore.setIn('goalsUi.sortOpen', open === undefined ? !state.goalsUi.sortOpen : open); },
  openGoalsHow(open = true) { demoStore.setIn('goalsUi.howOpen', open); },
  setGoalDetailsTab(tab) { demoStore.setIn('goalsUi.detailsTab', tab); },
  goalMathFor(goalId) {
    const goal = state.goals.find((g) => g.id === goalId);
    return goal ? { goal, ...goalMath(goal, state.transactions) } : null;
  },
  openGoalDeposit(goalId, type = 'deposit') {
    const goal = state.goals.find((g) => g.id === goalId) || state.goals[0];
    demoStore.openModal('goalDeposit', {
      id: makeId('goal-deposit'),
      goalId: goal?.id || goalId,
      type,
      amount: '',
      date: state.today,
      account: goal?.account || state.accounts[0]?.name || '',
    });
  },
  addGoalTransaction(goalId, { amount, type = 'income', date, account, title } = {}) {
    const goal = state.goals.find((g) => g.id === goalId);
    if (!goal) return;
    const cents = Math.round((Number(amount) || 0) * 100);
    if (cents <= 0) return;
    const tx = normalizeTransaction({
      id: makeId('tx'),
      title: title || (type === 'income' ? `${goal.title} deposit` : `${goal.title} withdrawal`),
      date: date || state.today,
      time: nowTime(),
      type,
      amount: cents / 100,
      currency: 'USD',
      account: account || goal.account,
      goalId,
      icon: type === 'income'
        ? { bg: '#43A047', fg: '#FFFFFF', glyph: 'user' }
        : { bg: '#E91E63', fg: '#FFFFFF', glyph: 'cash' },
      chips: [{ label: goal.title, bg: goal.pillBg, fg: goal.pillFg }],
    }, state.profile.baseCurrency);
    demoStore.set({
      transactions: [tx, ...state.transactions],
      ui: { ...state.ui, modal: null, modalData: null },
    });
    demoStore.toast(type === 'income' ? 'Deposit added' : 'Withdrawal recorded');
  },
  updateGoalProgress(goalId) {
    const goal = state.goals.find((g) => g.id === goalId);
    if (!goal) return;
    const m = goalMath(goal, state.transactions);
    if (m.remaining === 0 && goal.status === 'active') demoStore.setGoalStatus(goalId, 'completed');
  },
  saveGoal(goal) {
    const clean = {
      ...goal,
      id: goal.id || makeId('gl'),
      target: Number(goal.target) || 0,
      status: goal.status || 'active',
      kind: goal.kind || 'expense',
    };
    demoStore.set({ goals: replaceById(state.goals, clean) });
    demoStore.go('goals');
    demoStore.toast('Goal saved');
  },
  deleteGoal(goalId) {
    demoStore.set({
      goals: state.goals.filter((g) => g.id !== goalId),
      transactions: state.transactions.filter((t) => t.goalId !== goalId),
    });
    demoStore.go('goals');
    demoStore.toast('Goal deleted');
  },
  setGoalStatus(goalId, status) {
    demoStore.set({ goals: state.goals.map((g) => g.id === goalId ? { ...g, status } : g) });
    demoStore.toast(status === 'archived' ? 'Goal archived' : status === 'completed' ? 'Goal completed' : 'Goal restored');
  },

  /* ---------- UI setters used by screens ---------- */
  setReportMonth(month) { demoStore.setIn('reportsUi.month', month); },
  setChartMode(mode) { demoStore.setIn('reportsUi.chartMode', mode); },
  toggleCategoryMenu() { demoStore.setIn('reportsUi.menuOpen', !state.reportsUi.menuOpen); },
  setDimension(dim) { demoStore.set({ reportsUi: { ...state.reportsUi, dimension: dim, menuOpen: false } }); },
  toggleReportType() { demoStore.setIn('reportsUi.type', state.reportsUi.type === 'Expense' ? 'Income' : 'Expense'); },
  toggleDonut() { demoStore.setIn('reportsUi.donutExpanded', !state.reportsUi.donutExpanded); },
  setAccountSlide(i) { demoStore.setIn('accountsUi.slide', i); },
  setBudgetsTab(tab) { demoStore.setIn('budgetsUi.tab', tab); },
  setBudgetSlide(i) { demoStore.setIn('budgetsUi.slide', i); },
  toggleShowBudget() { demoStore.setIn('budgetsUi.showOnHome', !state.budgetsUi.showOnHome); },
  cycleBudgetBento() { demoStore.setIn('budgetsUi.bentoSlide', state.budgetsUi.bentoSlide ? 0 : 1); },
  cycleBudgetCarousel() {
    const n = state.budgets.length || 1;
    demoStore.setIn('budgetsUi.slide', (state.budgetsUi.slide + 1) % n);
  },
  openHowBudgets(open = true) { demoStore.setIn('howBudgetsOpen', open); },
};

export { initialState as liveInitialState, TODAY };
