/* ============================================================
   Pure derived selectors. Everything the UI displays as a number,
   chart series, summary or progress value is computed from live state.
   ============================================================ */

import {
  toINR,
  fromINR,
  symbol,
  fmtExact,
} from './format.js';
import {
  portfolioTotal,
  groupAssets,
  loanMath,
  loanSummaryFromLedger,
  goalMath,
  daysUntil,
  goalDaysLeft,
  remainingLabel,
  billShares,
  participantBalances,
  billStatus,
  netBalances,
} from './engine.js';

const DAY = 86400000;
const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const DIM_COLORS = ['#7B4028', '#00897B', '#3949AB', '#D81B60', '#2E7D32', '#EF6C00', '#8E24AA', '#1565C0'];

const dateOf = (iso) => new Date(`${iso}T00:00:00Z`);
const isoOf = (d) => new Date(d).toISOString().slice(0, 10);
export const addDays = (iso, n) => isoOf(dateOf(iso).getTime() + n * DAY);
export const monthKey = (iso) => iso.slice(0, 7);
export function monthBounds(iso) {
  const [y, m] = iso.split('-').map(Number);
  const start = `${y}-${String(m).padStart(2, '0')}-01`;
  const next = new Date(Date.UTC(y, m, 1)).toISOString().slice(0, 10);
  return { start, end: addDays(next, -1) };
}
export function daysInMonth(key) {
  const [y, m] = key.split('-').map(Number);
  return new Date(Date.UTC(y, m, 0)).getUTCDate();
}
export function startOfWeek(iso) {
  const d = dateOf(iso);
  const day = d.getUTCDay(); // 0 Sun .. 6 Sat
  const diff = day === 0 ? -6 : 1 - day;
  return addDays(iso, diff);
}
export function monthLabel(iso) {
  const d = dateOf(iso);
  return `${MONTHS[d.getUTCMonth()]} ${String(d.getUTCFullYear()).slice(-2)}`;
}
export function monthKeyFromLabel(label, today) {
  const [mon, yr] = label.split(' ');
  const m = MONTHS.indexOf(mon) + 1;
  let year = 2000 + Number(yr);
  const current = dateOf(today);
  if (m > current.getUTCMonth() + 1) year -= 1;
  return `${year}-${String(m).padStart(2, '0')}`;
}
export function reportMonths(state) {
  const out = [];
  let cursor = monthBounds(state.today).start;
  for (let i = 0; i < 5; i += 1) {
    out.push(monthLabel(cursor));
    cursor = addDays(cursor, -1);
    cursor = monthBounds(cursor).start;
  }
  return out;
}

export function txBase(tx, base = 'INR') {
  const inr = tx.baseAmount != null ? Number(tx.baseAmount) : toINR(Number(tx.amount) || 0, tx.currency || 'INR');
  return fromINR(inr, base);
}
export const txBaseCents = (tx, base = 'INR') => Math.round(txBase(tx, base) * 100);
const isCashFlow = (t) => t.includeInCashFlow !== false;
const isChart = (t) => isCashFlow(t) && t.includeInCharts !== false;
const isAccountTx = (t) => t.includeInAccounts !== false;
const isPast = (t, today) => t.date <= today;
const inRange = (t, start, end) => t.date >= start && t.date <= end;

export function monthlyTotals(state, key) {
  const base = state.profile.baseCurrency;
  let income = 0;
  let expense = 0;
  let count = 0;
  state.transactions.forEach((t) => {
    if (!isCashFlow(t) || !isPast(t, state.today) || monthKey(t.date) !== key) return;
    const v = txBase(t, base);
    if (t.type === 'income') income += v;
    else if (t.type === 'expense') expense += v;
    count += 1;
  });
  return { income: round2(income), expense: round2(expense), count, net: round2(income - expense) };
}

export function accountBalances(state) {
  const base = state.profile.baseCurrency;
  const cents = new Map();
  state.accounts.forEach((a) => cents.set(a.name, Math.round(fromINR(Number(a.openingBalance) || 0, base) * 100)));
  state.transactions.forEach((t) => {
    if (!isAccountTx(t)) return;
    const v = txBaseCents(t, base);
    if (t.type === 'transfer') {
      if (t.from && cents.has(t.from)) cents.set(t.from, cents.get(t.from) - v);
      if (t.to && cents.has(t.to)) cents.set(t.to, cents.get(t.to) + v);
    } else if (t.account && cents.has(t.account)) {
      cents.set(t.account, cents.get(t.account) + (t.type === 'income' ? v : -v));
    }
  });
  return state.accounts.map((a) => ({ ...a, balance: (cents.get(a.name) || 0) / 100 }));
}

