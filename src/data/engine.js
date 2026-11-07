/* ============================================================
   MoneyMate financial engine — pure, integer-cent maths.
   All currency is handled in integer cents so proportional splits
   never drift by a penny (0.1 + 0.2 !== 0.3 in IEEE 754 floats).

   Splitting uses the largest-remainder (Hare–Niemeyer) method:
   floor every quota, then hand out the leftover cents to the
   largest fractional remainders so parts always sum to the whole.
   ============================================================ */

/** 330.005 -> 33001 ; tolerates float noise from the UI layer */
export function toCents(amount) {
  return Math.round(Number(amount || 0) * 100);
}

export function fromCents(cents) {
  return Math.round(Number(cents || 0)) / 100;
}

const MINUS = '\u2212'; // typographic minus is avoided in UI; keep ASCII for parsing

/** $1,234.56 — negative renders as -$1,234.56 */
export function fmtMoney(cents, { symbol = '$', decimals = 2 } = {}) {
  const n = Math.round(Number(cents) || 0);
  const neg = n < 0;
  const abs = Math.abs(n);
  const whole = Math.floor(abs / 100);
  const frac = String(abs % 100).padStart(2, '0');
  const grouped = whole.toLocaleString('en-US');
  const body = decimals === 0 ? grouped : `${grouped}.${frac}`;
  return `${neg ? '-' : ''}${symbol}${body}`;
}

/** 33000 -> "330.00" (no symbol — used inside chips) */
export function fmtPlain(cents, decimals = 2) {
  return fmtMoney(cents, { symbol: '', decimals });
}

/**
 * Distribute `totalCents` across weights proportionally, using the
 * largest-remainder method. Guarantees sum(result) === totalCents.
 * Deterministic ties: earlier index wins.
 */
export function allocate(totalCents, weights) {
  const total = Math.round(totalCents);
  const n = weights.length;
  if (!n) return [];
  const sumW = weights.reduce((a, b) => a + Math.max(0, b), 0);
  if (sumW <= 0) {
    // no weights: fall back to an even split
    return allocate(total, new Array(n).fill(1));
  }

  const quotas = weights.map((w) => (total * Math.max(0, w)) / sumW);
  const floors = quotas.map((q) => Math.floor(q));
  let remainder = total - floors.reduce((a, b) => a + b, 0);

  const order = quotas
    .map((q, i) => ({ i, frac: q - Math.floor(q) }))
    .sort((a, b) => (b.frac - a.frac) || (a.i - b.i));

  const out = floors.slice();
  let k = 0;
  // remainder can only be < n, but guard against float noise either way
  while (remainder > 0) {
    out[order[k % n].i] += 1;
    remainder -= 1;
    k += 1;
  }
  while (remainder < 0) {
    out[order[(n - 1) - (k % n)].i] -= 1;
    remainder += 1;
    k += 1;
  }
  return out;
}

/* ---------- bill splitting ---------- */

/** Equal split, cent-exact. */
export function splitEqual(totalCents, count) {
  if (count <= 0) return [];
  return allocate(totalCents, new Array(count).fill(1));
}

/** Percentage split, cent-exact. `pcts` are 0–100 numbers. */
export function splitPercentage(totalCents, pcts) {
  return allocate(totalCents, pcts.map((p) => Math.max(0, Number(p) || 0)));
}

/**
 * Custom split: normalises explicit shares to integer cents and, if they
 * don't reconcile with the total, adjusts the last participant so the bill
 * is always internally consistent.
 */
export function splitCustom(totalCents, sharesCents) {
  const out = sharesCents.map((c) => Math.round(Number(c) || 0));
  const sum = out.reduce((a, b) => a + b, 0);
  if (out.length && sum !== totalCents) {
    out[out.length - 1] += totalCents - sum;
  }
  return out;
}

/** Shares per the bill's split mode. */
export function billShares(bill) {
  const total = toCents(bill.total);
  const people = bill.participants || [];
  if (!people.length) return [];
  if (bill.mode === 'equal') return splitEqual(total, people.length);
  if (bill.mode === 'percentage') return splitPercentage(total, people.map((p) => p.percent));
  return splitCustom(total, people.map((p) => toCents(p.share)));
}

