import React from 'react';
import { Plus, ArrowUpRight, SlidersHorizontal, Info, UserRound } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { fmtMoney, toCents, goalDaysLeft } from '../data/engine.js';
import { WavyBar, Glyph } from '../components/step4/ui4.jsx';

const TABS = [
  { id: 'active', label: 'Active' },
  { id: 'completed', label: 'Completed' },
  { id: 'archived', label: 'Archived' },
];

const SORTS = [
  { id: 'name', label: 'Name' },
  { id: 'amount', label: 'Amount' },
  { id: 'date', label: 'Date' },
  { id: 'progress', label: 'Progress' },
  { id: 'saved', label: 'Saved' },
];

export default function GoalsView() {
  const goals = useStore((s) => s.goals);
  const transactions = useStore((s) => s.transactions);
  const tab = useStore((s) => s.goalsUi.tab);
  const sort = useStore((s) => s.goalsUi.sort);
  const sortOpen = useStore((s) => s.goalsUi.sortOpen);
  const today = useStore((s) => s.today);

  const withMath = goals.map((g) => {
    const linked = transactions.filter((t) => t.goalId === g.id);
    const saved = linked
      .filter((t) => !t.transfer)
      .reduce((a, t) => a + (t.type === 'income' ? toCents(t.amount) : -toCents(t.amount)), 0);
    const target = toCents(g.target);
    return {
      ...g,
      saved,
      targetCents: target,
      remaining: Math.max(0, target - saved),
      progress: target <= 0 ? 0 : Math.round((saved / target) * 100),
      days: goalDaysLeft(g.end, today),
    };
  });

  const visible = withMath
    .filter((g) => (g.status || 'active') === tab)
    .sort((a, b) => {
      if (sort === 'amount') return b.targetCents - a.targetCents;
      if (sort === 'date') return (a.end || '').localeCompare(b.end || '');
      if (sort === 'progress') return b.progress - a.progress;
      if (sort === 'saved') return b.saved - a.saved;
      return a.title.localeCompare(b.title);
    });

  return (
    <div className="view dark-view goals-view s4">
      <header className="dark-header">
        <button type="button" className="dark-back" aria-label="Back" onClick={() => demoStore.back()}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <path d="M19 12H5m6-7-7 7 7 7" />
          </svg>
        </button>
        <h1 className="dark-title">Goals</h1>
        <div className="dark-right">
          <button type="button" className="dark-profile-btn" aria-label="Profile" onClick={() => demoStore.openProfile()}><UserRound /></button>
          <span className="page-badge">
            {goals.length}/{goals.length}
          </span>
        </div>
      </header>

      <div className="gl-meta">
        <span className="gl-count">
          {visible.length} goal{visible.length === 1 ? '' : 's'}
        </span>
        <div className="gl-actions">
          <button
            type="button"
            className="info-btn"
            aria-label="Sort goals"
            aria-expanded={sortOpen}
            onClick={() => demoStore.toggleGoalSortMenu()}
          >
            <SlidersHorizontal />
          </button>
          <button
            type="button"
            className="info-btn"
            aria-label="How goals work"
            onClick={() => demoStore.openGoalsHow(true)}
          >
            <Info />
          </button>
        </div>
      </div>

      {sortOpen ? (
        <div className="sort-menu" role="menu">
          {SORTS.map((s) => (
            <button
              key={s.id}
              type="button"
              role="menuitemradio"
              aria-checked={sort === s.id}
              className={`sort-item${sort === s.id ? ' on' : ''}`}
              onClick={() => demoStore.setGoalSort(s.id)}
            >
              {s.label}
            </button>
          ))}
        </div>
      ) : null}

      <div className="gl-list">
        {visible.map((g) => (
          <button
            key={g.id}
            type="button"
            className="goal-card"
            style={{
              background: g.surface,
              borderColor: `${g.tile}55`,
            }}
            onClick={() => demoStore.go('goalDetails', { id: g.id })}
          >
            <div className="gc-head">
              <span className="gc-tile" style={{ background: g.tile }}>
                <Glyph name="bank" />
              </span>
              <div className="gc-mid">
                <h3>{g.title}</h3>
                <p>
                  {new Date(`${g.end}T00:00:00`).toLocaleDateString('en-US', {
                    month: '2-digit',
                    day: '2-digit',
                    year: 'numeric',
                  })}
                </p>
              </div>
              <span className="gc-pill" style={{ background: g.pillBg, color: g.pillFg }}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                  <circle cx="12" cy="13" r="8" />
                  <path d="M12 9v4l2.5 2M9 2h6" />
                </svg>
                {g.days > 0 ? `${g.days} days` : g.days === 0 ? 'Today' : `${Math.abs(g.days)}d over`}
              </span>
            </div>

            <div className="gc-figures">
              <div>
                <span className="gc-label">Saved</span>
                <span className="gc-value">{fmtMoney(g.saved)}</span>
              </div>
              <span className="gc-divider" />
              <div>
                <span className="gc-label">Remaining</span>
                <span className="gc-value">{fmtMoney(g.remaining)}</span>
              </div>
            </div>

            <WavyBar
              id={`goal-${g.id}`}
              pct={g.progress}
              color={g.bar}
              track={g.track}
            />

            <div className="gc-foot">
              <span className="gc-goal">
                <ArrowUpRight />
                Goal: {fmtMoney(g.targetCents)}
              </span>
              <span className="gc-pct">{g.progress}%</span>
            </div>
          </button>
        ))}

        {visible.length === 0 ? (
          <p className="gl-empty">
            No {tab} goals yet. Tap + to create one.
          </p>
        ) : null}
      </div>

      <button
        type="button"
        className="fab goal-fab"
        aria-label="Add goal"
        onClick={() => demoStore.go('goalEditor', {})}
      >
        <Plus />
      </button>

      <div className="gtabs-wrap">
        <div className="gtabs" role="tablist">
          {TABS.map((t) => (
            <button
              key={t.id}
              type="button"
              role="tab"
              aria-selected={tab === t.id}
              className={`gtab${tab === t.id ? ' on' : ''}`}
              onClick={() => demoStore.setGoalsTab(t.id)}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
