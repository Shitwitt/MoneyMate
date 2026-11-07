import React from 'react';
import { Bell, BellOff, Cloud, MessageSquareText, Star } from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';

export default function Greeting() {
  const name = useStore((s) => s.profile.name);
  const status = useStore((s) => s.status);
  const recurringCount = useStore((s) => s.recurring.length);
  const greeting = useStore((s) => s.greeting);

  return (
    <section className="greeting" aria-label="Greeting">
      <div className="greeting-line">
        <span>{greeting}</span>{' '}
        <button type="button" className="user-name" onClick={demoStore.openProfile} aria-label="Edit profile name">{name}</button>
        <span> !!!</span>
      </div>
      <p className="greeting-sub">
        <button type="button" className="link-button" onClick={demoStore.openProfile}>Personalize your profile</button>
        {' · '}
        <button type="button" className="link-button" onClick={() => { demoStore.setIn('status.backup', !status.backup); demoStore.toast(status.backup ? 'Backup paused' : 'Backup enabled'); }}>
          <Cloud /> Backup {status.backup ? 'Synced' : 'Ready'}
        </button>
      </p>

      <div className="quick-status" role="group" aria-label="Quick actions">
        <button type="button" className="chip-button" onClick={() => demoStore.openCollection('recurring')}>
          {recurringCount} recurring
        </button>
        <button type="button" className="chip-button" onClick={() => { const next = (Number(status.rating) % 5) + 1; demoStore.setIn('status.rating', next); demoStore.toast(`Rated ${next} stars`); }} aria-label="Rate app">
          <Star /> {Number(status.rating)}.0
        </button>
        <button
          type="button"
          className="chip-button"
          onClick={() => demoStore.setIn('status.notification', !status.notification)}
          aria-label="Toggle notifications"
        >
          {status.notification ? <Bell /> : <BellOff />} {status.notification ? 'On' : 'Off'}
        </button>
        <button type="button" className="chip-button" onClick={demoStore.openFeedback} aria-label="Feedback">
          <MessageSquareText />{status.feedback ? 'Saved' : ''}
        </button>
      </div>
    </section>
  );
}
