import React from 'react';
import { CalendarDays, Pencil, Plus, TrendingUp, Wallet } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, fmtFull, maskFor } from '../data/demoStore.js';
import { budgetCards, budgetPace } from '../data/derive.js';
import { SubHeader } from '../components/step2/ui2.jsx';
import { SectionHead } from '../components/ui.jsx';
import { InteractiveChart, ChartTooltipCard, RingGauge, WavyProgress } from '../components/charts/Interactive.jsx';
import LiveTransactionRow from '../components/LiveTransactionRow.jsx';

const W = 320;
const H = 184;
const PAD = { l: 34, r: 10, t: 12, b: 24 };

export default function BudgetDetailView() {
  const state = useStore((s) => s);
  const params = state.route.params;
  const base = state.profile.baseCurrency;
  const mask = maskFor(base);
  const items = budgetCards(state);
  const budget = items.find((b) => b.id === params.id) || items[0];
  const pace = budget ? budgetPace(state, budget.id) : null;
  const points = pace?.points || [];
  const maxV = pace?.maxV || 1;
  const limit = budget?.limit || 0;
  const y = (v) => H - PAD.b - (v / maxV) * (H - PAD.t - PAD.b);
  const line = (key) => points.map((p, i) => `${i === 0 ? 'M' : 'L'}${PAD.l + (i / Math.max(1, points.length - 1)) * (W - PAD.l - PAD.r)},${y(p[key]).toFixed(2)}`).join(' ');
  const recent = budget
    ? state.transactions
      .filter((t) => t.budgetId === budget.id || (budget.categories || []).includes(t.category))
      .sort((a, b) => (a.date < b.date ? 1 : -1))
    : [];

  if (!budget || !pace) {
    return (
      <div className="view">
        <SubHeader title="Budget Detail" />
        <button type="button" className="live-card empty-note" onClick={() => demoStore.openBudgetEditor()}>No budget selected — add one now.</button>
      </div>
    );
  }

  return (
    <div className="view budget-detail">
      <SubHeader
        title={budget.name}
        right={<button type="button" className="icon-btn" aria-label="Edit budget" onClick={() => demoStore.openBudgetEditor(budget.id)}><Pencil /></button>}
      />

      <section className="live-card">
        <div className="budget-detail-head">
          <RingGauge pct={budget.pct} size={86} stroke={9} color={budget.color || '#3949AB'} label={`${budget.usedPct}% used`}>
            <b>{budget.usedPct}%</b><small>used</small>
          </RingGauge>
          <div>
            <h2><Wallet /> {budget.name}</h2>
            <p><CalendarDays /> {budget.period} · {budget.for} · {budget.type} · {budget.mode}</p>
            <p>{budget.start} → {budget.end}</p>
          </div>
        </div>
        <div className="bc2-split">
          <div><div className="bc2-label">Spent</div><div className="bc2-value" style={{ color: budget.color }}>{state.privacy ? mask : fmtFull(budget.spent, base)}</div></div>
          <div><div className="bc2-label">Remaining</div><div className="bc2-value">{state.privacy ? mask : fmtFull(budget.remaining, base)}</div></div>
          <div><div className="bc2-label">Limit</div><div className="bc2-value">{state.privacy ? mask : fmtFull(budget.limit, base)}</div></div>
        </div>
        <WavyProgress pct={budget.pct} color={budget.color || '#3949AB'} track="#E9D9D0" height={10} stroke={4} label={`${budget.pct}% of budget`} />
        <div className="live-math">
          <span>Daily Safe Spend</span>
          <b>You can spend {state.privacy ? mask : fmtFull(budget.dailySafeSpend, base)}/day for {budget.daysLeft} more days</b>
        </div>
      </section>

      <section className="live-card">
        <div className="rp-card-head"><span className="rp-head-simple"><TrendingUp /> Pace chart</span><span className="rp-badge">{points.length} days</span></div>
        <InteractiveChart
          count={points.length}
          width={W}
          height={H}
          padL={PAD.l}
          padR={PAD.r}
          padT={PAD.t}
          padB={PAD.b}
          crosshairColor="#1E88E5"
          ariaLabel="Budget pace chart with actual spending, ideal pace and limit"
          tooltip={(i) => {
            const p = points[i];
            const diff = p.difference;
            return (
              <ChartTooltipCard
                title={p.date}
                rows={[
                  { label: 'Actual Spent', value: fmtFull(p.actual, base) },
                  { label: `Ideal Pace ${fmtFull(p.ideal, base)}`, value: `${diff >= 0 ? 'Under' : 'Over'} pace by ${fmtFull(Math.abs(diff), base)}` },
                  { label: 'Budget Limit', value: fmtFull(p.limit, base) },
                ]}
              />
            );
          }}
          tooltipVariant="card"
          style={{ height: H }}
        >
          {({ active, xAt }) => (
            <>
              {[0, 0.5, 1].map((f) => {
                const v = maxV * f;
                return (
                  <g key={f}>
                    <line x1={PAD.l} x2={W - PAD.r} y1={y(v)} y2={y(v)} stroke="#E9D9D0" strokeWidth="0.7" />
                    <text x={PAD.l - 4} y={y(v) + 3} textAnchor="end" fontSize="8" fill="#8B746B">{Math.round(v / 1000)}k</text>
                  </g>
                );
              })}
              {[0, Math.floor((points.length - 1) / 2), points.length - 1].map((i) => (
                <text key={i} x={xAt(i)} y={H - 5} textAnchor="middle" fontSize="8" fill="#8B746B">{points[i]?.date?.slice(5) || ''}</text>
              ))}
              <line x1={PAD.l} x2={W - PAD.r} y1={y(limit)} y2={y(limit)} stroke="#EF5350" strokeWidth="1.8" strokeDasharray="7 5" />
              <text x={W - PAD.r - 2} y={y(limit) - 4} textAnchor="end" fontSize="9" fontWeight="800" fill="#EF5350">Limit</text>
              <path d={line('ideal')} fill="none" stroke="#9E9E9E" strokeWidth="1.8" strokeDasharray="5 5" />
              <path d={line('actual')} fill="none" stroke="#1E88E5" strokeWidth="2.8" strokeLinecap="round" />
              {active != null && points[active] ? (
                <g>
                  <circle cx={xAt(active)} cy={y(points[active].actual)} r="4.2" fill="#1E88E5" stroke="#fff" strokeWidth="1.5" />
                  <circle cx={xAt(active)} cy={y(points[active].ideal)} r="3.4" fill="#9E9E9E" />
                </g>
              ) : null}
            </>
          )}
        </InteractiveChart>
        <div className="pace-legend">
          <span><i style={{ borderColor: '#1E88E5' }} />Actual Spent</span>
          <span><i style={{ borderColor: '#9E9E9E', borderTopStyle: 'dashed' }} />Ideal Pace</span>
          <span><i style={{ borderColor: '#EF5350', borderTopStyle: 'dashed' }} />Budget Limit</span>
        </div>
      </section>

      <SectionHead title="Recent transactions" action="See all" onAction={() => demoStore.openSearch(budget.name)} />
      <div className="upcoming-actions">
        <button type="button" className="chip-button" onClick={() => demoStore.openTransactionEditor({ budgetId: budget.id, type: budget.for === 'Income' ? 'income' : 'expense' })}>
          <Plus /> Add transaction
        </button>
      </div>
      <div className="live-tx-list">
        {recent.slice(0, 14).map((t) => <LiveTransactionRow key={t.id} tx={t} />)}
        {recent.length === 0 ? <p className="empty-note">No linked transactions yet.</p> : null}
      </div>
    </div>
  );
}
