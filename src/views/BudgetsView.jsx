import React from 'react';
import {
  Wallet,
  Check,
  Info,
  CalendarDays,
  ListFilter,
  Sparkles,
  SlidersHorizontal,
  Banknote,
} from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, usd } from '../data/demoStore.js';
import { budgets, budgetSummary } from '../data/step2Data.js';
import { SubHeader, WavyProgress, RingGauge, ExitDemoPill } from '../components/step2/ui2.jsx';
import { Dots, useSwipe } from '../components/ui.jsx';

const SUMMARY_PILLS = [
  {
    key: 'total',
    label: 'Total',
    bg: '#4E5B8C',
    iconBg: '#BBC3E8',
    iconFg: '#2C3763',
    value: budgetSummary.total,
    icon: 'wallet',
  },
  {
    key: 'spent',
    label: 'Spent',
    bg: '#8C4A54',
    iconBg: '#F2C2CB',
    iconFg: '#6B2C36',
    value: budgetSummary.spent,
    icon: 'cash',
  },
  {
    key: 'remaining',
    label: 'Remaining',
    bg: '#00695C',
    iconBg: '#A7E8D8',
    iconFg: '#004D40',
    value: budgetSummary.remaining,
    icon: 'wallet',
  },
];

function PillIcon({ icon }) {
  return icon === 'cash' ? <Banknote /> : <Wallet />;
}

function BudgetCard({ b }) {
  return (
    <button
      type="button"
      className="budget-card2"
      style={{ background: b.surface }}
      onClick={() => demoStore.go('budgetDetail', { id: b.id })}
    >
      <div className="bc2-top">
        <span className="bc2-tile" style={{ background: b.tile, color: b.tileFg }}>
          <Wallet />
        </span>
        <div className="bc2-mid">
          <div className="bc2-name">{b.name}</div>
          <div className="bc2-chips">
            <span className="mc" style={{ background: b.accentSoft, color: b.accent }}>
              Monthly
            </span>
            <span className="mc" style={{ background: b.accentSoft, color: b.accent }}>
              {b.mode}
            </span>
            <span className="mc" style={{ background: b.autoChip.bg, color: b.autoChip.fg }}>
              {b.autoChip.icon === 'auto' ? <Sparkles className="mc-ico" /> : <SlidersHorizontal className="mc-ico" />}
              {b.autoChip.label}
            </span>
          </div>
        </div>
        <span className="bc2-pct" style={{ borderColor: b.pillBorder, color: b.accent }}>
          <Check aria-hidden="true" />
          {b.pct}%
        </span>
      </div>

      <div className="bc2-split">
        <div>
          <div className="bc2-label">Spent</div>
          <div className="bc2-value" style={{ color: b.accent }}>
            {usd(b.spent)}
          </div>
        </div>
        <div className="bc2-divider" />
        <div>
          <div className="bc2-label">Budget</div>
          <div className="bc2-value dark">{usd(b.total)}</div>
        </div>
      </div>

      <WavyProgress pct={b.pct} color={b.accent} track={b.trackColor} height={10} stroke={4} />

      <div className="bc2-info">
        <span className="bc2-info-row">
          <CalendarDays aria-hidden="true" />
          You can spend ${b.perDay}/day for {b.daysLeft} more days
        </span>
        <span className="bc2-info-row">
          <Wallet aria-hidden="true" />
          Remaining
          <b style={{ color: b.accent }}>{usd(b.remaining)}</b>
        </span>
      </div>
    </button>
  );
}

export default function BudgetsView() {
  const slide = useStore((s) => s.budgetsUi.slide);

  const swipe = useSwipe({
    onLeft: () => demoStore.setBudgetSlide(1),
    onRight: () => demoStore.setBudgetSlide(0),
  });

  return (
    <div className="view">
      <SubHeader
        title="Budgets"
        center={false}
        right={
          <>
            <ExitDemoPill />
            <span className="page-chip">{budgetSummary.pages}</span>
          </>
        }
      />

      <div className="budget-summary" {...swipe}>
        <RingGauge pct={budgetSummary.pct} size={155} stroke={18}>
          <span className="rg-main">{budgetSummary.pct}%</span>
          <span className="rg-sub">Spent</span>
        </RingGauge>

        <div className="summary-pills">
          {SUMMARY_PILLS.map((p) => (
            <div className="sum-pill" key={p.key} style={{ background: p.bg }}>
              <span className="sum-ico" style={{ background: p.iconBg, color: p.iconFg }}>
                <PillIcon icon={p.icon} />
              </span>
              <div>
                <div className="sum-label">{p.label}</div>
                <div className="sum-value">{usd(p.value)}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <Dots count={2} active={slide} />

      <div className="budgets-subhead">
        <span className="bs-title">2 budgets</span>
        <div className="bs-actions">
          <button
            type="button"
            className="icon-btn dark"
            aria-label="Sort budgets"
            onClick={() => demoStore.toast('Sort budgets')}
          >
            <ListFilter />
          </button>
          <button
            type="button"
            className="icon-btn dark"
            aria-label="How budgets work"
            onClick={() => demoStore.openHowBudgets(true)}
          >
            <Info />
          </button>
        </div>
      </div>

      <div className="budget-list">
        {budgets.map((b) => (
          <BudgetCard b={b} key={b.id} />
        ))}
      </div>
    </div>
  );
}
