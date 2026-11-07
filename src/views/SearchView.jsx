import React, { useEffect, useState } from 'react';
import { Plus, Search } from 'lucide-react';

import { SubHeader } from '../components/step2/ui2.jsx';
import LiveTransactionRow from '../components/LiveTransactionRow.jsx';
import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { searchTransactions } from '../data/derive.js';

export default function SearchView() {
  const routeQuery = useStore((s) => s.route.params?.query || '');
  const [query, setQuery] = useState(routeQuery);
  const results = useStore((s) => searchTransactions(s, routeQuery));

  useEffect(() => setQuery(routeQuery), [routeQuery]);
  const change = (value) => {
    setQuery(value);
    demoStore.setSearchQuery(value);
  };

  return (
    <div className="search-view">
      <SubHeader title="Transactions" />
      <div className="search-box">
        <Search />
        <input value={query} onChange={(e) => change(e.target.value)} placeholder="Search title, account, category, label…" aria-label="Search transactions" />
        {query ? <button type="button" onClick={() => change('')} aria-label="Clear search">Clear</button> : null}
      </div>
      <div className="search-summary">
        <span>{results.length} live results</span>
        <button type="button" className="btn primary small" onClick={() => demoStore.openTransactionEditor()}><Plus /> Add transaction</button>
      </div>
      <div className="live-tx-list">
        {results.map((tx) => <LiveTransactionRow key={tx.id} tx={tx} />)}
        {results.length === 0 ? <p className="empty-note">No transactions match “{query}”. Add one or clear the filter.</p> : null}
      </div>
    </div>
  );
}
