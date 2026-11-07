import React from 'react';
import {
  User,
  Trash2,
  Timer,
  CalendarDays,
  CheckCircle2,
  AlertTriangle,
  Wallet,
  PencilLine,
} from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { fmtMoney, loanState, toCents } from '../data/engine.js';
import { DarkHeader } from '../components/step3/ui3.jsx';

function PayDialog({ loan, st, onClose }) {
  const [value, setValue] = React.useState('');
  const remaining = st.remaining / 100;
  return (
    <div className="dlg-scrim" role="presentation" onClick={onClose}>
      <form
        className="dlg dark"
        onSubmit={(e) => {
          e.preventDefault();
          demoStore.recordLoanPayment(loan.id, Number(String(value).replace(/[^0-9.]/g, '')) || 0);
          onClose();
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <h3>Record payment</h3>
        <p className="dlg-sub">
          {loan.kind === 'lending' ? 'Received from' : 'Paid to'} {loan.person} · remaining{' '}
          {fmtMoney(st.remaining)}
        </p>
        <label className="dlg-field">
          Amount
          <input
            autoFocus
            value={value}
            inputMode="decimal"
            placeholder="0.00"
            aria-label="Payment amount"
            onChange={(e) => setValue(e.target.value)}
          />
        </label>
        <div className="dlg-quick">
          <button type="button" onClick={() => setValue(remaining.toFixed(2))}>
            Full remaining
          </button>
          <button type="button" onClick={() => setValue((remaining / 2).toFixed(2))}>
            Half
          </button>
        </div>
        <div className="dlg-actions">
          <button type="button" className="dlg-cancel" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="dlg-save">
            Record
          </button>
        </div>
      </form>
    </div>
  );
}

export default function LoanDetailsView() {
  const params = useStore((s) => s.route.params);
  const loans = useStore((s) => s.loans);
  const today = useStore((s) => s.today);
  const [paying, setPaying] = React.useState(false);

  const loan = loans.find((l) => l.id === params.id) || loans[0];
  if (!loan) return null;

  const st = loanState(loan, today);

  return (
    <div className="view dark-view loan-details">
      <DarkHeader
        title={loan.kind === 'lending' ? 'Lending' : 'Borrowing'}
        right={
          <button
            type="button"
            className="dark-icon-btn danger"
            aria-label="Delete loan"
            onClick={() => demoStore.deleteLoan(loan.id)}
          >
            <Trash2 />
          </button>
        }
      />

      <section className="loan-hero" style={{ background: loan.surface }}>
        <div className="lc-top">
          <span className="lc-tile" style={{ background: loan.accent, color: loan.tileFg }}>
            <User />
          </span>
          <span className="lc-mid">
            <span className="lc-name">{loan.title}</span>
            <span className="lc-sub" style={{ color: loan.textSoft }}>
              {loan.person} · {loan.account}
            </span>
          </span>
          {st.completed ? (
            <span className="lc-pill done">
              <CheckCircle2 />
              Completed
            </span>
          ) : st.overdue ? (
            <span className="lc-pill overdue">
              <AlertTriangle />
              Overdue {Math.abs(st.days)}d
            </span>
          ) : (
            <span className="lc-pill" style={{ background: loan.pillBg, color: loan.pillFg }}>
              <Timer />
              {st.days} days
            </span>
          )}
        </div>

        <div className="lh-amounts">
          <div>
            <div className="lc-label" style={{ color: loan.textSoft }}>
              Remaining
            </div>
            <div className="lh-big">{fmtMoney(st.remaining)}</div>
          </div>
          <div className="lh-right">
            <div className="lc-label" style={{ color: loan.textSoft }}>
              Paid / Total
            </div>
            <div className="lh-small">
              {fmtMoney(toCents(loan.paid))} / {fmtMoney(toCents(loan.total))}
            </div>
          </div>
        </div>

        <div className="lc-track lh-track" style={{ background: loan.track }}>
          <span style={{ width: `${Math.max(2, st.completion)}%`, background: loan.fill }} />
        </div>

        <div className="lc-bottom">
          <span className="lc-due" style={{ color: loan.textSoft }}>
            <CalendarDays />
            Due {new Date(loan.due).toLocaleDateString('en-US')}
          </span>
          <span className="lc-pct" style={{ color: loan.textSoft }}>
            {st.completion}% complete
          </span>
        </div>
      </section>

      <div className="lh-actions">
        <button type="button" className="lh-btn" onClick={() => setPaying(true)} disabled={st.completed}>
          <Wallet />
          Record payment
        </button>
        <button
          type="button"
          className="lh-btn ghost"
          onClick={() => demoStore.recordLoanPayment(loan.id, st.remaining / 100)}
          disabled={st.completed}
        >
          <CheckCircle2 />
          Mark fully paid
        </button>
      </div>

      <div className="lh-info">
        <div className="lh-info-row">
          <span>Outstanding</span>
          <b>{fmtMoney(st.remaining)}</b>
        </div>
        <div className="lh-info-row">
          <span>Completion</span>
          <b>{st.completion}%</b>
        </div>
        <div className="lh-info-row">
          <span>Due date</span>
          <b>{new Date(loan.due).toLocaleDateString('en-US')}</b>
        </div>
        <div className="lh-info-row">
          <span>{st.overdue ? 'Overdue by' : 'Days remaining'}</span>
          <b className={st.overdue ? 'danger' : undefined}>
            {Math.abs(st.days)} day{Math.abs(st.days) === 1 ? '' : 's'}
          </b>
        </div>
      </div>

      <button type="button" className="ext-fab" onClick={() => demoStore.go('loanEditor', { id: loan.id })}>
        <PencilLine />
        Edit
      </button>

      {paying ? <PayDialog loan={loan} st={st} onClose={() => setPaying(false)} /> : null}
    </div>
  );
}
