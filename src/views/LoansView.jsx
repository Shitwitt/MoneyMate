import React from 'react';
import { Plus, User, Timer, CalendarDays, ListFilter, CheckCircle2, AlertTriangle } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { fmtMoney, loanMath, loanSummaryFromLedger, toCents, daysUntil } from '../data/engine.js';
import { DarkHeader, PageBadge, InfoButton, SegmentedBar } from '../components/step3/ui3.jsx';

const TABS = [
  { id: 'lending', label: 'Lending' },
  { id: 'borrowing', label: 'Borrowing' },
  { id: 'completed', label: 'Completed' },
];

export default function LoansView() {
  const loans = useStore((s) => s.loans);
  const transactions = useStore((s) => s.transactions);
  const tab = useStore((s) => s.loansUi.tab);
  const sort = useStore((s) => s.loansUi.sort);
  const today = useStore((s) => s.today);

  const summary = loanSummaryFromLedger(loans, transactions, today);

  // every card is derived from the linked ledger, so the list and the
  // details screen can never disagree
  const withMath = loans.map((l) => {
    const m = loanMath(l, transactions);
    return {
      ...l,
      paid: m.paid / 100,
      total: m.total / 100,
      amount: m.principal / 100,
      remaining: m.remaining,
      completion: m.completion,
      days: daysUntil(l.end, today),
      completed: (l.status || 'active') === 'completed' || m.remaining === 0,
      subtitle: `${l.kind === 'lending' ? 'Lent to' : 'Borrowed from'} ${l.person}`,
    };
  });

  const filtered = withMath.filter((l) => {
    if (tab === 'completed') return l.completed;
    if (l.completed) return false;
    return l.kind === tab;
  });

  const sorted = [...filtered].sort((a, b) =>
    sort === 'name' ? a.title.localeCompare(b.title) : toCents(b.total) - toCents(a.total),
  );

  return (
    <div className="view dark-view loans-view">
      <DarkHeader title="Loans" right={<PageBadge>{loans.length}/{loans.length}</PageBadge>} />

      {/* summary */}
      <section className="loan-summary">
        <div className="ls-split">
          <div className="ls-col">
            <span className="ls-label">Lending</span>
            <span className="ls-value lending">{fmtMoney(summary.lending)}</span>
          </div>
          <div className="ls-divider" />
          <div className="ls-col">
            <span className="ls-label">Borrowing</span>
            <span className="ls-value borrowing">{fmtMoney(summary.borrowing)}</span>
          </div>
        </div>
        <div className="ls-hr" />
        <div className="ls-net">
          <div>
            <div className="ls-net-title">Net Loan Balance</div>
            <div className="ls-net-note">{summary.note}</div>
          </div>
          <span className="ls-net-value">{fmtMoney(summary.net)}</span>
        </div>
      </section>

      <div className="dark-subhead">
        <span className="dark-count">
          {sorted.length} loan{sorted.length === 1 ? '' : 's'}
        </span>
        <div className="dark-actions">
          <button
            type="button"
            className="dark-icon-btn"
            aria-label={`Sort by ${sort === 'name' ? 'amount' : 'name'}`}
            onClick={() => demoStore.toggleLoanSort()}
          >
            <ListFilter />
          </button>
          <InfoButton label="How loans work" onClick={() => demoStore.openLoansHow(true)} />
        </div>
      </div>

      {sorted.length === 0 ? <p className="dark-empty">No {tab} loans.</p> : null}

      <div className="loan-list">
        {sorted.map((l) => {
          const st = {
            days: l.days,
            completion: l.completion,
            completed: l.completed,
            overdue: !l.completed && l.days < 0,
          };
          return (
            <button
              type="button"
              className="loan-card"
              key={l.id}
              style={{ background: l.surface || '#272233' }}
              onClick={() => demoStore.go('loanDetails', { id: l.id })}
            >
              <div className="lc-top">
                <span className="lc-tile" style={{ background: l.accent, color: '#FFFFFF' }}>
                  <User />
                </span>
                <span className="lc-mid">
                  <span className="lc-name">{l.title}</span>
                  <span className="lc-sub" style={{ color: l.textSoft || '#B3A09A' }}>
                    {l.subtitle}
                  </span>
                </span>
                {st.overdue ? (
                  <span className="lc-pill overdue">
                    <AlertTriangle />
                    {Math.abs(st.days)}d late
                  </span>
                ) : st.completed ? (
                  <span className="lc-pill done">
                    <CheckCircle2 />
                    Paid
                  </span>
                ) : (
                  <span className="lc-pill" style={{ background: l.pillBg || '#3A2B41', color: l.pillFg || '#BA68C8' }}>
                    <Timer />
                    {st.days} days
                  </span>
                )}
              </div>

              <div className="lc-split">
                <div>
                  <div className="lc-label" style={{ color: l.textSoft || '#B3A09A' }}>
                    Paid
                  </div>
                  <div className="lc-value">{fmtMoney(toCents(l.paid))}</div>
                </div>
                <span className="lc-vr" />
                <div>
                  <div className="lc-label" style={{ color: l.textSoft || '#B3A09A' }}>
                    Total
                  </div>
                  <div className="lc-value">{fmtMoney(toCents(l.total))}</div>
                </div>
              </div>

              <div className="lc-track" style={{ background: l.track || '#343559' }}>
                <span style={{ width: `${Math.max(2, st.completion)}%`, background: l.fill || l.accent }} />
              </div>

              <div className="lc-bottom">
                <span className="lc-due" style={{ color: l.textSoft || '#B3A09A' }}>
                  <CalendarDays />
                  Due{' '}
                  {new Date(`${l.end}T00:00:00`).toLocaleDateString('en-US', {
                    month: '2-digit',
                    day: '2-digit',
                    year: 'numeric',
                  })}
                </span>
                <span className="lc-pct" style={{ color: l.textSoft || '#B3A09A' }}>
                  {st.completion}%
                </span>
              </div>
            </button>
          );
        })}
      </div>

      <button type="button" className="dark-fab" aria-label="Add loan" onClick={() => demoStore.go('loanEditor', {})}>
        <Plus />
      </button>

      <div className="dark-bottom-bar">
        <SegmentedBar options={TABS} value={tab} onChange={demoStore.setLoansTab} three />
      </div>
    </div>
  );
}
