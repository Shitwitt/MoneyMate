import React from 'react';
import { CreditCard, House, Plus, RefreshCw, Search } from 'lucide-react';

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
  const items = [
    { id: 'home', icon: House, label: t('Home') },
    { id: 'accounts', icon: CreditCard, label: t('Accounts') },
    { id: 'reports', icon: RefreshCw, label: t('Reports') },
    { id: 'search', icon: Search, label: t('Search') },
  ];

  return (
    <>
      <button type="button" className="floating-fab" onClick={() => demoStore.openTransactionEditor()} aria-label={t('New')} title={t('New')}>
        <Plus />
      </button>
      <nav className="floating-nav" aria-label="Primary">
        {items.map(({ id, icon: Icon, label }) => (
          <button key={id} type="button" className={active === id ? 'on' : ''} onClick={() => go(id)} aria-label={label}>
            <Icon /><span>{label}</span>
          </button>
        ))}
      </nav>
    </>
  );
}