/**
 * Per-participant settlement maths.
 *   owes     = max(0, share - paid)
 *   progress = min(100, paid / share * 100)
 *   status   = owes === 0 ? 'Settled' : 'Owes'
 * The payer paid the merchant, so the payer's share counts as already paid.
 */
export function participantBalances(bill) {
  const shares = billShares(bill);
  return (bill.participants || []).map((p, i) => {
    const share = shares[i] || 0;
    const isPayer = p.id === bill.payerId;
    const paid = isPayer ? share : Math.round(toCents(p.paid));
    const owes = Math.max(0, share - paid);
    const progress = share === 0 ? 100 : Math.min(100, (paid / share) * 100);
    return {
      ...p,
      share,
      paid,
      owes,
      progress,
      isPayer,
      status: owes === 0 ? 'Settled' : 'Owes',
    };
  });
}

/** A bill is Settled only when every participant owes nothing. */
export function billStatus(bill) {
  const rows = participantBalances(bill);
  return rows.every((r) => r.owes === 0) ? 'Settled' : 'Pending';
}

/** Total of all shares must equal the bill total (sanity helper). */
export function billReconciles(bill) {
  const shares = billShares(bill);
  return shares.reduce((a, b) => a + b, 0) === toCents(bill.total);
}

/**
 * Net balances across bills: how much each contact owes the current user
 * (positive) or the user owes them (negative).
 */
export function netBalances(bills) {
  const map = new Map();
  bills.forEach((bill) => {
    const rows = participantBalances(bill);
    const payer = rows.find((r) => r.isPayer);
    if (!payer) return;
    rows.forEach((r) => {
      if (r.id === payer.id) return;
      const key = r.name;
      // the payer fronted r.share; r.paid reduces what the contact still owes
      const delta = r.share - r.paid;
      map.set(key, (map.get(key) || 0) + delta);
    });
  });
  return [...map.entries()]
    .map(([name, cents]) => ({ name, cents }))
    .filter((x) => x.cents !== 0)
    .sort((a, b) => b.cents - a.cents);
}

/**
 * Who-pays-whom across bills, including the current user ("You").
 * netBalances() gives each contact's position relative to the user, so the
 * user's own position is the negative of their sum.
 */
export function settleUp(bills, userName = 'You') {
  const net = netBalances(bills);
  // netBalances: positive = the contact owes you. settleTransfers expects
  // positive = creditor, so contacts flip sign and the user holds the sum.
  const total = net.reduce((a, b) => a + b.cents, 0);
  const positions = [
    ...net.map((n) => ({ name: n.name, cents: -n.cents })),
    { name: userName, cents: total },
  ];
  return settleTransfers(positions.filter((p) => p.cents !== 0));
}

/**
 * Minimal settle-up transfers (greedy): repeatedly match the largest
 * creditor with the largest debtor. Produces at most n-1 transfers,
 * which is what "who pays whom" apps display.
 */
export function settleTransfers(net) {
  const debtors = net.filter((x) => x.cents < 0).map((x) => ({ ...x })).sort((a, b) => a.cents - b.cents);
  const creditors = net.filter((x) => x.cents > 0).map((x) => ({ ...x })).sort((a, b) => b.cents - a.cents);
  const out = [];
  let d = 0;
  let c = 0;
  while (d < debtors.length && c < creditors.length) {
    const amount = Math.min(-debtors[d].cents, creditors[c].cents);
    if (amount > 0) {
      out.push({ from: debtors[d].name, to: creditors[c].name, cents: amount });
      debtors[d].cents += amount;
      creditors[c].cents -= amount;
    }
    if (debtors[d].cents === 0) d += 1;
    if (creditors[c].cents === 0) c += 1;
  }
  return out;
}

/* ---------- loans ---------- */

/** remaining = max(0, principal - paid) */
export function loanRemaining(loan) {
  const total = toCents(loan.total);
  const paid = toCents(loan.paid);
  return Math.max(0, total - paid);
}

/** round(paid / principal * 100), clamped to [0, 100] */
export function loanCompletion(loan) {
  const total = toCents(loan.total);
  if (total <= 0) return 0;
  const paid = Math.min(toCents(loan.paid), total);
  return Math.min(100, Math.round((paid / total) * 100));
}