export function heroTotals(state) {
  const base = state.profile.baseCurrency;
  const accounts = accountBalances(state).filter((a) => a.includeInTotals !== false);
  const total = accounts.reduce((sum, a) => sum + a.balance, 0) + fromINR(Number(state.profile.liabilitiesOffset) || 0, base);
  const current = monthlyTotals(state, monthKey(state.today));
  const prevStart = addDays(monthBounds(state.today).start, -1);
  const previous = monthlyTotals(state, monthKey(prevStart));
  return {
    total: round2(total),
    income: { now: current.income, prev: previous.income, deltaPct: deltaPct(current.income, previous.income) },
    expense: { now: current.expense, prev: previous.expense, deltaPct: deltaPct(current.expense, previous.expense) },
    accounts,
  };
}

function deltaPct(now, prev) {
  if (!prev) return now > 0 ? 100 : 0;
  return Math.round(((now - prev) / prev) * 100);
}
const round2 = (v) => Math.round((Number(v) || 0) * 100) / 100;

export function weeklySeries(state) {
  const base = state.profile.baseCurrency;
  const monday = startOfWeek(state.today);
  const prevMonday = addDays(monday, -7);
  const days = WEEKDAYS.map((d, i) => ({
    d, date: addDays(monday, i), amount: 0, prev: 0, pct: 0, prevPct: 0,
  }));
  const prevByOffset = {};
  let thisWeek = 0;
  let lastWeek = 0;
  state.transactions.forEach((t) => {
    if (!isChart(t) || t.type !== 'expense' || !isPast(t, state.today)) return;
    const v = txBase(t, base);
    const idx = days.findIndex((x) => x.date === t.date);
    if (idx >= 0) {
      days[idx].amount += v;
      thisWeek += v;
    } else if (t.date >= prevMonday && t.date < monday) {
      const off = Math.floor((new Date(`${t.date}T00:00:00Z`) - new Date(`${prevMonday}T00:00:00Z`)) / 86400000);
      prevByOffset[off] = (prevByOffset[off] || 0) + v;
      lastWeek += v;
    }
  });
  days.forEach((d, i) => { d.prev = prevByOffset[i] || 0; });
  const max = Math.max(1, ...days.map((d) => d.amount), ...days.map((d) => d.prev));
  days.forEach((d) => {
    d.amount = round2(d.amount);
    d.prev = round2(d.prev);
    d.pct = Math.round((d.amount / max) * 100);
    d.prevPct = Math.round((d.prev / max) * 100);
  });
  const peak = days.reduce((best, d) => (d.amount > best.amount ? d : best), days[0]);
  return { days, thisWeek: round2(thisWeek), lastWeek: round2(lastWeek), highlight: peak?.d || 'Sat' };
}

export function last30Series(state) {
  const base = state.profile.baseCurrency;
  const start = addDays(state.today, -29);
  const prevStart = addDays(start, -30);
  const points = Array.from({ length: 30 }, (_, i) => ({ date: addDays(start, i), amount: 0, pct: 0 }));
  let total = 0;
  let prevTotal = 0;
  state.transactions.forEach((t) => {
    if (!isChart(t) || t.type !== 'expense' || !isPast(t, state.today)) return;
    const v = txBase(t, base);
    const idx = points.findIndex((p) => p.date === t.date);
    if (idx >= 0) {
      points[idx].amount += v;
      total += v;
    } else if (t.date >= prevStart && t.date < start) {
      prevTotal += v;
    }
  });
  const max = Math.max(...points.map((p) => p.amount), 1);
  let running = 0;
  points.forEach((p) => {
    p.amount = round2(p.amount);
    p.pct = Math.round((p.amount / max) * 100);
    running += p.amount;
    p.cum = round2(running);
  });
  const maxCum = Math.max(1, running);
  points.forEach((p) => { p.cumPct = Math.round((p.cum / maxCum) * 100); });
  return {
    points,
    series: points.map((p) => p.pct),
    cumulative: points.map((p) => p.cumPct),
    total: round2(total),
    deltaPct: deltaPct(total, prevTotal),
  };
}

