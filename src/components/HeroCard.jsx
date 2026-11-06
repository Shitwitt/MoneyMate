import React from 'react';
import { Eye, EyeOff, Info, ArrowUp } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore, fmtFull } from '../data/demoStore.js';

const MASK = '₹••••••';

export default function HeroCard() {
  const privacy = useStore((s) => s.privacy);
  const balance = useStore((s) => s.balance);
  const { total, income, expense } = balance;

  const amt = (v) => (privacy ? MASK : fmtFull(v));
  const compared = (v) =>
    privacy ? 'Compared to ₹•••••• last month' : `Compared to ${fmtFull(v)} last month`;

  return (
    <section className="hero-card" aria-label="Total balance">
      <div className="hero-label">Total balance</div>

      <div className="hero-top">
        <div className="hero-amount-row">
          <span className={`hero-amount${privacy ? ' masking' : ''}`}>{amt(total)}</span>
          <button
            type="button"
            className="hero-info"
            aria-label="Balance breakdown"
            onClick={() => demoStore.toast('Balance = accounts − liabilities')}
          >
            <Info />
          </button>
        </div>

        <button
          type="button"
          className="eye-btn"
          aria-label={privacy ? 'Show amounts' : 'Hide amounts (privacy mode)'}
          aria-pressed={privacy}
          onClick={() => demoStore.togglePrivacy()}
        >
          {privacy ? <Eye /> : <EyeOff />}
        </button>
      </div>

      <div className="hero-split">
        <div>
          <div className="hero-col-label">Income</div>
          <div className="hero-col-value">
            <span className="hero-value-num">{amt(income.now)}</span>
            <span className="hero-delta up-pos">
              <ArrowUp aria-hidden="true" />
              {income.deltaPct}%
            </span>
          </div>
          <div className="hero-col-sub">{compared(income.prev)}</div>
        </div>

        <div>
          <div className="hero-col-label">Expense</div>
          <div className="hero-col-value">
            <span className="hero-value-num">{amt(expense.now)}</span>
            <span className="hero-delta up-neg">
              <ArrowUp aria-hidden="true" />
              {expense.deltaPct}%
            </span>
          </div>
          <div className="hero-col-sub">{compared(expense.prev)}</div>
        </div>
      </div>
    </section>
  );
}
