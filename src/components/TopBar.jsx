import React from 'react';
import { LayoutGrid, Plus, Wallet } from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { useT } from '../hooks/useT.js';
import ProfileAvatar from './ProfileAvatar.jsx';

export default function TopBar() {
  const name = useStore((s) => s.profile.name);
  const t = useT();
  return (
    <header className="topbar" aria-label="MoneyMate toolbar">
      <div className="topbar-spacer" aria-hidden="true" />
      <div className="topbar-center">
        <div className="topbar-brand" aria-label="Paisa">
          <Wallet /> <span>Paisa</span>
        </div>
        <button type="button" className="new-badge" onClick={() => demoStore.openTransactionEditor()} aria-label={t('New')}>
          <Plus /> {t('New')}
        </button>
      </div>
      <div className="top-actions">
        <button type="button" className="top-icon" aria-label="Customize dashboard" onClick={demoStore.openLayout}>
          <LayoutGrid />
        </button>
        <ProfileAvatar label={`${t('Profile')}: ${name}`} />
      </div>
    </header>
  );
}
