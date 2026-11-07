import React from 'react';

import { SectionHead } from './ui.jsx';
import LiveTransactionRow from './LiveTransactionRow.jsx';
import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { upcomingTransactions } from '../data/derive.js';

export default function UpcomingTransactions() {
  const upcoming = useStore((s) => upcomingTransactions(s));
  return (
    <section className="upcoming-section" aria-label="Upcoming transactions">
      <SectionHead title="Upcoming transactions" action="See All" onAction={() => demoStore.openSearch('')} />
      <div className="live-tx-list upcoming-list">
        {upcoming.map((tx) => <LiveTransactionRow key={tx.id} tx={tx} />)}
        {upcoming.length === 0 ? (
          <button type="button" className="empty-note" onClick={() => demoStore.openTransactionEditor({ date: demoStore.getState().today })}>
            No upcoming transactions. Add a future-dated expense, income or transfer.
          </button>
        ) : null}
      </div>
    </section>
  );
}
