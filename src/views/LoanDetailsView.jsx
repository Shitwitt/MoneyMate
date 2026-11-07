import React from 'react';
import {
  ArrowUpRight,
  Clock,
  Trash2,
  Plus,
  UserRound,
  CalendarDays,
  Hourglass,
  FileText,
  Check,
  Pencil,
} from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { fmtMoney, toCents, daysUntil, chargeCents } from '../data/engine.js';
import { TxRow, AddMini } from '../components/step4/ui4.jsx';

function dateLabel(iso) {
  if (!iso) return '—';
  return new Date(`${iso}T00:00:00`).toLocaleDateString('en-US', {
    month: '2-digit',
    day: '2-digit',
    year: 'numeric',
  });
}

/** Quick-log sheet opened by the `+` in the app bar. */
function QuickLog({ loan, remaining, onClose }) {
  const [value, setValue] = React.useState('');
  const [account, setAccount] = React.useState(loan.account);
  const quick = remaining / 100;

  return (
    <div className="dlg-scrim" role="presentation" onClick={onClose}>
      <form
        className="dlg dark"
        onClick={(e) => e.stopPropagation()}
        onSubmit={(e) => {
          e.preventDefault();
          const amt = Number(String(value).replace(/[^0-9.]/g, '')) || 0;
          demoStore.recordLoanPayment(loan.id, amt, { account });
          onClose();
        }}
      >
        <h3>Log transaction</h3>
        <p className="dlg-sub">
          {loan.kind === 'lending' ? 'Received from' : 'Paid to'} {loan.person} · outstanding{' '}
          {fmtMoney(remaining)}
        </p>
        <label className="dlg-field">
          Amount
          <input
            autoFocus
            value={value}
            inputMode="decimal"
            placeholder="0.00"
            aria-label="Transaction amount"
            onChange={(e) => setValue(e.target.value.replace(/[^0-9.]/g, ''))}
          />
        </label>
        <label className="dlg-field">
          Account
          <select value={account} onChange={(e) => setAccount(e.target.value)} aria-label="Account">
            {[loan.account, 'Kotak Mahindra Bank', 'HDFC Bank', 'Cash Wallet', 'Savings Account'].map(
              (a) => (
                <option key={a} value={a}>
                  {a}
                </option>
              ),
            )}
          </select>
        </label>
        <div className="dlg-quick">
          <button type="button" onClick={() => setValue(quick ? quick.toFixed(2) : '')}>
            Full remaining
          </button>
          <button type="button" onClick={() => setValue((quick / 2).toFixed(2))}>
            Half
          </button>
        </div>
        <div className="dlg-actions">
          <button type="button" className="dlg-cancel" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="dlg-save">
            Log
          </button>
        </div>
      </form>
    </div>
  );
}

