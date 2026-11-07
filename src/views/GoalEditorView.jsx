import React from 'react';
import { Camera, CalendarDays, Wallet, Save } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { accountCatalog } from '../data/step4Data.js';
import {
  ColorPicker,
  AccountPicker,
  Glyph,
  AddMini,
} from '../components/step4/ui4.jsx';

function oneDecimal(v) {
  if (v === '' || v == null) return '';
  const n = Number(v);
  if (Number.isNaN(n)) return String(v);
  return Number.isInteger(n) ? n.toFixed(1) : String(n);
}

function usDate(iso) {
  if (!iso) return '--/--/----';
  return new Date(`${iso}T00:00:00`).toLocaleDateString('en-US', {
    month: '2-digit',
    day: '2-digit',
    year: 'numeric',
  });
}

export default function GoalEditorView() {
  const params = useStore((s) => s.route.params);
  const goals = useStore((s) => s.goals);
  const existing = goals.find((g) => g.id === params.id);

  const [name, setName] = React.useState(existing?.title || '');
  const [amount, setAmount] = React.useState(existing ? oneDecimal(existing.target) : '');
  const [start, setStart] = React.useState(existing?.start || '2026-11-07');
  const [end, setEnd] = React.useState(existing?.end || '2026-11-07');
  const [account, setAccount] = React.useState(existing?.account || '');
  const [primary, setPrimary] = React.useState(existing?.color || '#F44336');
  const [accent, setAccent] = React.useState(existing?.accent || '#FF9C27');
  const [acctList, setAcctList] = React.useState(accountCatalog);
  const [addAccount, setAddAccount] = React.useState(false);

  const save = () => {
    const id = existing?.id || `gl-${Date.now().toString(36)}`;
    demoStore.saveGoal({
      id,
      title: name.trim() || 'Untitled Goal',
      target: Number(amount) || 0,
      start,
      end,
      account,
      category: existing?.category || 'Savings',
      status: existing?.status || 'active',
      color: primary,
      accent,
      surface: existing?.surface || '#231824',
      tile: primary,
      bar: primary,
      track: existing?.track || '#3A243E',
      pillBg: existing?.pillBg || '#38203E',
      pillFg: accent,
    });
  };

  return (
    <div className="view dark-view goal-editor s4">
      <header className="dark-header">
        <button type="button" className="dark-back" aria-label="Back" onClick={() => demoStore.back()}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <path d="M19 12H5m6-7-7 7 7 7" />
          </svg>
        </button>
        <h1 className="dark-title">Goal</h1>
      </header>

      <div className="ed-row">
        <button
          type="button"
          className="ed-icon goal"
          style={{ background: primary }}
          aria-label="Goal icon"
        >
          <Glyph name="bank" />
          <span className="ed-icon-badge">
            <Camera />
          </span>
        </button>
        <input
          className="ed-input"
          value={name}
          placeholder="Ex: Trip to Japan"
          aria-label="Goal name"
          onChange={(e) => setName(e.target.value)}
        />
      </div>

      <input
        className="ed-input ed-full"
        value={amount}
        inputMode="decimal"
        placeholder="Amount"
        aria-label="Target amount"
        onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ''))}
      />

      <div className="ed-dates">
        <label className="ed-date">
          <span className="ed-date-label">
            <CalendarDays />
            Start date
          </span>
          <span className="ed-date-value">{usDate(start)}</span>
          <input type="date" value={start} onChange={(e) => setStart(e.target.value)} aria-label="Start date" />
        </label>
        <label className="ed-date">
          <span className="ed-date-label">
            <CalendarDays />
            End date
          </span>
          <span className="ed-date-value">{usDate(end)}</span>
          <input type="date" value={end} onChange={(e) => setEnd(e.target.value)} aria-label="End date" />
        </label>
      </div>

      <AccountPicker
        label="Select account"
        accounts={acctList}
        value={account}
        onChange={setAccount}
        onAdd={() => setAddAccount(true)}
      />

      <ColorPicker
        primary={primary}
        accent={accent}
        onChange={(which, hex) => (which === 'accent' ? setAccent(hex) : setPrimary(hex))}
      />

      <button type="button" className="ed-submit" onClick={save}>
        <Save />
        {existing ? 'Update Goal' : 'Add goal'}
      </button>

      {addAccount ? (
        <AddMini
          title="Add account"
          placeholder="Account name"
          onSave={(n) => {
            setAcctList((l) => [...l, { id: `ac-${Date.now()}`, name: n, color: '#00897B', icon: 'bank' }]);
            setAccount(n);
          }}
          onClose={() => setAddAccount(false)}
        />
      ) : null}
    </div>
  );
}
