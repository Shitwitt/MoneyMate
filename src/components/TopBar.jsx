import React from 'react';
import { LayoutGrid, Moon, Plus, Sun } from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { useT } from '../hooks/useT.js';
import ProfileAvatar from './ProfileAvatar.jsx';

export default function TopBar() {
  const name = useStore((s) => s.profile.name);
  const theme = useStore((s) => s.theme);
  const t = useT();
  return (
    <header className="topbar" aria-label="MoneyMate toolbar">
      <button type="button" className="new-badge" onClick={() => demoStore.openTransactionEditor()} aria-label="Add transaction">
        <Plus /> {t('New')}
      </button>

      <div className="top-actions">
        <button type="button" className="top-icon" aria-label="Customize dashboard" onClick={demoStore.openLayout}>
          <LayoutGrid />
        </button>
        <button type="button" className="top-icon" aria-label="Toggle theme" onClick={demoStore.toggleTheme}>
          {theme === 'dark' ? <Sun /> : <Moon />}
        </button>
        <ProfileAvatar label={`${t('Profile')}: ${name}`} />
      </div>
    </header>
  );
}