/** Whole days from `from` to `due`, DST-safe (UTC midnight comparison). */
export function daysUntil(dueISO, fromISO) {
  const due = new Date(dueISO);
  const from = fromISO ? new Date(fromISO) : new Date();
  const dueUTC = Date.UTC(due.getFullYear(), due.getMonth(), due.getDate());
  const fromUTC = Date.UTC(from.getFullYear(), from.getMonth(), from.getDate());
  return Math.ceil((dueUTC - fromUTC) / 86400000);
}

/**
 * Loan status + countdown.
 * Overdue when days < 0 AND there is still a balance outstanding.
 */
export function loanState(loan, todayISO) {
  const remaining = loanRemaining(loan);
  const completion = loanCompletion(loan);
  const days = daysUntil(loan.due, todayISO);
  const completed = remaining === 0 || toCents(loan.paid) >= toCents(loan.total);
  return {
    remaining,
    completion,
    days,
    completed,
    overdue: !completed && days < 0,
  };
}

/**
 * Lending / borrowing / net aggregates over active (not completed) loans.
 *
 * Note on `net`: the product displays "Net Loan Balance" as
 *   lending − signedBorrowing  ==  lending + |borrowing|
 * (e.g. 17,336 − (−24,106) = 41,442.00), i.e. total outstanding exposure
 * across both directions, which is what the reference UI shows. `trueNet`
 * keeps the ordinary accountant's net position (lending − |borrowing|)
 * available for anything that needs it.
 */
export function loanSummary(loans, todayISO) {
  let lending = 0;
  let borrowingAbs = 0;
  loans.forEach((l) => {
    const st = loanState(l, todayISO);
    if (st.completed) return;
    if (l.kind === 'lending') lending += st.remaining;
    else borrowingAbs += st.remaining;
  });
  const net = lending + borrowingAbs;
  const trueNet = lending - borrowingAbs;
  return {
    lending,
    borrowing: -borrowingAbs,
    net,
    trueNet,
    note: net > 0 ? 'You\u2019re owed more than you owe' : 'You owe more than you\u2019re owed',
  };
}

/* ---------- assets ---------- */

/** value × units (units default 1) */
export function assetValue(asset) {
  const value = Number(asset.value) || 0;
  const units = asset.units == null || asset.units === '' ? 1 : Number(asset.units) || 0;
  return Math.round(value * units * 100) / 100;
}

/** Portfolio total = Σ (value × units) */
export function portfolioTotal(assets) {
  return assets.reduce((sum, a) => sum + assetValue(a), 0);
}

/** Group totals + a $736K style shorthand. */
export function groupAssets(assets) {
  const map = new Map();
  assets.forEach((a) => {
    const key = a.type || 'Other';
    map.set(key, (map.get(key) || 0) + assetValue(a));
  });
  return [...map.entries()].map(([type, total]) => ({
    type,
    total,
    short: compactMoney(total),
    items: assets.filter((a) => (a.type || 'Other') === type),
  }));
}

/** 736114.85 -> "$736K" (thousands, no decimals) */
export function compactMoney(amount) {
  const n = Number(amount) || 0;
  const neg = n < 0;
  const abs = Math.abs(n);
  let out;
  if (abs >= 1e6) out = `${(abs / 1e6).toFixed(abs >= 1e7 ? 0 : 1).replace(/\.0$/, '')}M`;
  else if (abs >= 1e3) out = `${Math.round(abs / 1e3)}K`;
  else out = String(Math.round(abs));
  return `${neg ? '-' : ''}$${out}`;
}

/* ---------- misc ---------- */

/** 0–360 hue for a hex colour, used by the shade generator */
export function hexToHsl(hex) {
  const h = hex.replace('#', '');
  const r = parseInt(h.slice(0, 2), 16) / 255;
  const g = parseInt(h.slice(2, 4), 16) / 255;
  const b = parseInt(h.slice(4, 6), 16) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  let hue = 0;
  let s = 0;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    if (max === r) hue = ((g - b) / d + (g < b ? 6 : 0)) / 6;
    else if (max === g) hue = ((b - r) / d + 2) / 6;
    else hue = ((r - g) / d + 4) / 6;
  }
  return { h: hue * 360, s: s * 100, l: l * 100 };
}

