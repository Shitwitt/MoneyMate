import React from 'react';
import { ChartNoAxesCombined, House, Plus, Search, Wallet } from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';

export default function FloatingNav() {
  const active = useStore((s) => s.nav.active);
  const go = (tab) => {
    if (tab === 'search') demoStore.openSearch();
    else demoStore.go(tab === 'home' ? 'home' : tab);
    demoStore.setNav(tab);
  };

  return (
    <nav className="floating-nav" aria-label="Primary">
      <button type="button" className={active === 'home' ? 'on' : ''} onClick={() => go('home')} aria-label="Home"><House /></button>
      <button type="button" className={active === 'accounts' ? 'on' : ''} onClick={() => go('accounts')} aria-label="Accounts"><Wallet /></button>
      <button type="button" className="fab" onClick={() => demoStore.openTransactionEditor()} aria-label="Add transaction"><Plus /></button>
      <button type="button" className={active === 'reports' ? 'on' : ''} onClick={() => go('reports')} aria-label="Reports"><ChartNoAxesCombined /></button>
      <button type="button" className={active === 'search' ? 'on' : ''} onClick={() => go('search')} aria-label="Search"><Search /></button>
    </nav>
  );
}
