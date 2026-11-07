import React from 'react';
import { Banknote, CalendarDays, Check, Info, ListFilter, Plus, SlidersHorizontal, Sparkles, Wallet } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, fmtFull, maskFor } from '../data/demoStore.js';
import { budgetCards } from '../data/derive.js';
import { SubHeader, WavyProgress, RingGauge } from '../components/step2/ui2.jsx';
import { SectionHead } from '../components/ui.jsx';

function PillIcon({ icon }) { return icon === 'cash' ? <Banknote /> : <Wallet />; }

export default function BudgetsView() {
  const state = useStore((s) => s);
  const items = budgetCards(state);
  const tab = state.budgetsUi.tab;
  const base = state.profile.baseCurrency;
  const mask = maskFor(base);
  const total = items.reduce((a, b) => a + b.limit, 0);
  const spent = items.reduce((a, b) => a + b.spent, 0);
  const remaining = total - spent;
  const visible = items.filter((b) => (tab === 'completed' ? b.status === 'Over budget' || b.usedPct >= 100 : b.status !== 'Over budget' && b.usedPct < 100));
  const summary = [
    { key: 'total', label: 'Total', bg: '#F3E2D9', iconBg: '#7B4028', iconFg: '#FFF4EC', value: total, icon: 'wallet' },
    { key: 'spent', label: 'Spent', bg: '#F8D9D3', iconBg: '#C45B44', iconFg: '#FFFFFF', value: spent, icon: 'cash' },
    { key: 'remaining', label: 'Remaining', bg: '#DFEEE0', iconBg: '#2E7D32', iconFg: '#FFFFFF', value: remaining, icon: 'wallet' },
  ];

  return (
    <div className="view budgets-view">
      <SubHeader
        title="Budgets"
        right={
          <>
            <button type="button" className="icon-btn" aria-label="How budgets work" onClick={() => demoStore.openHowBudgets(true)}><Info /></button>
            <button type="button" className="chip-button" onClick={() => demoStore.openBudgetEditor()}><Plus /> Add budget</button>
          </>
        }
      />

      <div className="budget-summary">
        {summary.map((p) => (
          <div className="bs-pill" key={p.key} style={{ background: p.bg }}>
            <span className="bs-ico" style={{ background: p.iconBg, color: p.iconFg }}><PillIcon icon={p.icon} /></span>
            <span className="bs-mid"><small>{p.label}</small><strong>{state.privacy ? mask : fmtFull(p.value, base)}</strong></span>
          </div>
        ))}
      </div>

      <div className="filter-row">
        <button type="button" className={`filter-btn${tab === 'active' ? ' on' : ''}`} onClick={() => demoStore.setBudgetsTab('active')}>Active</button>
        <button type="button" className={`filter-btn${tab === 'completed' ? ' on' : ''}`} onClick={() => demoStore.setBudgetsTab('completed')}>Completed</button>
        <button type="button" className="filter-btn" onClick={demoStore.toggleShowBudget}><ListFilter /> {state.budgetsUi.showOnHome ? 'Shown on Home' : 'Hidden on Home'}</button>
      </div>

      <SectionHead title={`${visible.length} budgets`} action="Add budget" onAction={() => demoStore.openBudgetEditor()} />

      <div className="budget-list">
        {visible.map((b) => (
          <div className="budget-card2 live-card" key={b.id} style={{ borderColor: `${b.color}55` }}>
            <button type="button" className="budget-card-main" onClick={() => demoStore.go('budgetDetail', { id: b.id })}>
              <div className="bc2-top">
                <span className="bc2-tile" style={{ background: b.color, color: '#fff' }}><Wallet /></span>
                <div className="bc2-mid">
                  <div className="bc2-name">{b.name}</div>
                  <div className="bc2-chips">
                    <span className="mc" style={{ background: `${b.color}22`, color: b.color }}><CalendarDays /> {b.period}</span>
                    <span className="mc" style={{ background: `${b.color}22`, color: b.color }}>{b.for}</span>
                    <span className="mc" style={{ background: `${b.color}22`, color: b.color }}>{b.mode === 'Automatic' ? <Sparkles /> : <SlidersHorizontal />}{b.mode}</span>
                  </div>
                </div>
                <RingGauge pct={b.pct} size={58} stroke={7} color={b.color} label={`${b.usedPct}% used`}><b>{b.usedPct}%</b></RingGauge>
              </div>
              <div className="bc2-split">
                <div><div className="bc2-label">Spent</div><div className="bc2-value" style={{ color: b.color }}>{state.privacy ? mask : fmtFull(b.spent, base)}</div></div>
                <div><div className="bc2-label">Remaining</div><div className="bc2-value">{state.privacy ? mask : fmtFull(b.remaining, base)}</div></div>
                <div><div className="bc2-label">Limit</div><div className="bc2-value">{state.privacy ? mask : fmtFull(b.limit, base)}</div></div>
              </div>
              <WavyProgress pct={b.pct} color={b.color} track="#E9D9D0" height={9} stroke={4} label={`${b.pct}% of ${b.name}`} />
              <div className="bc2-foot"><span><Check /> {b.status}</span><span>{state.privacy ? mask : fmtFull(b.dailySafeSpend, base)}/day · {b.daysLeft} days left</span></div>
            </button>
            <button type="button" className="btn ghost small budget-edit" onClick={() => demoStore.openBudgetEditor(b.id)}>Edit</button>
          </div>
        ))}
        {visible.length === 0 ? <button type="button" className="live-card empty-note" onClick={() => demoStore.openBudgetEditor()}>No {tab} budgets — add one now.</button> : null}
      </div>
    </div>
  );
}
