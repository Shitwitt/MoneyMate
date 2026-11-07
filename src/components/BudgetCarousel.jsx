import React from 'react';
import { ChevronRight, Landmark, PiggyBank, ShoppingCart } from 'lucide-react';

import { Dots, useSwipe } from './ui.jsx';
import { RingGauge } from './charts/Interactive.jsx';
import { demoStore, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { budgetCards } from '../data/derive.js';

export default function BudgetCarousel() {
  const items = useStore((s) => budgetCards(s));
  const slide = useStore((s) => s.budgetsUi.slide);
  const base = useStore((s) => s.profile.baseCurrency);
  const privacy = useStore((s) => s.privacy);
  const foodIndex = items.findIndex((item) => item.id === 'food');
  const baseIndex = slide === 0 && foodIndex >= 0 ? foodIndex : Math.min(slide, Math.max(0, items.length - 1));
  const swipe = useSwipe({
    onLeft: () => demoStore.setBudgetSlide((baseIndex + 1) % Math.max(1, items.length)),
    onRight: () => demoStore.setBudgetSlide((baseIndex - 1 + Math.max(1, items.length)) % Math.max(1, items.length)),
  });
  const i = Math.min(baseIndex, Math.max(0, items.length - 1));
  const b = items[i];
  const money = (v) => privacy ? '••••' : fmtFull(v, base);
  const over = b && b.remaining < 0;

  return (
    <section className="budget-carousel" aria-label="Budget overview">
      <div className="section-head"><h2>Track budgets</h2></div>
      {b ? (
        <>
          <div className="budget-viewport" {...swipe}>
            <button type="button" className="budget-slide" onClick={() => demoStore.go('budgetDetail', { id: b.id })} aria-label={`Open ${b.name}`}>
              <div className="budget-slide-head">
                <span className="budget-slide-icon"><Landmark /></span>
                <div>
                  <strong>{b.name}</strong>
                  <small>{b.period} · <em className={over ? 'over' : ''}>{b.status}</em></small>
                </div>
                <ChevronRight />
              </div>
              <div className="budget-slide-body">
                <RingGauge
                  pct={b.usedPct || 0}
                  size={112}
                  stroke={9}
                  color={over ? '#F44336' : (b.accent || '#3949AB')}
                  track="#F1DDD6"
                  label={`${b.usedPct || 0}% used`}
                >
                  <b>{Math.round(b.usedPct || 0)}%</b><small>used</small>
                </RingGauge>
                <div className="budget-slide-nums">
                  <span><Landmark /> Budget <b>{money(b.limit)}</b></span>
                  <span><ShoppingCart /> Spent <b>{money(b.spent)}</b></span>
                  <span><PiggyBank /> Remaining <b className={over ? 'negative' : ''}>{money(b.remaining)}</b></span>
                </div>
              </div>
            </button>
            <div className="budget-next-edge" aria-hidden="true" />
          </div>
          <Dots count={items.length} active={i} className="dots budget-dots" />
        </>
      ) : (
        <button type="button" className="empty-note" onClick={() => demoStore.openBudgetEditor()}>
          No budgets yet — tap to add your first live budget.
        </button>
      )}
    </section>
  );
}
