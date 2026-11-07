import React from 'react';
import { Bell, BellOff, Cloud, Repeat2, Star } from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { useT } from '../hooks/useT.js';

export default function Greeting() {
  const name = useStore((s) => s.profile.name);
  const status = useStore((s) => s.status);
  const recurringCount = useStore((s) => s.recurring.length);
  const t = useT();

  return (
    <section className="greeting" aria-label="Greeting">
      <p className="greeting-copy">
        {t('Good late night')}{' '}
        <button type="button" className="greeting-user" onClick={demoStore.openProfile} aria-label="Edit profile name">{name}</button>.{' '}
        You have{' '}
        <button
          type="button"
          className="greeting-token"
          onClick={() => { demoStore.setIn('status.backup', !status.backup); demoStore.toast(status.backup ? 'Backup paused' : 'Backup enabled'); }}
          aria-label="Toggle backup"
        >
          <Cloud /> backup
        </button>,{' '}
        <button
          type="button"
          className="greeting-token"
          onClick={() => demoStore.setIn('status.notification', !status.notification)}
          aria-label="Toggle notifications"
        >
          {status.notification ? <Bell /> : <BellOff />} notification
        </button>,{' '}
        <button
          type="button"
          className="greeting-token"
          onClick={() => { const next = (Number(status.rating) % 5) + 1; demoStore.setIn('status.rating', next); demoStore.toast(`Rated ${next} stars`); }}
          aria-label="Rate app"
        >
          <Star /> rating
        </button>{' '}
        and{' '}
        <button type="button" className="greeting-token recurring" onClick={() => demoStore.openCollection('recurring')} aria-label="Recurring items">
          <Repeat2 /> {recurringCount} recurring
        </button>
      </p>
    </section>
  );
}
