/* ============================================================
   Currency + number formatting for the live MoneyMate store.
   All stored money is a Number. `baseAmount` is always INR; the
   user's selected base currency is applied at render time.
   ============================================================ */

export const CURRENCIES = ['INR', 'USD', 'EUR', 'GBP'];
export const CURRENCY_SYMBOL = { INR: '₹', USD: '$', EUR: '€', GBP: '£' };

/** Units of INR per one unit of the currency. */
export const EXCHANGE_RATES = { INR: 1, USD: 83.15, EUR: 90.2, GBP: 105.4 };

export const maskChar = '•';

export function symbol(currency = 'INR') {
  return CURRENCY_SYMBOL[currency] || CURRENCY_SYMBOL.INR;
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
export function inrGroup(num) {
  const neg = num < 0;
  const [intPart, decPart] = Math.abs(num).toFixed(2).split('.');
  const last3 = intPart.slice(-3);
  const rest = intPart.slice(0, -3);
  const grouped = rest ? `${rest.replace(/\B(?=(\d{2})+(?!\d))/g, ',')},${last3}` : last3;
  return `${neg ? '-' : ''}${grouped}${decPart ? `.${decPart}` : ''}`;
}

function groupNumber(num, currency) {
  const abs = Math.abs(num);
  if (currency === 'INR') return inrGroup(abs);
  return abs.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function withSign(num, body) {
  return `${num < 0 ? '-' : ''}${body}`;
}

/** Full currency amount, e.g. ₹8,55,933.46 or $1,234.56. */
export function fmtFull(num, currency = 'INR') {
  return withSign(num, `${symbol(currency)}${groupNumber(num, currency)}`);
}

/** Compact KPI: ₹14.8L, ₹14.8K, $1.2K. */
export function fmtCompact(num, opts = {}, currency = 'INR') {
  if (typeof opts === 'string') { currency = opts; opts = {}; }
  if (typeof opts === 'number') opts = { decimals: opts };
  const neg = num < 0;
  const abs = Math.abs(num);
  const trim = (v) => v.toFixed(2).replace(/\.?0+$/, '');
  let out;
  if (abs >= 1e7) out = `${trim(abs / 1e7)}Cr`;
  else if (abs >= 1e5) out = `${trim(abs / 1e5)}L`;
  else if (abs >= 1e3) out = `${trim(abs / 1e3)}K`;
  else out = trim(abs);
  if (opts.decimals != null && !/[A-Za-z]/.test(out)) out = abs.toFixed(opts.decimals);
  return `${neg ? '-' : ''}${symbol(currency)}${out}`;
}

/** Short KPI: ₹0.0 / ₹24.9K. */
export function fmtShort(num, decimals = 1, currency = 'INR') {
  if (typeof decimals === 'string') { currency = decimals; decimals = 1; }
  const abs = Math.abs(num);
  let out;
  if (abs >= 1e5) out = `${(abs / 1e5).toFixed(2).replace(/\.?0+$/, '')}L`;
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
  const abs = Math.abs(num);
  const body = currency === 'INR' ? abs.toLocaleString('en-IN') : abs.toLocaleString('en-US');
  return withSign(num, `${symbol(currency)}${body}`);
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
  return CURRENCIES.map((id) => ({ id, label: `${symbol(id)} ${id}` }));
}
