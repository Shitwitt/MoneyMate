import React from 'react';
import {
  Banknote,
  Building2,
  ChartNoAxesColumn,
  Check,
  ChevronDown,
  ChevronsUpDown,
  CircleArrowRight,
  Copy,
  HandCoins,
  Landmark,
  Minus,
  PiggyBank,
  Store,
  TrendingUp,
  UserRound,
  Wallet,
  CreditCard,
  CircleDollarSign,
} from 'lucide-react';

import { paletteMain } from '../../data/step3Data.js';
import { shadeRamp } from '../../data/engine.js';
import { demoStore } from '../../data/demoStore.js';

/* ============================================================
   Icon catalogue — every account / category glyph in the app
   resolves through here so tinting stays consistent.
   ============================================================ */

const GLYPHS = {
  bank: Building2,
  building: Landmark,
  piggy: PiggyBank,
  wallet: Wallet,
  card: CreditCard,
  cash: Banknote,
  dollar: CircleDollarSign,
  chart: ChartNoAxesColumn,
  trend: TrendingUp,
  calc: Store,
  user: UserRound,
  hand: HandCoins,
  transfer: ChevronsUpDown,
  pie: CircleArrowRight,
  flag: ChartNoAxesColumn,
  check: Check,
  minus: Minus,
};

export function Glyph({ name, ...rest }) {
  const Cmp = GLYPHS[name] || Wallet;
  return <Cmp {...rest} />;
}

/** 44×44 rounded tile used by both ledgers. */
export function IconTile({ icon, size = 44, radius = 14 }) {
  const spec = icon || { bg: '#8E8580', fg: '#FFFFFF', glyph: 'wallet' };
  return (
    <span
      className="ic-tile"
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        background: spec.bg,
        color: spec.fg,
      }}
      aria-hidden="true"
    >
      <Glyph name={spec.glyph} />
    </span>
  );
}

/* ============================================================
   Colour picker — Primary / Accent / Wheel, hex pill, copy
   ============================================================ */

/** 24 fully-saturated hues, one per swatch row-slot in the reference. */
export const WHEEL_COLORS = (() => {
  const out = [];
  const n = 24;
  for (let i = 0; i < n; i += 1) {
    const h = Math.round((i / n) * 360);
    // HSL(h, 100%, 52%) -> hex, no dependencies
    const c = (1 - Math.abs(((h / 60) % 2) - 1)) * 1;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = 0.48;
    let rgb;
    if (h < 60) rgb = [1, x, 0];
    else if (h < 120) rgb = [x, 1, 0];
    else if (h < 180) rgb = [0, 1, x];
    else if (h < 240) rgb = [0, x, 1];
    else if (h < 300) rgb = [x, 0, 1];
    else rgb = [1, 0, x];
    out.push(
      `#${rgb
        .map((v) =>
          Math.round(Math.min(255, Math.max(0, (v + m) * 255)))
            .toString(16)
            .padStart(2, '0'),
        )
        .join('')
        .toUpperCase()}`,
    );
  }
  return out;
})();

export function checkOn(hex) {
  // relative luminance decides whether the tick is dark or light
  const h = hex.replace('#', '');
  const r = parseInt(h.slice(0, 2), 16) / 255;
  const g = parseInt(h.slice(2, 4), 16) / 255;
  const b = parseInt(h.slice(4, 6), 16) / 255;
  const lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  return lum > 0.6 ? '#3B2016' : '#FFFFFF';
}

function Swatch({ hex, active, onPick }) {
  return (
    <button
      type="button"
      className={`sw4${active ? ' on' : ''}`}
      style={{ background: hex }}
      aria-label={hex}
      aria-pressed={active}
      onClick={() => onPick(hex)}
    >
      {active ? (
        <svg viewBox="0 0 24 24" fill="none" stroke={checkOn(hex)} strokeWidth="3" strokeLinecap="round">
          <path d="m5 13 4.5 4.5L19 7" />
        </svg>
      ) : null}
    </button>
  );
}

