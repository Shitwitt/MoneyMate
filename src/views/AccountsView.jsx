import React from 'react';
import {
  Landmark,
  Wallet,
  CreditCard,
  LayoutGrid,
  ArrowLeft,
  ArrowRight,
  ArrowUp,
  TrendingUp,
  PiggyBank,
  DollarSign,
  ChartLine,
} from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, usd } from '../data/demoStore.js';
import { accounts, accountTransactions } from '../data/step2Data.js';
import { SubHeader, ExitDemoPill } from '../components/step2/ui2.jsx';
import { useSwipe } from '../components/ui.jsx';

const ACCT_ICON = { bank: Landmark, wallet: Wallet, card: CreditCard };

/* small bank/wallet glyph used inline in transaction routes & chips */
function RouteIcon({ tone }) {
  if (tone === 'teal') return <Landmark className="route-ico teal" aria-hidden="true" />;
  if (tone === 'piggy') return <PiggyBank className="route-ico pink" aria-hidden="true" />;
  if (tone === 'chart') return <ChartLine className="route-ico red" aria-hidden="true" />;
  return <Wallet className="route-ico" aria-hidden="true" />;
}

function ChipIcon({ icon }) {
  if (icon === 'wallet') return <Wallet aria-hidden="true" />;
  if (icon === 'dollar') return <DollarSign aria-hidden="true" />;
  return null;
}

export default function AccountsView() {
  const slide = useStore((s) => s.accountsUi.slide);
  const acct = accounts[slide];

  const swipe = useSwipe({
    onLeft: () => demoStore.setAccountSlide(Math.min(accounts.length - 1, slide + 1)),
    onRight: () => demoStore.setAccountSlide(Math.max(0, slide - 1)),
  });

  const Icon = ACCT_ICON[acct.icon] || Landmark;

  return (
    <div className="view">
      <div className="view-header-wrap">
        <SubHeader
          title="Accounts"
          center={false}
          right={
            <>
              <ExitDemoPill />
              <button
                type="button"
                className="icon-btn"
                aria-label="Switch to carousel view"
                onClick={() => demoStore.toast('Card carousel view')}
              >
                <LayoutGrid />
              </button>
            </>
          }
        />
      </div>

      <div className="acct-carousel" {...swipe}>
        <div
          className="acct-card"
          style={{ background: acct.surface }}
          key={acct.id}
          role="group"
          aria-label={`${acct.name} account`}
        >
          <div className="acct-top">
            <div className="acct-id">
              <span className="acct-tile" style={{ background: acct.tile, color: acct.tileFg }}>
                <Icon />
              </span>
              <div>
                <div className="acct-name" style={{ color: acct.titleColor }}>
                  {acct.name}
                </div>
                <div className="acct-owner" style={{ color: acct.subColor }}>
                  {acct.owner}
                </div>
              </div>
            </div>
            <span className="acct-last4" style={{ background: acct.pillBg, color: acct.acctColor }}>
              {acct.last4}
            </span>
          </div>

          <div className="acct-bottom">
            <div>
              <div className="acct-bal-label" style={{ color: acct.subColor }}>
                Total balance
              </div>
              <div className="acct-balance" style={{ color: acct.amountColor }}>
                {usd(acct.balance)}
              </div>
            </div>
            <span className="acct-kind" style={{ background: acct.pillBg, color: acct.acctColor }}>
              {acct.kind}
            </span>
          </div>
        </div>
      </div>

      <div className="acct-dots" role="tablist" aria-label="Accounts">
        {accounts.map((a, i) => (
          <button
            key={a.id}
            type="button"
            className={`acct-dot${i === slide ? ' on' : ''}`}
            aria-label={a.name}
            aria-selected={i === slide}
            role="tab"
            onClick={() => demoStore.setAccountSlide(i)}
          />
        ))}
      </div>

      <div className="acct-split">
        <div>
          <div className="split-label">Income</div>
          <div className="split-value-row">
            <span className="split-value">{usd(acct.income.now)}</span>
            <span className="split-delta pos">
              <ArrowUp aria-hidden="true" />
              {acct.income.deltaPct.toFixed(2)}%
            </span>
          </div>
          <div className="split-sub">Compared to {usd(acct.income.prev)} last month</div>
        </div>

        <div>
          <div className="split-label">Expense</div>
          <div className="split-value-row">
            <span className="split-value">{usd(acct.expense.now)}</span>
            <span className="split-delta neg">
              <ArrowUp aria-hidden="true" />
              {acct.expense.deltaPct.toFixed(2)}%
            </span>
          </div>
          <div className="split-sub">Compared to {usd(acct.expense.prev)} last month</div>
        </div>
      </div>

      <h2 className="view-section-title">Transactions</h2>

      <div className="tx-list">
        {accountTransactions.map((t) => (
          <button
            type="button"
            className="tx s2"
            key={t.id}
            onClick={() => demoStore.toast(`${t.title} — transaction details`)}
          >
            <span
              className="tx-ico s2"
              style={{ background: t.kind === 'transfer' ? '#7D7470' : '#E91E63', color: '#fff' }}
            >
              {t.kind === 'transfer' ? (
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M4 8h13l-3-3" />
                  <path d="M20 16H7l3 3" />
                </svg>
              ) : (
                <BanknoteGlyph />
              )}
            </span>

            <span className="tx-mid">
              <span className="tx-title s2" style={{ display: 'block' }}>
                {t.title}
              </span>
              <span className="tx-meta s2">
                {t.time} • {t.when} •{' '}
                <span className="tx-route">
                  <RouteIcon tone={t.from.tone} />
                  {t.from.label}
                  {t.to ? (
                    <>
                      <ArrowRight className="route-arrow" aria-hidden="true" />
                      <RouteIcon tone={t.to.tone} />
                      {t.to.label}
                    </>
                  ) : null}
                </span>
              </span>
              {t.chips.length ? (
                <span className="chips s2">
                  {t.chips.map((c, i) => (
                    <span className="chip s2" key={`${t.id}-${i}`} style={{ background: c.bg, color: c.fg }}>
                      <ChipIcon icon={c.icon} />
                      {c.label}
                    </span>
                  ))}
                </span>
              ) : null}
            </span>

            <span
              className="tx-amt"
              style={{ color: t.kind === 'transfer' ? '#1E88E5' : '#D32F2F' }}
            >
              {usd(t.amount)}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}

function BanknoteGlyph() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="6" width="20" height="12" rx="2" />
      <circle cx="12" cy="12" r="2.6" />
      <path d="M6 10v.01M18 14v.01" />
    </svg>
  );
}

export { RouteIcon, ChipIcon, BanknoteGlyph };
