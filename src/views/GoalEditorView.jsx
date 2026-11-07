import React from 'react';
import { Camera, CalendarDays, Wallet, Save } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { DarkHeader } from '../components/step3/ui3.jsx';
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
  const accounts = useStore((s) => s.accounts);
  const today = useStore((s) => s.today);
  const existing = goals.find((g) => g.id === params.id);
  const acctList = accounts;

  const [name, setName] = React.useState(existing?.title || '');
  const [amount, setAmount] = React.useState(existing ? oneDecimal(existing.target) : '');
  const [start, setStart] = React.useState(existing?.start || today);
  const [end, setEnd] = React.useState(existing?.end || new Date(Date.parse(today) + 60 * 86400000).toISOString().slice(0, 10));
  const [account, setAccount] = React.useState(existing?.account || accounts[0]?.name || '');
  const [primary, setPrimary] = React.useState(existing?.color || '#F44336');
  const [accent, setAccent] = React.useState(existing?.accent || '#FF9C27');
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
<DarkHeader title="Goal" />

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
            const st = demoStore.getState();
            demoStore.saveAccount({ name: n, balance: 0, holder: st.profile.name, last4: '0000', type: 'Bank', color: '#00897B', currency: st.profile.baseCurrency });
            setAccount(n);
          }}
          onClose={() => setAddAccount(false)}
        />
      ) : null}
    </div>
  );
}