export default function LoanDetailsView() {
  const params = useStore((s) => s.route.params);
  const loans = useStore((s) => s.loans);
  const transactions = useStore((s) => s.transactions);
  const today = useStore((s) => s.today);
  const quickOpen = useStore((s) => s.loansUi.quickAdd);
  const [personModal, setPersonModal] = React.useState(false);

  const loan = loans.find((l) => l.id === params.id) || loans[0];
  if (!loan) return null;

  const linked = transactions.filter((t) => t.loanId === loan.id);
  const principal = toCents(loan.amount);
  const charges = linked
    .filter((t) => t.type === 'expense' && !t.transfer)
    .reduce((a, t) => a + toCents(chargeCents(t)), 0);
  const paid = linked
    .filter((t) => t.type === 'income' && !t.transfer)
    .reduce((a, t) => a + toCents(t.amount), 0);
  const total = principal + charges;
  const remaining = Math.max(0, total - paid);
  const completion = total <= 0 ? 0 : Math.min(100, Math.round((paid / total) * 100));
  const daysLeft = daysUntil(loan.end, today);

  const history = [...linked].sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0));

  return (
    <div className="view dark-view loan-details s4">
      <header className="dark-header">
        <button type="button" className="dark-back" aria-label="Back" onClick={() => demoStore.back()}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <path d="M19 12H5m6-7-7 7 7 7" />
          </svg>
        </button>
        <div className="dark-right">
          <button type="button" className="dark-profile-btn" aria-label="Profile" onClick={() => demoStore.openProfile()}><UserRound /></button>
          <button
            type="button"
            className="dark-icon-btn"
            aria-label="Log transaction"
            onClick={() => demoStore.openQuickLog(true)}
          >
            <Plus />
          </button>
          <button
            type="button"
            className="dark-icon-btn danger"
            aria-label="Delete loan"
            onClick={() => demoStore.deleteLoan(loan.id)}
          >
            <Trash2 />
          </button>
        </div>
      </header>

      <h1 className="ld-title">{loan.title}</h1>

      <div className="ld-pills">
        <span className={`ld-pill kind ${loan.kind}`}>
          <ArrowUpRight />
          {loan.kind === 'lending' ? 'Lending' : 'Borrowing'}
        </span>
        <span className="ld-pill days">
          <Clock />
          {daysLeft > 0 ? `${daysLeft} days left` : daysLeft === 0 ? 'Due today' : `${Math.abs(daysLeft)} days over`}
        </span>
      </div>

      <p className="ld-lent-label">Amount Lent</p>
      <p className="ld-lent">{fmtMoney(remaining)}</p>

      {/* ---------- repayment progress ---------- */}
      <section className="ld-progress">
        <h2 className="ld-progress-title">Repayment Progress</h2>
        <div className="ld-track" role="progressbar" aria-valuenow={completion} aria-valuemin={0} aria-valuemax={100}>
          <span style={{ width: `${Math.max(completion, 0.6)}%` }} />
        </div>
        <div className="ld-cols">
          <div>
            <span className="ld-col-label">Paid</span>
            <span className="ld-col-value">{fmtMoney(paid)}</span>
          </div>
          <div>
            <span className="ld-col-label">Amount</span>
            <span className="ld-col-value coral">{fmtMoney(principal)}</span>
          </div>
          <div>
            <span className="ld-col-label">Total</span>
            <span className="ld-col-value">{fmtMoney(total)}</span>
          </div>
        </div>
      </section>

      {/* ---------- loan details ---------- */}
      <h2 className="ld-section-title">Loan Details</h2>
      <section className="ld-details">
        <button
          type="button"
          className="ld-row"
          onClick={() => setPersonModal(true)}
          aria-label={loan.kind === 'lending' ? 'Lent to' : 'Borrowed from'}
        >
          <span className="ld-row-ico">
            <UserRound />
          </span>
          <span className="ld-row-mid">
            <span className="ld-row-label">{loan.kind === 'lending' ? 'Lent to' : 'Borrowed from'}</span>
            <span className="ld-row-value">{loan.person}</span>
          </span>
        </button>

        <div className="ld-row static">
          <span className="ld-row-ico">
            <CalendarDays />
          </span>
          <span className="ld-row-mid">
            <span className="ld-row-label">Start date</span>
            <span className="ld-row-value">{dateLabel(loan.start)}</span>
          </span>
        </div>

        <div className="ld-row static">
          <span className="ld-row-ico">
            <CalendarDays />
          </span>
          <span className="ld-row-mid">
            <span className="ld-row-label">End date</span>
            <span className="ld-row-value">{dateLabel(loan.end)}</span>
          </span>
        </div>

        <button
          type="button"
          className="ld-row"
          onClick={() => demoStore.go('loanEditor', { id: loan.id })}
          aria-label="Edit notes"
        >
          <span className="ld-row-ico">
            <FileText />
          </span>
          <span className="ld-row-mid">
            <span className="ld-row-label">Notes</span>
            <span className="ld-row-value">{loan.notes || 'Add a note'}</span>
          </span>
        </button>
      </section>

      <button
        type="button"
        className="ld-done"
        onClick={() => demoStore.markLoanDone(loan.id)}
        disabled={remaining === 0}
      >
        <Check />
        Mark as Done
      </button>

      {/* ---------- payment history ---------- */}
      <h2 className="ld-history-title">Payment History</h2>
      <div className="ld-history">
        {history.map((tx) => (
          <TxRow key={tx.id} tx={tx} todayISO={today} />
        ))}
        {history.length === 0 ? (
          <p className="ld-empty">
            <Hourglass />
            No payments yet — log one with the + above.
          </p>
        ) : null}
      </div>

      <button
        type="button"
        className="ext-fab"
        onClick={() => demoStore.go('loanEditor', { id: loan.id })}
      >
        <Pencil />
        Edit
      </button>

      {quickOpen ? (
        <QuickLog loan={loan} remaining={remaining} onClose={() => demoStore.openQuickLog(false)} />
      ) : null}
      {personModal ? (
        <AddMini
          title={loan.kind === 'lending' ? 'Lent to' : 'Borrowed from'}
          placeholder="Person name"
          onSave={(name) => demoStore.saveLoan({ ...loan, person: name })}
          onClose={() => setPersonModal(false)}
        />
      ) : null}
    </div>
  );
}