export function ColorPicker({ primary, accent, onChange }) {
  const [tab, setTab] = React.useState('primary');
  const [copied, setCopied] = React.useState(false);
  const active = tab === 'accent' ? accent : primary;
  const set = (hex) => onChange(tab === 'accent' ? 'accent' : 'primary', hex);

  // "0xFF9C27" style label: 6 hex digits, uppercase, Flutter-ish prefix
  const label = `0xFF${active.replace('#', '').toUpperCase().slice(0, 6)}`;

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(label);
      setCopied(true);
      setTimeout(() => setCopied(false), 1200);
    } catch (err) {
      setCopied(true);
      setTimeout(() => setCopied(false), 1200);
    }
  };

  const ramp = shadeRamp(active, 10);

  return (
    <section className="col-section">
      <h3 className="col-title">Colors</h3>

      <div className="col-tabs" role="tablist">
        {[
          { id: 'primary', label: 'Primary' },
          { id: 'accent', label: 'Accent' },
          { id: 'wheel', label: 'Wheel' },
        ].map((t) => (
          <React.Fragment key={t.id}>
            {t.id === 'wheel' ? <span className="col-sep" aria-hidden="true" /> : null}
            <button
              type="button"
              role="tab"
              aria-selected={tab === t.id}
              className={`col-tab${tab === t.id ? ' on' : ''}`}
              onClick={() => setTab(t.id)}
            >
              {t.label}
            </button>
          </React.Fragment>
        ))}
      </div>

      <div className="sw-grid" role="group" aria-label={`${tab} palette`}>
        {(tab === 'wheel' ? WHEEL_COLORS : paletteMain).map((c) => (
          <Swatch key={`m${c}`} hex={c} active={active.toUpperCase() === c.toUpperCase()} onPick={set} />
        ))}
        {tab === 'wheel'
          ? null
          : ramp.map((c) => (
              <Swatch
                key={`t${c}`}
                hex={c}
                active={active.toUpperCase() === c.toUpperCase()}
                onPick={set}
              />
            ))}
      </div>

      <button type="button" className="hex-pill" onClick={copy} aria-label={`Copy colour ${label}`}>
        <span>{copied ? 'Copied!' : label}</span>
        <Copy />
      </button>
    </section>
  );
}

/* ============================================================
   Pickers used by both editors
   ============================================================ */

export function PersonPicker({ people, value, onChange, onAdd }) {
  const [open, setOpen] = React.useState(false);
  return (
    <div className="pk-block">
      <button type="button" className="pk-head" onClick={() => setOpen((v) => !v)} aria-expanded={open}>
        <span className="pk-ico">
          <UserRound />
        </span>
        <span className="pk-mid">
          <span className="pk-label">Person</span>
          <span className={`pk-value${value ? ' set' : ''}`}>{value || 'Select person'}</span>
        </span>
        <ChevronDown className={`pk-caret${open ? ' up' : ''}`} />
      </button>

      {open ? (
        <div className="chip-row">
          {people.map((p) => (
            <button
              key={p}
              type="button"
              className={`pk-chip${value === p ? ' on' : ''}`}
              aria-pressed={value === p}
              onClick={() => {
                onChange(p);
                setOpen(false);
              }}
            >
              <span className="pk-dot" style={{ background: TINTS[p % TINTS.length] }} />
              {p}
            </button>
          ))}
          <button type="button" className="pk-chip add" onClick={onAdd}>
            <span className="pk-plus">+</span>
            Add
          </button>
        </div>
      ) : null}
    </div>
  );
}

const TINTS = ['#26A69A', '#1E88E5', '#8E24AA', '#EF6C00', '#E91E63', '#00897B'];

