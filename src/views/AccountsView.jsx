import React from 'react';
import { ArrowUp, CreditCard, Landmark, LayoutGrid, Plus, Wallet } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, fmtFull, fmtCompact, maskFor } from '../data/demoStore.js';
import { accountBalances, monthlyTotals } from '../data/derive.js';
import { SubHeader } from '../components/step2/ui2.jsx';
import { Dots, SectionHead, useSwipe } from '../components/ui.jsx';
import LiveTransactionRow from '../components/LiveTransactionRow.jsx';

const ACCT_ICON = { bank: Landmark, wallet: Wallet, card: CreditCard };

function prevMonthKey(today) {
  const d = new Date(`${today.slice(0, 7)}-01T00:00:00Z`);
  d.setUTCMonth(d.getUTCMonth() - 1);
  return d.toISOString().slice(0, 7);
}
const deltaPct = (now, prev) => (prev ? Math.round(((now - prev) / prev) * 100) : now ? 100 : 0);

export default function AccountsView() {
  const state = useStore((s) => s);
  const accounts = accountBalances(state);
  const slide = Math.min(state.accountsUi.slide, Math.max(0, accounts.length - 1));
  const base = state.profile.baseCurrency;
  const mask = maskFor(base);
  const swipe = useSwipe({
    onLeft: () => demoStore.setAccountSlide(Math.min(accounts.length - 1, slide + 1)),
    onRight: () => demoStore.setAccountSlide(Math.max(0, slide - 1)),
  });

  if (!accounts.length) {
    return (
      <div className="view">
        <SubHeader title="Accounts" right={<button type="button" className="chip-button" onClick={() => demoStore.openAccountEditor()}><Plus /> Add account</button>} />
        <button type="button" className="live-card empty-note" onClick={() => demoStore.openAccountEditor()}>No accounts yet — tap to add one.</button>
      </div>
    );
  }

  const acct = accounts[slide];
  const Icon = ACCT_ICON[acct.icon] || Landmark;
  const related = state.transactions
    .filter((t) => t.account === acct.name || t.from === acct.name || t.to === acct.name)
    .sort((a, b) => (a.date < b.date ? 1 : -1));
  const filteredState = { ...state, transactions: related };
  const now = monthlyTotals(filteredState, state.today.slice(0, 7));
  const prev = monthlyTotals(filteredState, prevMonthKey(state.today));
  const income = { now: now.income, prev: prev.income, deltaPct: deltaPct(now.income, prev.income) };
  const expense = { now: now.expense, prev: prev.expense, deltaPct: deltaPct(now.expense, prev.expense) };
  const pillBg = `${acct.color}22`;

  return (
    <div className="view">
      <div className="view-header-wrap">
        <SubHeader
          title="Accounts"
          right={
            <>
              <button type="button" className="chip-button" onClick={() => demoStore.openAccountEditor()}><Plus /> Add account</button>
              <button type="button" className="icon-btn" aria-label="Customize dashboard" onClick={demoStore.openLayout}><LayoutGrid /></button>
            </>
          }
        />
      </div>

      <div className="acct-carousel" {...swipe}>
        <button
          type="button"
          className="acct-card"
          style={{ background: acct.surface || '#F3E1D7', border: 0, width: '100%', textAlign: 'left' }}
          key={acct.id}
          onClick={() => demoStore.openAccountEditor(acct.id)}
          aria-label={`Edit ${acct.name}`}
        >
          <div className="acct-top">
            <div className="acct-id">
              <span className="acct-tile" style={{ background: acct.color, color: '#fff' }}><Icon /></span>
              <div>
                <div className="acct-name" style={{ color: '#2C1D17' }}>{acct.name}</div>
                <div className="acct-owner" style={{ color: '#6E5A51' }}>{acct.holder}</div>
              </div>
            </div>
            <span className="acct-last4" style={{ background: pillBg, color: acct.color }}>{acct.last4 || '—'}</span>
          </div>
          <div className="acct-bottom">
            <div>
              <div className="acct-bal-label" style={{ color: '#6E5A51' }}>Total balance</div>
              <div className="acct-balance" style={{ color: '#2C1D17' }}>{state.privacy ? mask : fmtFull(acct.balance, base)}</div>
            </div>
            <span className="acct-kind" style={{ background: pillBg, color: acct.color }}>{acct.type}</span>
          </div>
        </button>
      </div>

      <div className="acct-dots" role="tablist" aria-label="Accounts">
        {accounts.map((a, i) => (
          <button key={a.id} type="button" className={`acct-dot${i === slide ? ' on' : ''}`} aria-label={a.name} aria-selected={i === slide} role="tab" onClick={() => demoStore.setAccountSlide(i)} />
        ))}
      </div>
      <Dots count={accounts.length} active={slide} className="acct-dots-soft" />

      <div className="acct-split">
        <div>
          <div className="split-label">Income</div>
          <div className="split-value-row"><span className="split-value">{state.privacy ? mask : fmtCompact(income.now, base)}</span><span className="split-delta pos"><ArrowUp />{income.deltaPct.toFixed(2)}%</span></div>
          <div className="split-sub">Compared to {state.privacy ? mask : fmtFull(income.prev, base)} last month</div>
        </div>
        <div>
          <div className="split-label">Expense</div>
          <div className="split-value-row"><span className="split-value">{state.privacy ? mask : fmtCompact(expense.now, base)}</span><span className="split-delta neg"><ArrowUp />{expense.deltaPct.toFixed(2)}%</span></div>
          <div className="split-sub">Compared to {state.privacy ? mask : fmtFull(expense.prev, base)} last month</div>
        </div>
      </div>

      <SectionHead title="Transactions" action="See all" onAction={() => demoStore.openSearch(acct.name)} />
      <div className="upcoming-actions">
        <button type="button" className="chip-button" onClick={() => demoStore.openTransactionEditor({ account: acct.name })}><Plus /> Add transaction</button>
      </div>
      <div className="live-tx-list">
        {related.slice(0, 14).map((t) => <LiveTransactionRow key={t.id} tx={t} />)}
        {related.length === 0 ? <p className="empty-note">No transactions linked to this account yet.</p> : null}
      </div>
    </div>
  );
}
