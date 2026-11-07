import React from 'react';
import { Plus, Home, CreditCard, ChartPie, Search } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';

const TABS = [
  { id: 'home', label: 'Home', Icon: Home },
  { id: 'accounts', label: 'Accounts', Icon: CreditCard },
  { id: 'reports', label: 'Reports', Icon: ChartPie },
  { id: 'search', label: 'Search', Icon: Search },
];

export default function FloatingNav() {
  const active = useStore((s) => s.nav.active);

  return (
    <div className="float-layer">
      <button
        type="button"
        className="fab"
        aria-label="Add transaction"
        onClick={() => demoStore.toast('Add transaction — coming in the next step')}
      >
        <Plus />
      </button>

      <nav className="bottom-nav" aria-label="Primary">
        {TABS.map(({ id, label, Icon }) => (
          <button
            type="button"
            key={id}
            className={`nav-item${active === id ? ' active' : ''}`}
            aria-current={active === id ? 'page' : undefined}
            onClick={() => {
              if (id === 'home') demoStore.go('home');
              else if (id === 'accounts') demoStore.go('accounts');
              else if (id === 'reports') demoStore.go('reports');
              else demoStore.toast('Search — built in a later step');
            }}
          >
            <Icon aria-hidden="true" />
            {label}
          </button>
        ))}
      </nav>
    </div>
  );
}