export function calendarHeatmap(state) {
  const base = state.profile.baseCurrency;
  const { start, end } = monthBounds(state.today);
  const n = daysInMonth(monthKey(state.today));
  const spending = Array.from({ length: n + 1 }, () => ({ amount: 0, count: 0 }));
  state.transactions.forEach((t) => {
    if (!isChart(t) || t.type !== 'expense') return;
    if (t.date < start || t.date > end) return;
    const day = Number(t.date.slice(8, 10));
    spending[day].amount += txBase(t, base);
    spending[day].count += 1;
  });
  const values = spending.slice(1).map((x) => x.amount).filter(Boolean).sort((a, b) => a - b);
  const medium = values[Math.floor(values.length / 3)] || 1;
  const high = values[Math.floor((values.length * 2) / 3)] || medium * 2;
  const firstDay = dateOf(start).getUTCDay();
  const lead = firstDay === 0 ? 6 : firstDay - 1;
  const cells = [];
  for (let i = 0; i < lead; i += 1) cells.push({ key: `blank-${i}`, day: null });
  for (let day = 1; day <= n; day += 1) {
    const date = `${monthKey(state.today)}-${String(day).padStart(2, '0')}`;
    const amount = round2(spending[day].amount);
    const level = amount === 0 ? 0 : amount >= high ? 2 : amount >= medium ? 1 : 1;
    cells.push({ key: date, day, date, amount, count: spending[day].count, level, isToday: date === state.today });
  }
  return { month: monthLabel(state.today), cells, max: Math.max(...values, 1), zero: '#F4ECE8', medium: '#D7C0B6', high: '#BA988A' };
}

export function trendSeries(state) {
  const base = state.profile.baseCurrency;
  const current = monthBounds(state.today);
  const prev = monthBounds(addDays(current.start, -1));
  const n = 31;
  const todayDay = Number(state.today.slice(8, 10));
  const thisDaily = Array.from({ length: n + 1 }, () => 0);
  const lastDaily = Array.from({ length: n + 1 }, () => 0);
  const futureDaily = Array.from({ length: n + 1 }, () => 0);
  state.transactions.forEach((t) => {
    if (!isChart(t) || t.type !== 'expense') return;
    const day = Number(t.date.slice(8, 10));
    const v = txBase(t, base);
    if (t.date >= current.start && t.date <= current.end) {
      if (t.date <= state.today) thisDaily[day] += v;
      else futureDaily[day] += v;
    } else if (t.date >= prev.start && t.date <= prev.end) {
      lastDaily[Math.min(day, n)] += v;
    }
  });
  const cum = (arr) => {
    let total = 0;
    return Array.from({ length: n }, (_, i) => {
      total += arr[i + 1] || 0;
      return round2(total);
    });
  };
  const thisMonth = cum(thisDaily);
  const lastMonth = cum(lastDaily);
  const projectedBase = thisMonth[Math.min(todayDay, n) - 1] || 0;
  let projected = projectedBase;
  const projectedArr = Array.from({ length: n }, (_, i) => {
    if (i + 1 > todayDay) projected += futureDaily[i + 1] || 0;
    return round2(Math.max(thisMonth[i], i + 1 <= todayDay ? thisMonth[i] : projected));
  });
  const maxV = Math.max(5000, ...thisMonth, ...lastMonth, ...projectedArr) * 1.1;
  return {
    days: Array.from({ length: n }, (_, i) => i + 1),
    thisMonth,
    lastMonth,
    projected: projectedArr,
    today: todayDay,
    maxV: Math.ceil(maxV / 5000) * 5000,
    minV: 0,
  };
}

export function budgetMath(budget, state) {
  const base = state.profile.baseCurrency;
  const { start, end } = periodBounds(budget, state.today);
  const wantedType = budget.for === 'Income' ? 'income' : 'expense';
  const cats = budget.categories || [];
  let spentCents = 0;
  let count = 0;
  state.transactions.forEach((t) => {
    if (!isCashFlow(t) || t.type !== wantedType || !inRange(t, start, end) || !isPast(t, state.today)) return;
    const linked = t.budgetId === budget.id || (budget.type === 'Overall' && budget.for === wantedType) || cats.includes(t.category);
    if (!linked) return;
    spentCents += txBaseCents(t, base);
    count += 1;
  });
  const limit = Number(budget.limit) || 0;
  const spent = spentCents / 100;
  const remaining = round2(limit - spent);
  const usedPct = limit > 0 ? Math.round((spent / limit) * 100) : 0;
  const daysLeft = Math.max(1, daysUntil(end, state.today) + 1);
  const dailySafeSpend = round2(Math.max(0, remaining) / daysLeft);
  return { ...budget, start, end, spent: round2(spent), remaining, usedPct, daysLeft, dailySafeSpend, count, limit };
}

