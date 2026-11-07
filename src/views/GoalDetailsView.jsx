import React from 'react';
import { Trash2, Archive, ArchiveRestore, CalendarDays, Hourglass, Wallet, Pencil, Plus, UserRound } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { fmtMoney, toCents, goalDaysLeft, remainingLabel } from '../data/engine.js';
import { WavyBar, Glyph, TxRow } from '../components/step4/ui4.jsx';

const PERIODS = [
  { id: 'daily', label: 'Daily' },
  { id: 'weekly', label: 'Weekly' },
  { id: 'monthly', label: 'Monthly' },
  { id: 'yearly', label: 'Yearly' },
];

function usDate(iso) {
  if (!iso) return '—';
  return new Date(`${iso}T00:00:00`).toLocaleDateString('en-US', {
    month: '2-digit',
    day: '2-digit',
    year: 'numeric',
  });
}

/** Group rows by day / week / month / year, newest first. */
export function groupBy(rows, period) {
  const keyOf = (iso) => {
    const d = new Date(`${iso}T00:00:00`);
    if (period === 'yearly') return String(d.getFullYear());
    if (period === 'monthly') return `${d.getFullYear()}-${d.getMonth()}`;
    if (period === 'weekly') {
      const start = new Date(d);
      const day = (start.getDay() + 6) % 7;
      start.setDate(start.getDate() - day);
      return start.toISOString().slice(0, 10);
    }
    return iso.slice(0, 10);
  };

  const labelOf = (key, sample) => {
    const d = new Date(`${sample}T00:00:00`);
    if (period === 'yearly') return String(d.getFullYear());
    if (period === 'monthly') return d.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    if (period === 'weekly') {
      const s = new Date(`${key}T00:00:00`);
      const e = new Date(s);
      e.setDate(s.getDate() + 6);
      const f = (x) => x.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      return `${f(s)} – ${f(e)}`;
    }
    // "Sat, Dec 19" — weekday shortened, then a comma before the month
    const wd = d.toLocaleDateString('en-US', { weekday: 'short' });
    const md = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    return `${wd}, ${md}`;
  };

  const map = new Map();
  [...rows]
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

function ContributionSheet({ goal, onSave, onClose }) {
  const [amount, setAmount] = React.useState('');
  const [type, setType] = React.useState('income');
  const [date, setDate] = React.useState(new Date().toISOString().slice(0, 10));

  return (
    <div className="dlg-scrim" role="presentation" onClick={onClose}>
      <form
        className="dlg dark"
        onClick={(e) => e.stopPropagation()}
        onSubmit={(e) => {
          e.preventDefault();
          const value = Number(amount.replace(/[^0-9.]/g, '')) || 0;
          if (value > 0) onSave({ amount: value, type, date });
          onClose();
        }}
      >
        <h3>{type === 'income' ? 'Add contribution' : 'Withdraw funds'}</h3>
        <p className="dlg-sub">{goal.title}</p>

        <div className="dlg-toggle" role="group" aria-label="Direction">
          <button
            type="button"
            className={type === 'income' ? 'on' : ''}
            onClick={() => setType('income')}
          >
            Deposit
          </button>
          <button
            type="button"
            className={type === 'expense' ? 'on' : ''}
            onClick={() => setType('expense')}
          >
            Withdraw
          </button>
        </div>

        <label className="dlg-field">
          Amount
          <input
            autoFocus
            value={amount}
            inputMode="decimal"
            placeholder="0.00"
            aria-label="Contribution amount"
            onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ''))}
          />
        </label>

        <label className="dlg-field">
          Date
          <input type="date" value={date} aria-label="Date" onChange={(e) => setDate(e.target.value)} />
        </label>

        <div className="dlg-actions">
          <button type="button" className="dlg-cancel" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="dlg-save">
            Save
          </button>
        </div>
      </form>
    </div>
  );
}