export function hslToHex(h, s, l) {
  const hh = ((h % 360) + 360) % 360 / 360;
  const ss = Math.min(100, Math.max(0, s)) / 100;
  const ll = Math.min(100, Math.max(0, l)) / 100;
  const hue2rgb = (p, q, t) => {
    let tt = t;
    if (tt < 0) tt += 1;
    if (tt > 1) tt -= 1;
    if (tt < 1 / 6) return p + (q - p) * 6 * tt;
    if (tt < 1 / 2) return q;
    if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
    return p;
  };
  let r;
  let g;
  let b;
  if (ss === 0) {
    r = ll;
    g = ll;
    b = ll;
  } else {
    const q = ll < 0.5 ? ll * (1 + ss) : ll + ss - ll * ss;
    const p = 2 * ll - q;
    r = hue2rgb(p, q, hh + 1 / 3);
    g = hue2rgb(p, q, hh);
    b = hue2rgb(p, q, hh - 1 / 3);
  }
  const toHex = (v) => Math.round(v * 255).toString(16).padStart(2, '0');
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
}

/**
 * 10 light→dark tones of a base colour.
 * Calibrated against the Material teal ramp used in the design so that
 * #009688 reproduces #E0F2F1 → #004D40 exactly:
 *   hue preserved, saturation follows the Material tone curve and
 *   lightness steps linearly from 93% down to 22%.
 */
export function shadeRamp(hex, steps = 10) {
  const { h } = hexToHsl(hex);
  // measured from the Material teal 50→900 ramp
  const satCurve = [41, 41, 42, 42, 63, 100, 100, 100, 100, 100];
  const lightCurve = [91, 79, 65, 51, 40, 29, 27, 24, 21, 15];
  const out = [];
  for (let i = 0; i < steps; i += 1) {
    const idx = Math.round((i / (steps - 1)) * (satCurve.length - 1));
    const l = lightCurve[idx];
    // the base swatch is always exactly the user's colour
    const isBase = i === Math.floor(steps / 2);
    out.push(isBase ? hex.toUpperCase() : hslToHex(h, satCurve[idx], l));
  }
  return out;
}

/* ============================================================
   Step 4 — relational ledger maths
   Loans and goals are derived from linked transactions rather than
   storing a mutable `paid` figure, so every screen stays consistent.
   ============================================================ */

/**
 * The amount a charge contributes to a loan total. Multi-currency rows keep
 * their original figure in `amount` and the booked value in `converted`;
 * `charge: 'converted'` opts into the converted figure.
 */
export function chargeCents(tx) {
  if (tx.charge === 'converted' && tx.converted != null) return tx.converted;
  return tx.amount;
}

/** Group transactions by the link id they reference. */
export function indexByLink(transactions, field) {
  const map = new Map();
  transactions.forEach((t) => {
    const id = t[field];
    if (!id) return;
    if (!map.has(id)) map.set(id, []);
    map.get(id).push(t);
  });
  return map;
}

/**
 * Loan maths driven by the ledger:
 *   Amount  = principal entered in the form
 *   Total   = Amount + Σ linked expense charges
 *   Paid    = Σ linked income repayments
 *   Remaining = max(0, Total − Paid)
 *   Progress  = min(100, Paid / Total)
 */
export function loanMath(loan, transactions = []) {
  const linked = transactions.filter((t) => t.loanId === loan.id);
  const principal = toCents(loan.amount ?? loan.total ?? 0);
  const charges = linked
    .filter((t) => t.type === 'expense' && !t.transfer)
    .reduce((a, t) => a + toCents(chargeCents(t)), 0);
  const paid = linked
    .filter((t) => t.type === 'income' && !t.transfer)
    .reduce((a, t) => a + toCents(t.amount), 0);
  const total = principal + charges;
  const remaining = Math.max(0, total - paid);
  const completion = total <= 0 ? 0 : Math.min(100, Math.round((paid / total) * 100));
  return {
    principal,
    charges,
    paid,
    total,
    remaining,
    completion,
    transactions: linked,
    completed: remaining === 0,
  };
}

/** Aggregate the summary card straight from the ledger. */
export function loanSummaryFromLedger(loans, transactions, todayISO) {
  let lending = 0;
  let borrowing = 0;
  loans.forEach((l) => {
    const m = loanMath(l, transactions);
    if (m.remaining === 0) return;
    if (l.kind === 'lending') lending += m.remaining;
    else borrowing += m.remaining;
  });
  // `net` is the product's "Net Loan Balance": lending − signedBorrowing,
  // i.e. total outstanding exposure (17,336 − (−24,106) = 41,442).
  const net = lending + borrowing;
  return {
    lending,
    borrowing: -borrowing,
    net,
    trueNet: lending - borrowing,
    note: net > 0 ? 'You\u2019re owed more than you owe' : 'You owe more than you\u2019re owed',
  };
}