export function periodBounds(budget, today) {
  if (budget.start && budget.end && budget.period === 'Custom') return { start: budget.start, end: budget.end };
  const m = monthBounds(today);
  if (budget.period === 'Daily') return { start: today, end: today };
  if (budget.period === 'Weekly') {
    const s = startOfWeek(today);
    return { start: s, end: addDays(s, 6) };
  }
  if (budget.period === 'Yearly') {
    const y = today.slice(0, 4);
    return { start: `${y}-01-01`, end: `${y}-12-31` };
  }
  if (budget.start && budget.end) return { start: budget.start, end: budget.end };
  return m;
}

export function budgetPace(state, budgetId) {
  const budget = state.budgets.find((b) => b.id === budgetId) || state.budgets[0];
  if (!budget) return null;
  const m = budgetMath(budget, state);
  const { start, end } = m;
  const totalDays = Math.max(1, daysUntil(end, start) + 1);
  const base = state.profile.baseCurrency;
  const daily = new Map();
  state.transactions.forEach((t) => {
    if (!isCashFlow(t) || t.type !== (budget.for === 'Income' ? 'income' : 'expense')) return;
    if (!inRange(t, start, end) || !isPast(t, state.today)) return;
    const linked = t.budgetId === budget.id || (budget.type === 'Overall') || (budget.categories || []).includes(t.category);
    if (!linked) return;
    daily.set(t.date, (daily.get(t.date) || 0) + txBaseCents(t, base));
  });
  let actualCents = 0;
  const points = [];
  for (let i = 0; i < totalDays; i += 1) {
    const date = addDays(start, i);
    actualCents += daily.get(date) || 0;
    const ideal = (m.limit * (i + 1)) / totalDays;
    points.push({
      date,
      day: i + 1,
      actual: actualCents / 100,
      ideal: round2(ideal),
      limit: m.limit,
      difference: round2(ideal - actualCents / 100),
      isFuture: date > state.today,
    });
  }
  return { budget: m, points, maxV: Math.max(m.limit, ...points.map((p) => p.actual), 1) * 1.1 };
}

function dimensionValue(t, dimension) {
  if (dimension === 'Account') return t.account || t.from || 'Unassigned';
  if (dimension === 'Label') return (t.labels || [])[0] || 'No label';
  if (dimension === 'Person') return t.person || 'No person';
  if (dimension === 'Places') return t.place || 'No place';
  return t.category || 'Uncategorized';
}
function dimensionColor(label, i, state, dimension) {
  const pool = {
    Category: state.categories,
    Account: state.accounts,
    Label: state.labels,
    Person: state.people,
    Places: state.places,
  }[dimension] || [];
  const found = pool.find((x) => (x.name || x.label) === label);
  return found?.color || found?.tile || found?.primary || DIM_COLORS[i % DIM_COLORS.length];
}

export function donutGroups(state, monthLabelValue, type = 'Expense', dimension = 'Category') {
  const base = state.profile.baseCurrency;
  const key = monthKeyFromLabel(monthLabelValue, state.today);
  const groups = new Map();
  state.transactions.forEach((t) => {
    if (!isChart(t) || !isPast(t, state.today) || monthKey(t.date) !== key) return;
    if (type === 'Expense' && t.type !== 'expense') return;
    if (type === 'Income' && t.type !== 'income') return;
    const label = dimensionValue(t, dimension);
    const v = txBase(t, base);
    const g = groups.get(label) || { label, amount: 0, count: 0 };
    g.amount += v;
    g.count += 1;
    groups.set(label, g);
  });
  const total = [...groups.values()].reduce((s, g) => s + g.amount, 0) || 1;
  return [...groups.values()]
    .sort((a, b) => b.amount - a.amount)
    .map((g, i) => ({
      ...g,
      amount: round2(g.amount),
      pct: round2((g.amount / total) * 100),
      color: dimensionColor(g.label, i, state, dimension),
    }));
}

