import React from 'react';
import { ChevronRight, Plus, Target } from 'lucide-react';

import { SectionHead } from './ui.jsx';
import { Dots, useSwipe } from './ui.jsx';
import { RingGauge, WavyProgress } from './charts/Interactive.jsx';
import { demoStore, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { budgetCards } from '../data/derive.js';

export default function BudgetCarousel() {
  const items = useStore((s) => budgetCards(s));
  const slide = useStore((s) => s.budgetsUi.slide);
  const base = useStore((s) => s.profile.baseCurrency);
  const privacy = useStore((s) => s.privacy);
  const swipe = useSwipe({
    onLeft: () => demoStore.setBudgetSlide((slide + 1) % Math.max(1, items.length)),
    onRight: () => demoStore.setBudgetSlide((slide - 1 + Math.max(1, items.length)) % Math.max(1, items.length)),
  });
  const i = Math.min(slide, Math.max(0, items.length - 1));
  const b = items[i];

  return (
    <section className="budget-carousel" aria-label="Budget overview">
      <SectionHead title="Track budgets" action="See all" onAction={() => demoStore.go('budgets')} />
      <div className="budget-carousel-actions">
        <button type="button" className="chip-button" onClick={() => demoStore.openBudgetEditor()}><Plus /> Add budget</button>
      </div>
      {b ? (
        <div className="budget-slide live-card" {...swipe} onClick={() => demoStore.go('budgetDetail', { id: b.id })} role="button" tabIndex={0}>
          <div className="budget-slide-head">
            <Target />
            <strong>{b.name}</strong>
            <ChevronRight />
          </div>
          <div className="budget-slide-body">
            <RingGauge pct={b.usedPct || 0} size={78} stroke={9} color={b.color || '#3949AB'} label={`${b.usedPct}% used`}>
              <b>{b.usedPct || 0}%</b><small>used</small>
            </RingGauge>
            <div className="budget-slide-nums">
              <span>Spent {privacy ? '••••' : fmtFull(b.spent, base)}</span>
              <span>Remaining {privacy ? '••••' : fmtFull(b.remaining, base)}</span>
              <span>Limit {privacy ? '••••' : fmtFull(b.limit, base)}</span>
              <small>{privacy ? '••••' : fmtFull(b.dailySafeSpend, base)}/day for {b.daysLeft} more days</small>
            </div>
          </div>
          <WavyProgress pct={b.pct || 0} color={b.color || '#3949AB'} track="#E4E1F2" height={9} stroke={4} label={`${b.pct}% of budget`} />
          <Dots count={items.length} active={i} />
        </div>
      ) : (
        <button type="button" className="live-card empty-note" onClick={() => demoStore.openBudgetEditor()}>
          No budgets yet — tap to add your first live budget.
        </button>
      )}
    </section>
  );
}
