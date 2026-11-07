import React from 'react';
import {
  ArrowUpRight,
  CalendarDays,
  ChevronRight,
  Clock3,
  Gauge,
  Layers3,
  MapPin,
  PieChart,
  Star,
  Tag,
  Target,
  Trophy,
  UserRound,
  Wallet,
} from 'lucide-react';

import { Card, Dots, useSwipe } from './ui.jsx';
import { MiniChip } from './step2/ui2.jsx';
import { InteractiveChart, RingGauge, WavyProgress } from './charts/Interactive.jsx';
import Sparkline from './Sparkline.jsx';
import { demoStore, fmtFull, fmtCompact, usd } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { overview, weeklySeries, last30Series, budgetCards, goalCards } from '../data/derive.js';

const COLLECTION = {
  labels: 'labels', recurring: 'recurring', categories: 'categories',
  places: 'places', people: 'people', achievements: 'achievements',
};

function WeeklyBars({ weekly, base }) {
  const W = 300;
  const H = 88;
  const padL = 6;
  const padR = 6;
  const padT = 8;
  const padB = 18;
  const plotH = H - padT - padB;
  return (
    <InteractiveChart
      count={7}
      width={W}
      height={H}
      padL={padL}
      padR={padR}
      padT={padT}
      padB={padB}
      crosshair={false}
      ariaLabel="Weekly spending bars, this week versus last week"
      tooltip={(i) => `${weekly.days[i].d} • ${fmtFull(weekly.days[i].amount, base)}`}
      tooltipVariant="pill"
      style={{ height: H }}
    >
      {({ active, xCenter, plotW }) => {
        const bw = plotW / 7;
        return (
          <>
            {weekly.days.map((d, i) => {
              const x = xCenter(i);
              const prevH = Math.max(2, (d.prevPct / 100) * plotH);
              const curH = Math.max(2, (d.pct / 100) * plotH);
              const isActive = active === i || (!active && d.d === weekly.highlight);
              return (
                <g key={d.date}>
                  <rect x={x - bw * 0.36} y={H - padB - prevH} width={bw * 0.28} height={prevH} rx={bw * 0.14} fill="#DED1C8" opacity="0.85" />
                  <rect
                    x={x - bw * 0.02}
                    y={H - padB - curH - (isActive ? 3 : 0)}
                    width={bw * 0.34}
                    height={curH + (isActive ? 3 : 0)}
                    rx={bw * 0.17}
                    fill={isActive ? '#FFB59A' : '#7B4028'}
                    stroke={isActive ? '#7B4028' : 'none'}
                    strokeWidth="1"
                  />
                  <text x={x} y={H - 4} textAnchor="middle" fontSize="9" fontWeight={isActive ? 800 : 600} fill={isActive ? '#7B4028' : '#8B746B'}>{d.d}</text>
                </g>
              );
            })}
          </>
        );
      }}
    </InteractiveChart>
  );
}

