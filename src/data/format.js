/* ============================================================
   Currency + number formatting for the live MoneyMate store.
   All stored money is a Number. `baseAmount` is always INR; the
   user's selected base currency is applied at render time.
   ============================================================ */

/** Supported presentation currencies and their locale rules. */
export const CURRENCY_CATALOG = [
  { id: 'INR', symbol: '₹', name: 'Indian Rupee', locale: 'en-IN', rate: 1, decimals: 2, compact: 'indian' },
  { id: 'USD', symbol: '$', name: 'US Dollar', locale: 'en-US', rate: 83.15, decimals: 2, compact: 'western' },
  { id: 'EUR', symbol: '€', name: 'Euro', locale: 'en-IE', rate: 90.2, decimals: 2, compact: 'western' },
  { id: 'GBP', symbol: '£', name: 'British Pound', locale: 'en-GB', rate: 105.4, decimals: 2, compact: 'western' },
  { id: 'CAD', symbol: 'CA$', name: 'Canadian Dollar', locale: 'en-CA', rate: 60.5, decimals: 2, compact: 'western' },
  { id: 'AUD', symbol: 'A$', name: 'Australian Dollar', locale: 'en-AU', rate: 54.6, decimals: 2, compact: 'western' },
  { id: 'JPY', symbol: '¥', name: 'Japanese Yen', locale: 'ja-JP', rate: 0.56, decimals: 0, compact: 'western' },
  { id: 'AED', symbol: 'د.إ', name: 'UAE Dirham', locale: 'ar-AE', rate: 22.64, decimals: 2, compact: 'western' },
  { id: 'CHF', symbol: 'CHF', name: 'Swiss Franc', locale: 'de-CH', rate: 94.6, decimals: 2, compact: 'western' },
];

export const CURRENCIES = CURRENCY_CATALOG.map((c) => c.id);
export const CURRENCY_SYMBOL = Object.fromEntries(CURRENCY_CATALOG.map((c) => [c.id, c.symbol]));
/** Units of INR per one unit of the currency. */
export const EXCHANGE_RATES = Object.fromEntries(CURRENCY_CATALOG.map((c) => [c.id, c.rate]));
export const CURRENCY_META = Object.fromEntries(CURRENCY_CATALOG.map((c) => [c.id, c]));

export const maskChar = '•';

export function currencyMeta(currency = 'INR') {
  return CURRENCY_META[currency] || CURRENCY_CATALOG[0];
}

export function symbol(currency = 'INR') {
  return currencyMeta(currency).symbol;
}

export function maskFor(currency = 'INR') {
  return `${symbol(currency)}${maskChar.repeat(6)}`;
}

/** Convert any supported currency into INR. */
export function toINR(amount, currency = 'INR') {
  const n = Number(amount) || 0;
  return n * (EXCHANGE_RATES[currency] || 1);
}

/** Convert INR into the requested display/base currency. */
export function fromINR(inr, currency = 'INR') {
  const n = Number(inr) || 0;
  return n / (EXCHANGE_RATES[currency] || 1);
}

/** Convert directly between two currencies. */
export function convert(amount, from = 'INR', to = 'INR') {
  return fromINR(toINR(amount, from), to);
}

/** Indian grouping: 855933.46 -> 8,55,933.46 */
export function inrGroup(num, decimals = 2) {
  const neg = num < 0;
  const [intPart, decPart] = Math.abs(num).toFixed(decimals).split('.');
  const last3 = intPart.slice(-3);
  const rest = intPart.slice(0, -3);
  const grouped = rest ? `${rest.replace(/\B(?=(\d{2})+(?!\d))/g, ',')},${last3}` : last3;
  return `${neg ? '-' : ''}${grouped}${decPart ? `.${decPart}` : ''}`;
}

function groupNumber(num, currency) {
  const meta = currencyMeta(currency);
  const abs = Math.abs(num);
  if (currency === 'INR') return inrGroup(abs, meta.decimals);
  try {
    return abs.toLocaleString(meta.locale, {
      minimumFractionDigits: meta.decimals,
      maximumFractionDigits: meta.decimals,
    });
  } catch (err) {
    return abs.toLocaleString('en-US', { minimumFractionDigits: meta.decimals, maximumFractionDigits: meta.decimals });
  }
}