export function reportsData(state, monthLabelValue = state.reportsUi.month) {
  const base = state.profile.baseCurrency;
  const key = monthKeyFromLabel(monthLabelValue, state.today);
  const n = daysInMonth(key);
  const totals = monthlyTotals(state, key);
  const prevKey = monthKey(addDays(`${key}-01`, -1));
  const prevTotals = monthlyTotals(state, prevKey);
  const daily = Array.from({ length: n }, (_, i) => ({
    day: i + 1,
    date: `${key}-${String(i + 1).padStart(2, '0')}`,
    income: 0,
    expense: 0,
  }));
  const expenses = [];
  state.transactions.forEach((t) => {
    if (!isChart(t) || !isPast(t, state.today) || monthKey(t.date) !== key) return;
    const day = Number(t.date.slice(8, 10));
    if (!daily[day - 1]) return;
    const v = txBase(t, base);
    if (t.type === 'income') daily[day - 1].income += v;
    else if (t.type === 'expense') {
      daily[day - 1].expense += v;
      expenses.push({ ...t, amountBase: v });
    }
  });
  daily.forEach((d) => {
    d.income = round2(d.income);
    d.expense = round2(d.expense);
  });
  const activeDays = Math.max(1, daily.filter((d) => d.income || d.expense).length);
  const largest = expenses.sort((a, b) => b.amountBase - a.amountBase)[0];
  const peak = daily.reduce((best, d) => (d.expense > best.expense ? d : best), daily[0]);
  const top = donutGroups(state, monthLabelValue, 'Expense', 'Category')[0] || { label: '—', amount: 0, pct: 0 };
  const savingsRate = totals.income ? Math.round(((totals.income - totals.expense) / totals.income) * 100) : 0;
  return {
    month: monthLabelValue,
    key,
    totalBalance: round2(totals.income - totals.expense),
    income: { value: totals.income, prev: prevTotals.income, pct: deltaPct(totals.income, prevTotals.income) },
    expense: { value: totals.expense, prev: prevTotals.expense, pct: deltaPct(totals.expense, prevTotals.expense) },
    txCount: totals.count,
    daily,
    bars: {
      income: totals.income,
      expense: totals.expense,
      max: Math.max(...daily.map((d) => Math.max(d.income, d.expense)), 1) * 1.1,
    },
    insights: {
      savingsRate: { pct: `${savingsRate}%`, amount: `${fmtExact(totals.income - totals.expense, base)} saved` },
      avgDaily: { value: fmtExact(totals.expense / activeDays, base), perDay: 'per active day' },
      avgTransaction: { value: fmtExact(totals.count ? (totals.income + totals.expense) / totals.count : 0, base), sub: `${totals.count} transactions` },
      peakDay: { label: peak?.date ? new Date(`${peak.date}T00:00:00Z`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : '—', amount: fmtExact(peak?.expense || 0, base) },
      topCategory: { name: top.label, amount: fmtExact(top.amount, base), pct: `${top.pct}%` },
      largest: largest ? { title: largest.title, date: largest.date, amount: fmtExact(largest.amountBase, base) } : { title: '—', date: '—', amount: fmtExact(0, base) },
    },
    donut: donutGroups(state, monthLabelValue, state.reportsUi.type, state.reportsUi.dimension),
  };
}

export function budgetCards(state) {
  return state.budgets.map((b) => {
    const m = budgetMath(b, state);
    return {
      ...m,
      id: b.id,
      name: b.name,
      period: b.period,
      status: m.usedPct > 100 ? 'Over budget' : 'Good',
      accent: b.color,
      ringColor: b.color,
      budget: m.limit,
      spent: m.spent,
      remaining: m.remaining,
      pct: Math.min(100, Math.max(0, m.usedPct)),
      remainingPct: Math.max(0, 100 - m.usedPct),
    };
  });
}

export function loanCards(state) {
  const transactions = state.transactions;
  return state.loans.map((l) => {
    const m = loanMath(l, transactions);
    return {
      ...l,
      paid: m.paid / 100,
      total: m.total / 100,
      amount: m.principal / 100,
      remaining: m.remaining / 100,
      completion: m.completion,
      days: daysUntil(l.end, state.today),
      completed: (l.status || 'active') === 'completed' || m.remaining === 0,
      subtitle: `${l.kind === 'lending' ? 'Lent to' : 'Borrowed from'} ${l.person}`,
    };
  });
}

export function goalCards(state) {
  return state.goals.map((g) => {
    const m = goalMath(g, state.transactions);
    return {
      ...g,
      saved: m.saved / 100,
      targetCents: m.target / 100,
      remaining: m.remaining / 100,
      progress: m.progress,
      days: goalDaysLeft(g.end, state.today),
      remainingText: remainingLabel(g.end, state.today),
    };
  });
}

export function billCards(state) {
  return state.bills.map((b) => {
    const shares = billShares(b);
    const balances = participantBalances(b);
    const settled = billStatus(b) === 'Settled';
    return { ...b, shares, balances, settled };
  });
}

export function upcomingTransactions(state) {
  return state.transactions
    .filter((t) => t.date > state.today)
    .sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : 0))
    .map((t) => ({
      ...t,
      when: new Date(`${t.date}T00:00:00Z`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
      accountTone: t.accountTone || 'orange',
      chips: (t.chips || []).length ? t.chips : linkChips(t, state),
    }));
}

