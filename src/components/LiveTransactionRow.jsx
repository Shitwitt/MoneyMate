import React from 'react';
import { ArrowLeftRight, ReceiptText } from 'lucide-react';

import { demoStore, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { linkChips } from '../data/derive.js';

export default function LiveTransactionRow({ tx, className = '', showDate = true }) {
  const state = useStore((s) => s);
  const base = state.profile.baseCurrency;
  const chips = tx.chips?.length ? tx.chips : linkChips(tx, state);
  const icon = tx.transfer ? <ArrowLeftRight /> : <ReceiptText />;
  const amountClass = tx.transfer ? 'blue' : tx.type === 'income' ? 'green' : 'red';
  const dateLabel = tx.when || new Date(`${tx.date}T00:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

  return (
    <button
      type="button"
      className={`live-tx-row ${className}`}
      onClick={() => demoStore.openTransactionEditor(tx.id)}
      aria-label={`Edit ${tx.title}`}
      data-live-row="true"
    >
      <span className="live-tx-icon" style={{ background: tx.icon?.bg || '#7B4028' }}>{icon}</span>
      <span className="live-tx-body">
        <strong>{tx.title}</strong>
        <small>
          {tx.time || ''}{tx.time && showDate ? ' · ' : ''}{showDate ? dateLabel : ''}
          {tx.transfer ? ` · ${tx.from} → ${tx.to}` : tx.account ? ` · ${tx.account}` : ''}
        </small>
        <span className="live-tx-chips">
          {chips.slice(0, 3).map((c, i) => (
            <em key={`${c.label}-${i}`} style={{ background: c.bg, color: c.fg }}>{c.label}</em>
          ))}
        </span>
      </span>
      <span className={`live-tx-amount ${amountClass}`}>
        <b>{fmtFull(tx.amount, tx.currency)}</b>
        {tx.converted ? <small>{fmtFull(tx.converted, base)} booked</small> : null}
      </span>
    </button>
  );
}
