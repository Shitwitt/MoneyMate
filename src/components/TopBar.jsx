import React from 'react';
import { X, LayoutGrid, UserRound } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';

export default function TopBar() {
  const privacy = useStore((s) => s.privacy);

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