export default function GoalDetailsView() {
  const params = useStore((s) => s.route.params);
  const goals = useStore((s) => s.goals);
  const transactions = useStore((s) => s.transactions);
  const period = useStore((s) => s.goalsUi.detailsTab);
  const today = useStore((s) => s.today);
  const [contribOpen, setContribOpen] = React.useState(false);

  const goal = goals.find((g) => g.id === params.id) || goals[0];
  if (!goal) return null;

  const linked = transactions.filter((t) => t.goalId === goal.id);
  const saved = linked
    .filter((t) => !t.transfer)
    .reduce((a, t) => a + (t.type === 'income' ? toCents(t.amount) : -toCents(t.amount)), 0);
  const target = toCents(goal.target);
  const remaining = Math.max(0, target - saved);
  const progress = target <= 0 ? 0 : Math.round((saved / target) * 100);
  const days = goalDaysLeft(goal.end, today);

  const groups = groupBy(linked, period);
  const archived = (goal.status || 'active') === 'archived';

  return (
    <div className="view dark-view goal-details s4">
      <header className="dark-header">
        <button type="button" className="dark-back" aria-label="Back" onClick={() => demoStore.back()}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <path d="M19 12H5m6-7-7 7 7 7" />
          </svg>
        </button>
        <h1 className="dark-title">Goal Details</h1>
        <div className="dark-right">
          <button type="button" className="dark-icon-btn" aria-label="Add savings / deposit" onClick={() => demoStore.openGoalDeposit(goal.id)}><Plus /></button>
          <button type="button" className="dark-profile-btn" aria-label="Profile" onClick={() => demoStore.openProfile()}><UserRound /></button>
          <button
            type="button"
            className="dark-icon-btn danger"
            aria-label="Delete goal"
            onClick={() => demoStore.deleteGoal(goal.id)}
          >
            <Trash2 />
          </button>
          <button
            type="button"
            className="dark-icon-btn"
            aria-label={archived ? 'Unarchive goal' : 'Archive goal'}
            onClick={() => demoStore.setGoalStatus(goal.id, archived ? 'active' : 'archived')}
          >
            {archived ? <ArchiveRestore /> : <Archive />}
          </button>
        </div>
      </header>

      {/* ---------- hero ---------- */}
      <section className="gd-hero" style={{ borderColor: `${goal.tile}66` }}>
        <div className="gd-hero-head">
          <span className="gd-tile" style={{ background: goal.tile }}>
            <Glyph name="bank" />
          </span>
          <div>
            <span className="gd-kicker">{goal.kind === 'income' ? 'Income Goal' : 'Expense Goal'}</span>
            <h2 style={{ color: goal.accent }}>{goal.title}</h2>
          </div>
        </div>

        <div className="gd-bar-row">
          <span className="gd-pct">{progress}% completed</span>
          <span className="gd-by">
            {fmtMoney(saved)} by {fmtMoney(target)}
          </span>
        </div>

        <WavyBar id={`gd-${goal.id}`} pct={progress} color={goal.bar} track={goal.track} />

        <div className="gd-grid">
          <div className="gd-cell">
            <span className="gd-cell-label">
              <CalendarDays />
              Started
            </span>
            <span className="gd-cell-value">{usDate(goal.start)}</span>
          </div>
          <div className="gd-cell">
            <span className="gd-cell-label">
              <CalendarDays />
              End date
            </span>
            <span className="gd-cell-value">{usDate(goal.end)}</span>
          </div>
          <div className="gd-cell">
            <span className="gd-cell-label">
              <Hourglass />
              Remaining
            </span>
            <span className="gd-cell-value">
              {days > 0 ? remainingLabel(goal.end, today) : 'Ended'}
            </span>
          </div>
          <div className="gd-cell">
            <span className="gd-cell-label">
              <Wallet />
              Still needed
            </span>
            <span className="gd-cell-value">{fmtMoney(remaining)}</span>
          </div>
        </div>
      </section>

      <h2 className="gd-tx-title">Transactions</h2>

      <div className="gd-groups">
        {groups.map((g) => (
          <section className="gd-group" key={g.key}>
            <header className="gd-group-head">
              <span>{g.label}</span>
              <span>{fmtMoney(g.total)}</span>
            </header>
            {g.items.map((tx) => (
              <TxRow key={tx.id} tx={tx} todayISO={today} />
            ))}
          </section>
        ))}
        {groups.length === 0 ? <p className="gl-empty">No transactions yet.</p> : null}
      </div>

      <button
        type="button"
        className="ext-fab"
        onClick={() => demoStore.go('goalEditor', { id: goal.id })}
      >
        <Pencil />
        Edit
      </button>

      <button
        type="button"
        className="gd-contrib"
        aria-label="Add contribution"
        onClick={() => setContribOpen(true)}
      >
        <Plus />
      </button>

      <div className="gtabs-wrap">
        <div className="gtabs" role="tablist">
          {PERIODS.map((p) => (
            <button
              key={p.id}
              type="button"
              role="tab"
              aria-selected={period === p.id}
              className={`gtab${period === p.id ? ' on' : ''}`}
              onClick={() => demoStore.setGoalDetailsTab(p.id)}
            >
              {p.label}
            </button>
          ))}
        </div>
      </div>

      {contribOpen ? (
        <ContributionSheet
          goal={goal}
          onSave={(payload) => demoStore.addGoalTransaction(goal.id, payload)}
          onClose={() => setContribOpen(false)}
        />
      ) : null}
    </div>
  );
}
