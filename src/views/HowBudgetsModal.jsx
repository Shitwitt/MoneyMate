import React, { useEffect } from 'react';
import {
  ArrowUpDown,
  Shapes,
  SlidersHorizontal,
  CalendarDays,
  Tag,
  RefreshCw,
  ChartSpline,
  X,
} from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { howBudgetsWork } from '../data/step2Data.js';

const ICONS = {
  swipe: ArrowUpDown,
  shapes: Shapes,
  sliders: SlidersHorizontal,
  calendar: CalendarDays,
  tag: Tag,
  rolling: RefreshCw,
  chart: ChartSpline,
};

export default function HowBudgetsModal() {
  useEffect(() => {
    const onKey = (e) => {
      if (e.key === 'Escape') demoStore.openHowBudgets(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  return (
    <div className="modal-scrim" role="presentation" onClick={() => demoStore.openHowBudgets(false)}>
      <div
        className="how-sheet"
        role="dialog"
        aria-modal="true"
        aria-label="How Budgets Work"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="how-head">
          <h2>How Budgets Work</h2>
          <button
            type="button"
            className="how-close"
            aria-label="Close"
            onClick={() => demoStore.openHowBudgets(false)}
          >
            <X />
          </button>
        </div>

        <p className="how-intro">
          Budgets help you set spending limits and track your expenses. Here&apos;s how to get
          started.
        </p>

        <div className="how-items">
          {howBudgetsWork.map((item) => {
            const Icon = ICONS[item.icon] || Shapes;
            return (
              <div className="how-item" key={item.title}>
                <span className="how-ico">
                  <Icon />
                </span>
                <div>
                  <div className="how-title">{item.title}</div>
                  {item.lines.map((l) => (
                    <p className="how-line" key={l}>
                      {l}
                    </p>
                  ))}
                </div>
              </div>
            );
          })}
        </div>

        <button type="button" className="how-cta" onClick={() => demoStore.openHowBudgets(false)}>
          Got it
        </button>
      </div>
    </div>
  );
}
