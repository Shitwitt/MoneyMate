import React from 'react';
import { X, LayoutGrid, UserRound, Moon, Sun } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';

export default function TopBar() {
  const privacy = useStore((s) => s.privacy);
  const theme = useStore((s) => s.theme);

  return (
    <header className="top-bar">
      <button type="button" className="exit-demo" onClick={() => demoStore.exitDemo()}>
        <X />
        Exit Demo
      </button>

      <div className="top-right">
        <span className="new-badge">New</span>
        <button
          type="button"
          className="theme-toggle"
          aria-label={theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme'}
          aria-pressed={theme === 'dark'}
          onClick={() => demoStore.toggleTheme()}
        >
          {theme === 'dark' ? <Sun /> : <Moon />}
        </button>
        <button
          type="button"
          className="icon-btn"
          aria-label="Customize dashboard layout"
          onClick={() => demoStore.toast('Dashboard layout — coming in Step 2')}
        >
          <LayoutGrid />
        </button>
        <button
          type="button"
          className="avatar-btn"
          aria-label={`Profile — ${privacy ? 'private' : 'public'} mode`}
          onClick={() => demoStore.toast('Profile menu')}
        >
          <UserRound />
        </button>
      </div>
    </header>
  );
}
