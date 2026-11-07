import React from 'react';
import {
  ArrowLeftRight,
  Calculator,
  CreditCard,
  House,
  Landmark,
  PiggyBank,
  ReceiptText,
  Tag,
  TrendingUp,
  UserRound,
  Wallet,
} from 'lucide-react';

import { demoStore, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { linkChips } from '../data/derive.js';

const GLYPHS = {
  piggy: PiggyBank,
  calc: Calculator,
  trend: TrendingUp,
  wallet: Wallet,
  transfer: ArrowLeftRight,
};

const CHIP_ICONS = [
  { test: /budget/i, Icon: Wallet },
  { test: /home/i, Icon: House },
  { test: /personal/i, Icon: Landmark },
  { test: /work/i, Icon: TrendingUp },
  { test: /person|bob|alice|carol/i, Icon: UserRound },
  { test: /loan|fund/i, Icon: PiggyBank },
  { test: /category|label/i, Icon: Tag },
];

function chipIcon(label) {
  const hit = CHIP_ICONS.find(({ test }) => test.test(label));
  return hit ? hit.Icon : null;
}

export default function LiveTransactionRow({ tx, className = '', showDate = true }) {
  const state = useStore((s) => s);
  const base = state.profile.baseCurrency;
  const chips = tx.chips?.length ? tx.chips : linkChips(tx, state);
  const Glyph = tx.transfer ? ArrowLeftRight : (GLYPHS[tx.icon?.glyph] || ReceiptText);
  const amountClass = tx.transfer ? 'blue' : tx.type === 'income' ? 'green' : 'red';
  const dateLabel = tx.when || new Date(`${tx.date}T00:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  const account = tx.transfer ? `${tx.from} → ${tx.to}` : tx.account;

  return (
    <button
      type="button"
      className={`live-tx-row ${className}`}
      onClick={() => demoStore.openTransactionEditor(tx.id)}
      aria-label={`Edit ${tx.title}`}
      data-live-row="true"
    >
      <span className="live-tx-icon" style={{ background: tx.icon?.bg || '#7B4028', color: tx.icon?.fg || '#fff' }}>
        <Glyph />
      </span>
      <span className="live-tx-body">
        <strong>{tx.title}</strong>
        <small>
          {tx.time || ''}{tx.time && showDate ? ' · ' : ''}{showDate ? dateLabel : ''}
          {account ? <> · <CreditCard /> {account}</> : null}
        </small>
        <span className="live-tx-chips">
          {chips.slice(0, 4).map((c, i) => {
            const ChipIcon = chipIcon(c.label);
            return <em key={`${c.label}-${i}`} style={{ background: c.bg, color: c.fg }}>{ChipIcon ? <ChipIcon /> : null}{c.label}</em>;
          })}
        </span>
      </span>
      <span className={`live-tx-amount ${amountClass}`}>
        <b>{fmtFull(tx.amount, tx.currency)}</b>
        {tx.converted ? <small>{fmtFull(tx.converted, base)}</small> : null}
      </span>
    </button>
  );
}