export function linkChips(tx, state) {
  const chips = [];
  const push = (label, color) => chips.push({ label, bg: `${color}22`, fg: color });
  if (tx.category) push(tx.category, '#7B4028');
  if (tx.budgetId) {
    const b = state.budgets.find((x) => x.id === tx.budgetId);
    if (b) push(b.name, b.color);
  }
  if (tx.loanId) {
    const l = state.loans.find((x) => x.id === tx.loanId);
    if (l) push(l.title, '#3949AB');
  }
  if (tx.goalId) {
    const g = state.goals.find((x) => x.id === tx.goalId);
    if (g) push(g.title, g.color);
  }
  if (tx.person) push(tx.person, '#00897B');
  if (tx.place) push(tx.place, '#1565C0');
  (tx.labels || []).forEach((l) => push(l, '#2E7D32'));
  return chips.slice(0, 5);
}

export function transactionById(state, id) {
  return state.transactions.find((t) => t.id === id) || null;
}

export function searchTransactions(state, query = '') {
  const q = query.trim().toLowerCase();
  if (!q) return [...state.transactions].sort((a, b) => (a.date < b.date ? 1 : -1));
  return state.transactions.filter((t) =>
    [t.title, t.category, t.account, t.person, t.place, ...(t.labels || []), String(t.amount)]
      .join(' ')
      .toLowerCase()
      .includes(q),
  ).sort((a, b) => (a.date < b.date ? 1 : -1));
}

