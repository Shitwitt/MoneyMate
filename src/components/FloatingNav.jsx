import React from 'react';
import { ChartNoAxesCombined, House, Plus, Search, Wallet } from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { useT } from '../hooks/useT.js';

export default function FloatingNav() {
  const active = useStore((s) => s.nav.active);
  const t = useT();
  const go = (tab) => {
    if (tab === 'search') demoStore.openSearch();
    else demoStore.go(tab === 'home' ? 'home' : tab);
    demoStore.setNav(tab);
  };

  return (
    <nav className="floating-nav" aria-label="Primary">
      <button type="button" className={active === 'home' ? 'on' : ''} onClick={() => go('home')} aria-label={t('Home')} title={t('Home')}><House /></button>
      <button type="button" className={active === 'accounts' ? 'on' : ''} onClick={() => go('accounts')} aria-label={t('Accounts')} title={t('Accounts')}><Wallet /></button>
      <button type="button" className="fab" onClick={() => demoStore.openTransactionEditor()} aria-label={t('New')} title={t('New')}><Plus /></button>
      <button type="button" className={active === 'reports' ? 'on' : ''} onClick={() => go('reports')} aria-label={t('Reports')} title={t('Reports')}><ChartNoAxesCombined /></button>
      <button type="button" className={active === 'search' ? 'on' : ''} onClick={() => go('search')} aria-label={t('Search')} title={t('Search')}><Search /></button>
    </nav>
  );
}