export function AccountPicker({ accounts, value, onChange, onAdd, label = 'Account', defaultOpen = true }) {
  const [open, setOpen] = React.useState(defaultOpen);
  return (
    <div className="pk-block">
      <button type="button" className="pk-head" onClick={() => setOpen((v) => !v)} aria-expanded={open}>
        <span className="pk-ico">
          <Wallet />
        </span>
        <span className="pk-mid">
          <span className="pk-label">{label}</span>
          <span className={`pk-value${value ? ' set' : ''}`}>{value || 'Select account'}</span>
        </span>
        <ChevronDown className={`pk-caret${open ? ' up' : ''}`} />
      </button>

      {open ? (
        <div className="chip-row">
          {accounts.map((a) => (
            <button
              key={a.id}
              type="button"
              className={`pk-chip${value === a.name ? ' on' : ''}`}
              aria-pressed={value === a.name}
              onClick={() => {
                onChange(a.name);
                setOpen(false);
              }}
            >
              <span className="pk-gl" style={{ color: a.color }}>
                <Glyph name={a.icon} />
              </span>
              {a.name}
            </button>
          ))}
          <button type="button" className="pk-chip add" onClick={onAdd}>
            <span className="pk-plus">+</span>
            Add
          </button>
        </div>
      ) : null}
    </div>
  );
}

export function CategoryPicker({ categories, value, onChange, onAdd }) {
  const [open, setOpen] = React.useState(true);
  return (
    <div className="pk-block">
      <button type="button" className="pk-head" onClick={() => setOpen((v) => !v)} aria-expanded={open}>
        <span className="pk-ico">
          <ChartNoAxesColumn />
        </span>
        <span className="pk-mid">
          <span className="pk-label">Category</span>
          <span className={`pk-value${value ? ' set' : ''}`}>{value || 'Select category'}</span>
        </span>
        <ChevronDown className={`pk-caret${open ? ' up' : ''}`} />
      </button>

      {open ? (
        <div className="chip-row">
          {categories.map((c) => (
            <button
              key={c.id}
              type="button"
              className={`pk-chip${value === c.name ? ' on' : ''}`}
              aria-pressed={value === c.name}
              onClick={() => onChange(c.name)}
            >
              <span className="pk-gl" style={{ color: c.color }}>
                <Glyph name={c.icon} />
              </span>
              {c.name}
            </button>
          ))}
          <button type="button" className="pk-chip add" onClick={onAdd}>
            <span className="pk-plus">+</span>
            Add
          </button>
        </div>
      ) : null}
    </div>
  );
}

/** Small dashed "+ Add" sheet used by the three pickers. */
export function AddMini({ title, placeholder, onSave, onClose }) {
  const [value, setValue] = React.useState('');
  return (
    <div className="dlg-scrim" role="presentation" onClick={onClose}>
      <form
        className="dlg dark"
        onClick={(e) => e.stopPropagation()}
        onSubmit={(e) => {
          e.preventDefault();
          if (!value.trim()) return;
          onSave(value.trim());
          onClose();
        }}
      >
        <h3>{title}</h3>
        <label className="dlg-field">
          Name
          <input
            autoFocus
            value={value}
            aria-label={title}
            placeholder={placeholder}
            onChange={(e) => setValue(e.target.value)}
          />
        </label>
        <div className="dlg-actions">
          <button type="button" className="dlg-cancel" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="dlg-save">
            Add
          </button>
        </div>
      </form>
    </div>
  );
}

/* ============================================================
   Transaction row — the linked-ledger row used by loan payment
   history and goal transactions.
   ============================================================ */

const CURRENCY_SYMBOL = { USD: '$', GBP: '£', EUR: '€', INR: '₹' };

function money2(cents, sym = '$') {
  const neg = cents < 0;
  const abs = Math.abs(cents);
  const whole = Math.floor(abs / 100).toLocaleString('en-US');
  return `${neg ? '-' : ''}${sym}${whole}.${String(abs % 100).padStart(2, '0')}`;
}