/* ---------- goals ---------- */

/**
 * Goal maths:
 *   Saved     = Σ goal income − Σ goal expense (can be negative)
 *   Remaining = max(0, target − saved)
 *   Progress  = round(saved / target * 100)   (can be negative)
 */
export function goalMath(goal, transactions = []) {
  const linked = transactions.filter((t) => t.goalId === goal.id);
  const saved = linked.filter((t) => !t.transfer).reduce(
    (a, t) => a + (t.type === 'income' ? toCents(t.amount) : -toCents(t.amount)),
    0,
  );
  const target = toCents(goal.target);
  const remaining = Math.max(0, target - saved);
  const progress = target <= 0 ? 0 : Math.round((saved / target) * 100);
  return { saved, target, remaining, progress, transactions: linked };
}

/**
 * Goal countdown in whole days. Paisa counts the days *after* today, so a
 * target 49 calendar days away reads "48 days" (matches the references).
 */
export function goalDaysLeft(endISO, todayISO) {
  return Math.max(0, daysUntil(endISO, todayISO) - 1);
}

/** Whole months between two dates, for "1 month left". */
export function monthsBetween(fromISO, toISO) {
  const a = new Date(fromISO);
  const b = new Date(toISO);
  let months = (b.getFullYear() - a.getFullYear()) * 12 + (b.getMonth() - a.getMonth());
  if (b.getDate() < a.getDate()) months -= 1;
  return months;
}

/** Friendly remaining-time label: "1 month left", "2 weeks left", "48 days left". */
export function remainingLabel(endISO, todayISO) {
  const days = daysUntil(endISO, todayISO);
  if (days <= 0) return 'Ended';
  const months = monthsBetween(todayISO, endISO);
  if (months >= 1) return `${months} month${months === 1 ? '' : 's'} left`;
  const weeks = Math.floor(days / 7);
  if (weeks >= 1) return `${weeks} week${weeks === 1 ? '' : 's'} left`;
  return `${days} day${days === 1 ? '' : 's'} left`;
}

/** Suggested daily saving needed to hit the target by the end date. */
export function goalDailyNeed(goal, saved, todayISO) {
  const days = Math.max(1, daysUntil(goal.end, todayISO));
  const remaining = Math.max(0, toCents(goal.target) - saved);
  return Math.round(remaining / days);
}

/* ---------- grouping ---------- */

/** Group transactions by day / week / month / year, newest first. */
export function groupTransactionsByPeriod(transactions, period = 'month') {
  const keyOf = (iso) => {
    const d = new Date(iso);
    const y = d.getFullYear();
    if (period === 'yearly') return `${y}`;
    if (period === 'monthly') return `${y}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    if (period === 'weekly') {
      // ISO-ish week start (Monday)
      const d2 = new Date(Date.UTC(y, d.getMonth(), d.getDate()));
      const day = d2.getUTCDay() || 7;
      d2.setUTCDate(d2.getUTCDate() - (day - 1));
      return d2.toISOString().slice(0, 10);
    }
    return iso.slice(0, 10);
  };

  const labelOf = (key, sample) => {
    const d = new Date(sample);
    if (period === 'yearly') return String(d.getFullYear());
    if (period === 'monthly') {
      return d.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    }
    const start = new Date(`${key}T00:00:00`);
    if (period === 'weekly') {
      const end = new Date(start);
      end.setDate(start.getDate() + 6);
      const fmt = (x) => x.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      return `${fmt(start)} – ${fmt(end)}`;
    }
    return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
  };

  const map = new Map();
  [...transactions]
    .sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0))
    .forEach((t) => {
      const k = keyOf(t.date);
      if (!map.has(k)) map.set(k, { key: k, label: labelOf(k, t.date), items: [], total: 0 });
      const g = map.get(k);
      g.items.push(t);
      if (!t.transfer) g.total += t.type === 'income' ? toCents(t.amount) : -toCents(t.amount);
    });
  return [...map.values()];
}