function withSign(num, body) {
  return `${num < 0 ? '-' : ''}${body}`;
}

/** Full currency amount, e.g. ₹8,55,933.46 or $1,234.56. */
export function fmtFull(num, currency = 'INR') {
  const meta = currencyMeta(currency);
  const sign = num < 0 ? '-' : '';
  return `${sign}${meta.symbol}${groupNumber(num, currency)}`;
}

function compactBody(abs, currency) {
  const indian = currencyMeta(currency).compact === 'indian';
  const trim = (v) => v.toFixed(2).replace(/\.?0+$/, '');
  if (indian) {
    if (abs >= 1e7) return `${trim(abs / 1e7)}Cr`;
    if (abs >= 1e5) return `${trim(abs / 1e5)}L`;
    if (abs >= 1e3) return `${trim(abs / 1e3)}K`;
    return trim(abs);
  }
  if (abs >= 1e9) return `${trim(abs / 1e9)}B`;
  if (abs >= 1e6) return `${trim(abs / 1e6)}M`;
  if (abs >= 1e3) return `${trim(abs / 1e3)}K`;
  return trim(abs);
}

/** Compact KPI: ₹14.8L, $1.5M. */
export function fmtCompact(num, opts = {}, currency = 'INR') {
  if (typeof opts === 'string') { currency = opts; opts = {}; }
  if (typeof opts === 'number') opts = { decimals: opts };
  const body = compactBody(Math.abs(num), currency);
  if (opts.decimals != null && !/[A-Za-z]/.test(body)) {
    return withSign(num, `${symbol(currency)}${Math.abs(num).toFixed(opts.decimals)}`);
  }
  return withSign(num, `${symbol(currency)}${body}`);
}

/** Short KPI: ₹0.0 / ₹24.9K / $1.5M. */
export function fmtShort(num, decimals = 1, currency = 'INR') {
  if (typeof decimals === 'string') { currency = decimals; decimals = 1; }
  const abs = Math.abs(num);
  const indian = currencyMeta(currency).compact === 'indian';
  let out;
  if (indian && abs >= 1e7) out = `${(abs / 1e7).toFixed(2).replace(/\.?0+$/, '')}Cr`;
  else if (indian && abs >= 1e5) out = `${(abs / 1e5).toFixed(2).replace(/\.?0+$/, '')}L`;
  else if (abs >= 1e6) out = `${(abs / 1e6).toFixed(1).replace(/\.0$/, '')}M`;
  else if (abs >= 1e3) out = `${(abs / 1e3).toFixed(1).replace(/\.0$/, '')}K`;
  else out = abs.toFixed(decimals);
  return withSign(num, `${symbol(currency)}${out}`);
}

/** Western grouping with a forced USD symbol (Step 2/3 reference screens). */
export function usd(num, decimals = 2) {
  const abs = Math.abs(num);
  const s = abs.toLocaleString('en-US', { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
  return `${num < 0 ? '-' : ''}$${s}`;
}

export function fmtThousands(num, currency = 'INR') {
  const meta = currencyMeta(currency);
  const abs = Math.abs(num);
  let body;
  try {
    body = abs.toLocaleString(meta.locale, { maximumFractionDigits: 0 });
  } catch (err) {
    body = abs.toLocaleString('en-US', { maximumFractionDigits: 0 });
  }
  return withSign(num, `${meta.symbol}${body}`);
}

/** Privacy-aware formatter used by components via the store. */
export function money(store, fn, ...args) {
  if (store?.privacy) {
    const currency = store?.profile?.baseCurrency || 'INR';
    const raw = fn(...args);
    return raw.startsWith('-') ? `-${maskFor(currency)}` : maskFor(currency);
  }
  return fn(...args);
}

/** Two-decimal padded amount for tooltips. */
export function fmtExact(num, currency = 'INR') {
  return fmtFull(Number(num) || 0, currency);
}

export function currencyOptions() {
  return CURRENCY_CATALOG.map((c) => ({ id: c.id, label: `${c.symbol} ${c.id}`, name: c.name, symbol: c.symbol }));
}
