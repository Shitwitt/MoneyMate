import React from 'react';
import {
  PiggyBank,
  Calculator,
  TrendingUp,
  Wallet,
  Landmark,
  CreditCard,
  Store,
} from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore, fmtFull, inrGroup } from '../data/demoStore.js';
import { SectionHead } from './ui.jsx';

const MASK = '₹••••••';

const CURRENCY_META = {
  INR: { formatter: (v) => fmtFull(v) },
  // European convention as in the reference: 272,00 € (decimal comma)
  EUR: { formatter: (v) => `${inrGroup(v).replace('.', ',')} €` },
  GBP: { formatter: (v) => `£${inrGroup(v)}` },
};

const TX_ICON = {
  piggy: PiggyBank,
  calc: Calculator,
  arrow: TrendingUp,
  wallet: Wallet,
};

const ACCOUNT_ICON = {
  orange: Wallet,
  red: Store,
  blue: CreditCard,
};

const CHIP_ICON = {
  bank: Landmark,
  trend: TrendingUp,
};

export default function UpcomingTransactions() {
  const upcoming = useStore((s) => s.upcoming);
  const privacy = useStore((s) => s.privacy);

  return (
    <>
      <SectionHead
        title="Upcoming transactions"
        tone="sand"
        action="See All"
        onAction={() => demoStore.toast('All upcoming transactions')}
      />

      <div className="upcoming-list">
        {upcoming.map((tx) => {
          const Icon = TX_ICON[tx.icon] || Store;
          const AcctIcon = ACCOUNT_ICON[tx.accountTone] || Wallet;
          const meta = CURRENCY_META[tx.currency] || CURRENCY_META.INR;

          return (
            <button
              type="button"
              className="tx"
              key={tx.id}
              onClick={() => demoStore.toast(`${tx.title} — edit transaction`)}
            >
              <span className="tx-ico" style={{ background: tx.iconBg, color: tx.iconFg }}>
                <Icon />
              </span>

              <span className="tx-mid">
                <span className="tx-title" style={{ display: 'block' }}>
                  {tx.title}
                </span>
                <span className="tx-meta">
                  {tx.time}
                  <span className="dotsep">•</span>
                  {tx.when}
                  <span className="dotsep">•</span>
                  <span className="tx-acct">
                    <AcctIcon aria-hidden="true" />
                    {tx.account}
                  </span>
                </span>
                <span className="chips">
                  {tx.chips.map((c, i) => {
                    const CI = CHIP_ICON[c.icon];
                    return (
                      <span className="chip" key={`${tx.id}-chip-${i}`} style={{ background: c.bg, color: c.fg }}>
                        {CI ? <CI aria-hidden="true" /> : null}
                        {c.label}
                      </span>
                    );
                  })}
                </span>
              </span>

              <span className="tx-amt">
                <span className="a1" style={{ display: 'block' }}>
                  {privacy ? MASK : meta.formatter(tx.amount)}
                </span>
                {tx.converted != null ? (
                  <span className="a2" style={{ display: 'block' }}>
                    {privacy ? MASK : fmtFull(tx.converted)}
                  </span>
                ) : null}
              </span>
            </button>
          );
        })}
      </div>
    </>
  );
}
