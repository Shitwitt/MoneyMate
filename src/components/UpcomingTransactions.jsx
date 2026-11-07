import React from 'react';
import { Plus } from 'lucide-react';

import { SectionHead } from './ui.jsx';
import LiveTransactionRow from './LiveTransactionRow.jsx';
import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { upcomingTransactions } from '../data/derive.js';

export default function UpcomingTransactions() {
  const upcoming = useStore((s) => upcomingTransactions(s));
  return (
    <section className="upcoming-section" aria-label="Upcoming transactions">
      <SectionHead title="Upcoming transactions" action="See all" onAction={() => demoStore.openSearch('')} />
      <div className="upcoming-actions">
        <button type="button" className="chip-button" onClick={() => demoStore.openTransactionEditor({ date: demoStore.getState().today })}>
          <Plus /> Add future transaction
        </button>
      </div>
      <div className="live-tx-list upcoming-list">
        {upcoming.map((tx) => <LiveTransactionRow key={tx.id} tx={tx} />)}
        {upcoming.length === 0 ? <p className="empty-note">No upcoming transactions. Add a future-dated expense, income or transfer.</p> : null}
      </div>
    </section>
  );
}
