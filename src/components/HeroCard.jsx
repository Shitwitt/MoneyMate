import React from 'react';
import { ArrowUp, EyeOff, Info } from 'lucide-react';

import { demoStore, fmtFull, maskFor } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { useT } from '../hooks/useT.js';
import { heroTotals } from '../data/derive.js';

export default function HeroCard() {
  const hero = useStore((s) => heroTotals(s));
  const base = useStore((s) => s.profile.baseCurrency);
  const privacy = useStore((s) => s.privacy);
  const t = useT();
  const mask = maskFor(base);
  const shown = privacy ? mask : fmtFull(hero.total, base);
  const incomeDelta = Number(hero.income.deltaPct) || 0;
  const expenseDelta = Number(hero.expense.deltaPct) || 0;

  return (
    <section className="hero-card" aria-label={t('Total balance')}>
      <div className="hero-top">
        <button type="button" className="hero-label" onClick={demoStore.openBalance}>{t('Total balance')}</button>
        <button type="button" className="hero-eye" aria-label="Toggle privacy" onClick={demoStore.togglePrivacy}>
          <EyeOff />
        </button>
      </div>

      <div className="hero-amount-row">
        <div className="hero-amount" aria-live="polite">{shown}</div>
        <button type="button" className="hero-info" aria-label="Balance details" onClick={demoStore.openBalance}><Info /></button>
      </div>

      <div className="hero-split">
        <button type="button" className="hero-stat" onClick={() => demoStore.openCollection('transactions')}>
          <span className="hero-stat-label">{t('Income')}</span>
          <span className="hero-stat-value">
            <b>{privacy ? mask : fmtFull(hero.income.now, base)}</b>
            <span className={`hero-delta ${incomeDelta >= 0 ? 'up-pos' : 'up-neg'}`}><ArrowUp /> {Math.abs(incomeDelta)}%</span>
          </span>
          <small>Compared to {privacy ? mask : fmtFull(hero.income.prev, base)} last month</small>
        </button>
        <button type="button" className="hero-stat" onClick={() => demoStore.openCollection('transactions')}>
          <span className="hero-stat-label">{t('Expense')}</span>
          <span className="hero-stat-value">
            <b>{privacy ? mask : fmtFull(hero.expense.now, base)}</b>
            <span className={`hero-delta ${expenseDelta >= 0 ? 'up-pos' : 'up-neg'}`}><ArrowUp /> {Math.abs(expenseDelta)}%</span>
          </span>
          <small>Compared to {privacy ? mask : fmtFull(hero.expense.prev, base)} last month</small>
        </button>
      </div>
    </section>
  );
}