export default function BentoGrid() {
  const data = useStore((s) => ({
    o: overview(s),
    weekly: weeklySeries(s),
    last30: last30Series(s),
    budgets: budgetCards(s),
    goals: goalCards(s),
  }));
  const base = useStore((s) => s.profile.baseCurrency);
  const privacy = useStore((s) => s.privacy);
  const slide = useStore((s) => s.budgetsUi.bentoSlide);
  const swipe = useSwipe({ onLeft: demoStore.cycleBudgetBento, onRight: demoStore.cycleBudgetBento });
  const { o, weekly, last30, budgets, goals } = data;
  const budget = budgets[0];
  const goalPct = o.goals.target ? Math.round((o.goals.progressed / o.goals.target) * 100) : 0;
  const habitScore = Math.max(1, Math.min(100, Math.round((weekly.thisWeek / Math.max(1, weekly.lastWeek)) * 100) || 0));

  const open = (label) => {
    if (COLLECTION[label]) return demoStore.openCollection(COLLECTION[label]);
    if (label === 'Total balance') return demoStore.openBalance();
    if (label === 'Overview' || label === 'Customize') return demoStore.openLayout();
    if (label === 'Weekly' || label === 'Last 30 days' || label === 'Trend' || label === 'Analytics') return demoStore.go('reports');
    if (label === 'Budgets') return demoStore.go('budgets');
    if (label === 'Goals') return demoStore.go('goals');
    if (label === 'Assets') return demoStore.go('assets');
    if (label === 'Bills') return demoStore.go('billSplitter');
    if (label === 'Loans') return demoStore.go('loans');
    if (label === 'Accounts') return demoStore.go('accounts');
    return demoStore.openProfile();
  };

  return (
    <div className="bento-grid">
      <Card icon={Layers3} title="Overview" onClick={() => open('Overview')}>
        <strong className="bento-big">{o.accounts.count} accounts</strong>
        <small className="bento-sub">{privacy ? '••••' : fmtCompact(o.accounts.total, base)} · {o.categories.categories} categories</small>
      </Card>

      <Card icon={CalendarDays} title="Weekly" chevron={false} onClick={() => open('Weekly')}>
        <WeeklyBars weekly={weekly} base={base} />
        <div className="weekly-legend">
          <span>This {privacy ? '••••' : fmtFull(weekly.thisWeek, base)}</span>
          <span>Last {privacy ? '••••' : fmtFull(weekly.lastWeek, base)}</span>
        </div>
      </Card>

      <Card icon={ArrowUpRight} title="Last 30 days" chevron={false} onClick={() => open('Last 30 days')}>
        <Sparkline data={last30} />
      </Card>

      <Card icon={Gauge} title="Habit score" onClick={() => open('Analytics')}>
        <div className="habit-gauge">
          <RingGauge pct={habitScore} size={72} stroke={8} color="#7B4028" label="Habit score">
            <b>{habitScore}</b><small>/100</small>
          </RingGauge>
          <div><strong>{habitScore >= 70 ? 'Steady' : 'Recovering'}</strong><small>{weekly.highlight} is your peak day</small></div>
        </div>
      </Card>

      <Card icon={Wallet} title="Accounts" onClick={() => open('Accounts')}>
        <strong className="bento-big">{o.accounts.count} accounts</strong>
        <small className="bento-sub">{privacy ? '••••' : fmtCompact(o.accounts.total, base)}</small>
      </Card>

      <Card icon={Tag} title="Labels" onClick={() => open('labels')}>
        <strong className="bento-big">{o.labels.count}</strong><small className="bento-sub">Editable labels</small>
      </Card>

      <Card icon={Clock3} title="Recurring" onClick={() => open('recurring')}>
        <strong className="bento-big">{o.recurring.count}</strong><small className="bento-sub">Active schedules</small>
      </Card>

      <Card icon={PieChart} title="Categories" onClick={() => open('categories')}>
        <strong className="bento-big">{o.categories.categories}</strong><small className="bento-sub">{o.categories.expense} expense · {o.categories.income} income</small>
      </Card>

      <Card icon={MapPin} title="Places" onClick={() => open('places')}>
        <strong className="bento-big">{o.places.count}</strong><small className="bento-sub">Saved places</small>
      </Card>

      <Card icon={UserRound} title="Person" onClick={() => open('people')}>
        <strong className="bento-big">{o.people.count}</strong><small className="bento-sub">Linked contacts</small>
      </Card>

      <Card icon={Trophy} title="Achievements" onClick={() => open('achievements')}>
        <WavyProgress pct={Math.max(0, goalPct)} color="#7B4028" track="#F3D9CF" height={10} stroke={4} label={`${goalPct}% goal progress`} />
        <small className="bento-sub">{o.achievements.unlocked}/{o.achievements.total} unlocked</small>
      </Card>

      <Card icon={Target} title="Budgets" chevron={false} onClick={() => open('Budgets')} {...swipe}>
        <div className="bento-budget-head"><strong>{budget?.name || 'No budgets'}</strong><ChevronRight /></div>
        <div className="bento-budget-body">
          <RingGauge pct={budget?.pct || 0} size={64} stroke={7} color={budget?.color || '#3949AB'} label="Budget used">
            <b>{budget?.pct || 0}%</b>
          </RingGauge>
          <div>
            <small>Spent {privacy ? '••••' : fmtFull(budget?.spent || 0, base)}</small>
            <small>of {privacy ? '••••' : fmtFull(budget?.limit || 0, base)}</small>
          </div>
        </div>
        <Dots count={Math.max(1, budgets.length)} active={slide % Math.max(1, budgets.length)} />
      </Card>

      <Card icon={Star} title="Reports" onClick={() => open('Trend')}>
        <strong className="bento-big">{o.reports.count} txns</strong>
        <small className="bento-sub">{privacy ? '••••' : fmtCompact(o.reports.total, base)} this month</small>
      </Card>

      <Card icon={Wallet} title="Assets" onClick={() => open('Assets')}>
        <strong className="bento-big">{privacy ? '••••' : usd(o.assets.portfolio)}</strong>
        <small className="bento-sub">{o.assets.types} asset types</small>
      </Card>

      <Card icon={Layers3} title="Bills" onClick={() => open('Bills')}>
        <strong className="bento-big">{o.bills.pending} pending</strong>
        <small className="bento-sub">{o.bills.count} bills · {o.bills.settled} settled</small>
      </Card>

      <Card icon={Wallet} title="Loans" onClick={() => open('Loans')}>
        <strong className="bento-big">{o.loans.lending + o.loans.borrowing}</strong>
        <small className="bento-sub">{privacy ? '••••' : fmtCompact(o.loans.balance, base)} net</small>
      </Card>

      <Card icon={Target} title="Goals" onClick={() => open('Goals')}>
        <strong className="bento-big">{o.goals.active} active</strong>
        <small className="bento-sub">{goalPct}% average completion</small>
        <WavyProgress pct={Math.max(0, Math.min(100, goalPct))} color="#9C28B1" track="#F1DDF3" height={8} stroke={3} />
      </Card>
    </div>
  );
}