export function TxRow({ tx, todayISO }) {
  const cents = Math.round(tx.amount * 100);
  const isTransfer = tx.transfer;
  const sym = CURRENCY_SYMBOL[tx.currency] || '$';

  // a foreign-currency row shows the original figure, with the booked
  // USD amount underneath it
  const shown = tx.converted ? Math.round(tx.amount * 100) : cents;
  let amountText = money2(shown, tx.converted ? sym : '$');
  let amountClass;
  if (isTransfer) amountClass = 'blue';
  else if (tx.type === 'income') amountClass = 'green';
  else amountClass = 'red';

  const dateLabel = new Date(`${tx.date}T00:00:00`).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
  const hasYear = tx.date.slice(0, 4) !== String(todayISO || '2026').slice(0, 4);
  const dateFull = hasYear
    ? new Date(`${tx.date}T00:00:00`).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      })
    : dateLabel;

  // route line: "Cash Wallet -> HDFC Bank" for transfers, account otherwise
  const acct = tx.transfer ? null : tx.account;

  return (
    <article
      className="tx-row"
      data-live-row="true"
      role="button"
      tabIndex={0}
      onClick={() => demoStore.openTransactionEditor(tx.id)}
      onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') demoStore.openTransactionEditor(tx.id); }}
    >
      <IconTile icon={tx.icon} />

      <div className="tx-body">
        <h4 className="tx-title">{tx.title}</h4>
        <p className="tx-meta">
          <span>{tx.time || '1:03 AM'}</span>
          <span className="tx-dot">•</span>
          <span>{dateFull}</span>
          {tx.transfer ? (
            <>
              <span className="tx-dot">•</span>
              <span className="tx-route">
                <Wallet className="tx-gl" />
                {tx.from}
                <span className="tx-arr">→</span>
                <Banknote className="tx-gl" />
                {tx.to}
              </span>
            </>
          ) : acct ? (
            <>
              <span className="tx-dot">•</span>
              <span className="tx-route">
                <Wallet className="tx-gl" />
                {acct}
              </span>
            </>
          ) : null}
        </p>

        <div className="tx-chips">
          {(tx.chips || []).map((c, i) => (
            <span
              className="tx-chip"
              key={`${c.label}-${i}`}
              style={{ background: c.bg, color: c.fg }}
            >
              {c.icon ? <Glyph name={c.icon} /> : null}
              {c.label}
            </span>
          ))}
        </div>
      </div>

      <div className="tx-amounts">
        <span className={`tx-amt ${amountClass}`}>{amountText}</span>
        {tx.converted ? <span className="tx-conv">{money2(Math.round(tx.converted * 100))}</span> : null}
      </div>
    </article>
  );
}

/* ============================================================
   Wavy progress bar — a sinusoidal cap over a track, matching the
   goals reference. Path maths is deterministic so tests can assert it.
   ============================================================ */

/** Sine wave path for a bar of `w` × `h` with `amp` amplitude. */
export function wavePath(w, h, amp = 3.5, cycles = 2.4) {
  const mid = h / 2;
  const steps = 40;
  let d = `M 0 ${mid}`;
  for (let i = 0; i <= steps; i += 1) {
    const x = (i / steps) * w;
    const y = mid + Math.sin((x / w) * Math.PI * 2 * cycles) * amp;
    d += ` L ${x.toFixed(2)} ${y.toFixed(2)}`;
  }
  // close around the right cap so the stroke keeps its round ends
  return d;
}

export function WavyBar({ pct, color, track, height = 14, trackHeight = 8, id = 'wv' }) {
  const clamped = Math.max(0, Math.min(100, pct));
  const W = 320;
  const amp = Math.max(2.2, height * 0.3);

  return (
    <div className="wavy" style={{ height }} aria-hidden="true">
      <span className="wavy-track" style={{ background: track, height: trackHeight }} />
      {clamped > 0 ? (
        <svg className="wavy-fill" viewBox={`0 0 ${W} ${height}`} preserveAspectRatio="none">
          <defs>
            <clipPath id={`${id}-clip`}>
              <rect x="0" y="0" width={(W * clamped) / 100} height={height} />
            </clipPath>
          </defs>
          <g clipPath={`url(#${id}-clip)`}>
            <path
              d={wavePath(W, height, amp, 2.2)}
              fill="none"
              stroke={color}
              strokeWidth={trackHeight}
              strokeLinecap="round"
            />
          </g>
        </svg>
      ) : null}
    </div>
  );
}

/* ============================================================
   Page pieces shared by the goals screens
   ============================================================ */

export function GoalsTabBar({ options, value, onChange }) {
  return (
    <div className="gtabs" role="tablist">
      {options.map((o) => (
        <button
          key={o.id}
          type="button"
          role="tab"
          aria-selected={value === o.id}
          className={`gtab${value === o.id ? ' on' : ''}`}
          onClick={() => onChange(o.id)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}
