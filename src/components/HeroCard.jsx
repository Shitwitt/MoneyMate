import React from 'react';
import { ArrowUp, Eye, EyeOff, Info } from 'lucide-react';

import { demoStore, fmtFull, maskFor } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { heroTotals } from '../data/derive.js';

export default function HeroCard() {
  const hero = useStore((s) => heroTotals(s));
  const base = useStore((s) => s.profile.baseCurrency);
  const privacy = useStore((s) => s.privacy);
  const mask = maskFor(base);
  const shown = privacy ? mask : fmtFull(hero.total, base);

  return (
    <section className="hero-card" aria-label="Total balance">
      <div className="hero-top">
        <button type="button" className="hero-label" onClick={demoStore.openBalance}>
          Total balance <Info />
        </button>
        <button type="button" className="hero-eye" aria-label="Toggle privacy" onClick={demoStore.togglePrivacy}>
          {privacy ? <EyeOff /> : <Eye />}
        </button>
      </div>

      <div className="hero-amount" aria-live="polite">{shown}</div>
      <div className="hero-compare">
        <ArrowUp />
        {privacy ? mask : fmtFull(Math.abs(hero.income.now - hero.expense.now), base)} compared to last month
      </div>

      <div className="hero-stats">
        <button type="button" className="hero-stat" onClick={() => demoStore.openCollection('transactions')}>
          <span className="hero-stat-label">Income</span>
          <b>{privacy ? mask : fmtFull(hero.income.now, base)}</b>
          <small>{hero.income.deltaPct}% vs last month</small>
        </button>
        <button type="button" className="hero-stat" onClick={() => demoStore.openCollection('transactions')}>
          <span className="hero-stat-label">Expense</span>
          <b>{privacy ? mask : fmtFull(hero.expense.now, base)}</b>
          <small>{hero.expense.deltaPct}% vs last month</small>
        </button>
      </div>
    </section>
  );
}
