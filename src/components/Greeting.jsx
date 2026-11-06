import React from 'react';
import { BellOff, Star } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';

/* lucide ships no CloudCheck in older versions — build it inline from Cloud + check */
function CloudCheck() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M12 13l2 2 4-4" />
      <path d="M17.5 19a4.5 4.5 0 0 0 .5-8.97A6 6 0 0 0 6.2 9.2A3.5 3.5 0 0 0 7 19h10.5Z" />
    </svg>
  );
}

function CoinBadge() {
  return (
    <span className="coin-badge" aria-hidden="true">
      <i />
      <i />
    </span>
  );
}

export default function Greeting() {
  const user = useStore((s) => s.user);
  const greeting = useStore((s) => s.greeting);
  const status = useStore((s) => s.status);

  return (
    <p className="greeting">
      {greeting}{' '}
      <button
        type="button"
        className="trigger"
        onClick={() => demoStore.toast(`Signed in as ${user.name}`)}
      >
        <b>{user.name}</b>
      </button>
      . You have{' '}
      <span className="g-token">
        <button
          type="button"
          className="trigger"
          aria-label="Cloud backup status"
          onClick={() => demoStore.toast(status.backup ? 'Backup is on — synced 2 min ago' : 'Backup is off')}
        >
          <CloudCheck />
        </button>{' '}
        <button
          type="button"
          className="trigger"
          onClick={() => demoStore.toast(status.notifications ? 'Notifications enabled' : 'Notifications are off')}
        >
          <b>backup</b>
        </button>
      </span>
      ,{' '}
      <span className="g-token">
        <button
          type="button"
          className="trigger"
          aria-label="Notification status"
          onClick={() => demoStore.setIn('status.notifications', !status.notifications)}
        >
          <BellOff />
        </button>{' '}
        <button
          type="button"
          className="trigger"
          onClick={() => demoStore.setIn('status.notifications', !status.notifications)}
        >
          <b>notification</b>
        </button>
      </span>
      ,{' '}
      <span className="g-token">
        <button
          type="button"
          className="trigger"
          aria-label="Rate the app"
          onClick={() => demoStore.toast('Thanks! Rate MoneyMate on the Play Store ⭐')}
        >
          <Star />
        </button>{' '}
        <button
          type="button"
          className="trigger"
          onClick={() => demoStore.toast('Thanks! Rate MoneyMate on the Play Store ⭐')}
        >
          <b>rating</b>
        </button>
      </span>{' '}
      and{' '}
      <span className="g-token">
        <CoinBadge />
        <button
          type="button"
          className="trigger"
          onClick={() => demoStore.toast(`${status.recurring} recurring payments active`)}
        >
          <b>{status.recurring} recurring</b>
        </button>
      </span>
    </p>
  );
}