export function overview(state) {
  const base = state.profile.baseCurrency;
  const accounts = accountBalances(state);
  const included = accounts.filter((a) => a.includeInTotals !== false);
  const hero = heroTotals(state);
  const budgets = budgetCards(state);
  const assets = state.assets;
  const bills = billCards(state);
  const loans = loanCards(state);
  const goals = goalCards(state);
  const weekly = weeklySeries(state);
  const last30 = last30Series(state);
  const chartTx = state.transactions.filter(isChart);
  const reportsTotal = chartTx.reduce((sum, t) => sum + Math.abs(txBase(t, base)), 0);
  const categoryTotals = groupTotals(state, 'category');
  const placeTotals = groupTotals(state, 'place');
  const personTotals = groupTotals(state, 'person');
  const labelTotals = groupTotals(state, 'labels');
  const topCategory = categoryTotals[0] || { label: '—', total: 0, color: '#7B4028' };
  const topPlace = placeTotals[0] || { label: '—', total: 0 };
  const topPerson = personTotals[0] || { label: '—', total: 0 };
  const topLabel = labelTotals[0] || { label: '—', total: 0 };
  const activeGoals = goals.filter((g) => (g.status || 'active') === 'active');
  const progressed = activeGoals.reduce((sum, g) => sum + g.saved, 0);
  const target = activeGoals.reduce((sum, g) => sum + g.targetCents, 0);
  const activeBills = bills.filter((b) => !b.settled);
  const loanSummary = loanSummaryFromLedger(state.loans, state.transactions, state.today);
  const assetGroups = groupAssets(assets);
  const recurringMonthly = state.recurring.reduce((sum, r) => sum + (Number(r.amount) || 0), 0);
  const achievementsUnlocked = state.achievements.filter((a) => a.unlocked).length;
  const achievementsTotal = Math.max(37, state.achievements.length);
  const achievementsPct = Math.round((achievementsUnlocked / achievementsTotal) * 100);
  const habitScore = Math.max(0, Math.min(100, 60 + Math.round((last30.deltaPct || 0) / -4)));
  return {
    accounts: { count: included.length, total: round2(included.reduce((s, a) => s + Math.abs(a.balance), 0)) },
    reports: { count: state.transactions.length, total: round2(reportsTotal) },
    budgets: {
      count: budgets.length,
      slide: state.budgetsUi.bentoSlide || 0,
      detail: {
        total: round2(budgets.reduce((s, b) => s + b.limit, 0)),
        remaining: round2(budgets.reduce((s, b) => s + b.remaining, 0)),
        spent: round2(budgets.reduce((s, b) => s + b.spent, 0)),
      },
    },
    assets: { count: assets.length, total: round2(portfolioTotal(assets)), portfolio: round2(portfolioTotal(assets)), groups: assetGroups.length, types: assetGroups.length },
    billSplitter: { bills: bills.length, active: activeBills.length, total: round2(bills.reduce((s, b) => s + (Number(b.total) || 0), 0)) },
    bills: { count: bills.length, pending: activeBills.length, settled: bills.length - activeBills.length },
    loans: {
      lending: loans.filter((l) => l.kind === 'lending' && !l.completed).length,
      borrowing: loans.filter((l) => l.kind === 'borrowing' && !l.completed).length,
      balance: round2(loanSummary.trueNet / 100),
    },
    goals: { active: activeGoals.length, progressed: round2(progressed), target: round2(target) },
    labels: { count: state.labels.length, top: topLabel.label, topTotal: round2(topLabel.total) },
    analyticsMonth: { value: round2(hero.expense.now), deltaPct: hero.expense.deltaPct },
    recurring: { active: state.recurring.length, count: state.recurring.length, monthly: round2(recurringMonthly) },
    categories: {
      count: state.categories.length,
      categories: state.categories.length,
      expense: state.categories.filter((c) => c.type === 'expense').length,
      income: state.categories.filter((c) => c.type === 'income').length,
      top: categoryTotals.slice(0, 3).map((c) => ({ ...c, icon: 'wallet' })),
    },
    weekly,
    last30,
    places: { count: state.places.length, top: topPlace.label, topTotal: round2(topPlace.total) },
    person: { count: state.people.length, top: topPerson.label, topTotal: round2(topPerson.total) },
    people: { count: state.people.length, top: topPerson.label, topTotal: round2(topPerson.total) },
    habit: {
      score: habitScore,
      streakDays: Math.max(1, Math.round(habitScore / 10)),
      legend: [
        { label: 'Under average', color: '#D32F2F' },
        { label: 'On track', color: '#388E3C' },
        { label: 'Saved', color: '#388E3C' },
      ],
    },
    achievements: {
      unlocked: achievementsUnlocked,
      total: achievementsTotal,
      pct: achievementsPct,
      last: state.achievements.find((a) => a.unlocked) || { title: '—', date: '—' },
    },
  };
}

function groupTotals(state, field) {
  const base = state.profile.baseCurrency;
  const map = new Map();
  state.transactions.forEach((t) => {
    if (!isChart(t) || t.type !== 'expense') return;
    const raw = field === 'labels' ? (t.labels || [])[0] : t[field];
    const label = raw || 'Other';
    const v = txBase(t, base);
    map.set(label, (map.get(label) || 0) + v);
  });
  const colorFor = (label) => {
    const pool = field === 'labels' ? state.labels : field === 'category' ? state.categories : field === 'place' ? state.places : state.people;
    const found = pool.find((x) => (x.name || x.label) === label);
    return found?.color || found?.tile || '#7B4028';
  };
  return [...map.entries()]
    .map(([label, total]) => ({ label, total: round2(total), color: colorFor(label) }))
    .sort((a, b) => b.total - a.total);
}

export function balanceBreakdown(state) {
  const base = state.profile.baseCurrency;
  const accounts = accountBalances(state);
  const liabilities = fromINR(Number(state.profile.liabilitiesOffset) || 0, base);
  return {
    base,
    accounts,
    liabilities: round2(liabilities),
    total: round2(accounts.filter((a) => a.includeInTotals !== false).reduce((s, a) => s + a.balance, 0) + liabilities),
  };
}

export function collectionData(state, name) {
  const map = {
    categories: state.categories,
    people: state.people,
    places: state.places,
    labels: state.labels,
    templates: state.templates,
    recurring: state.recurring,
  };
  return { key: name, title: name[0].toUpperCase() + name.slice(1), items: map[name] || [] };
}

export function netBalanceData(state) {
  return netBalances(state.bills);
}

export const currencySymbol = symbol;
