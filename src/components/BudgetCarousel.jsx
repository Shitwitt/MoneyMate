import React from 'react';
import { Landmark, ShoppingCart, PiggyBank } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore, fmtFull } from '../data/demoStore.js';
import { Dots, useSwipe } from './ui.jsx';

const MASK = '₹••••••';

function Donut({ pct, color }) {
  const R = 40;
  const C = 2 * Math.PI * R;
  const filled = Math.min(100, Math.max(0, pct)) / 100;
  return (
    <div className="donut" role="img" aria-label={`${pct}% of budget used`}>
      <svg viewBox="0 0 96 96">
        <circle cx="48" cy="48" r={R} fill="none" stroke="#F7E7E1" strokeWidth="9" />
        <circle
          cx="48"
          cy="48"
          r={R}
          fill="none"
          stroke={color}
          strokeWidth="9"
          strokeLinecap="round"
          strokeDasharray={`${(C * filled).toFixed(2)} ${C.toFixed(2)}`}
          transform="rotate(-90 48 48)"
        />
      </svg>
      <div className="donut-text">
        <span className="dp">{pct}%</span>
        <span className="du">used</span>
      </div>
    </div>
  );
}

export default function BudgetCarousel() {
  const budgets = useStore((s) => s.budgets);
  const privacy = useStore((s) => s.privacy);

  const amt = (v) => (privacy ? MASK : fmtFull(v));
  const swipe = useSwipe({ onLeft: demoStore.cycleBudgetCarousel, onRight: demoStore.cycleBudgetCarousel });

  return (
    <>
      <div className="section-head on-sand">
        <h2>Track budgets</h2>
      </div>

      <div className="budget-carousel" {...swipe}>
        <div
          className="budget-track"
          style={{ transform: `translateX(-${budgets.slide * 100}%)` }}
        >
          {budgets.items.map((b) => (
            <button
              type="button"
              className="budget-card"
              key={b.id}
              onClick={() => demoStore.go('budgetDetail', { id: b.id })}
            >
              <div className="bc-top">
                <span className="bc-icon" style={{ background: b.accent === '#E53935' ? '#EF5350' : b.accent }}>
                  <Landmark />
                </span>
                <div className="bc-titles">
                  <div className="bc-name">{b.name}</div>
                  <div className="bc-sub">
                    {b.period} •
                    <span className="pill-status">{b.status}</span>
                  </div>
                </div>
              </div>

              <div className="bc-bottom">
                <Donut pct={b.pct} color={b.ringColor} />
                <div className="breakdown">
                  <div className="breakdown-row">
                    <Landmark aria-hidden="true" />
                    Budget
                    <span className="bv">{amt(b.budget)}</span>
                  </div>
                  <div className="breakdown-row">
                    <ShoppingCart aria-hidden="true" />
                    Spent
                    <span className="bv">{amt(b.spent)}</span>
                  </div>
                  <div className="breakdown-row">
                    <PiggyBank aria-hidden="true" />
                    Remaining
                    <span className="bv red">{amt(b.remaining)}</span>
                  </div>
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>

      <Dots count={budgets.items.length} active={budgets.slide} className="carousel-dots" />
    </>
  );
}
