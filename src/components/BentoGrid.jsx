import React from 'react';
import {
  ArrowUpRight,
  BarChart3,
  Building2,
  CalendarClock,
  ChartNoAxesCombined,
  ChevronRight,
  CreditCard,
  Landmark,
  MapPin,
  PiggyBank,
  Repeat2,
  Shapes,
  Tag,
  Target,
  TrendingUp,
  Trophy,
  UserRound,
  Users,
} from 'lucide-react';

import { Card, Dots, useSwipe } from './ui.jsx';
import { InteractiveChart, WavyProgress } from './charts/Interactive.jsx';
import Sparkline from './Sparkline.jsx';
import { demoStore, fmtFull, fmtCompact } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { overview, weeklySeries, last30Series, budgetCards } from '../data/derive.js';

const COLLECTION = {
  labels: 'labels', recurring: 'recurring', categories: 'categories',
  places: 'places', people: 'people', achievements: 'achievements',
};

function WeeklyBars({ weekly, base }) {
  const W = 300;
  const H = 92;
  const padL = 6;
  const padR = 6;
  const padT = 6;
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
              const curH = Math.max(8, (d.pct / 100) * plotH);
              const isActive = active === i || (!active && d.d === weekly.highlight);
              return (
                <g key={d.date}>
                  <circle cx={x} cy={H - padB - 5} r="8" fill={isActive ? '#FFB59A' : '#7B4028'} />
                  <rect
                    x={x - bw * 0.17}
                    y={H - padB - curH}
                    width={bw * 0.34}
                    height={curH}
                    rx={bw * 0.17}
                    fill={isActive ? '#FFB59A' : '#7B4028'}
                  />
                  <text x={x} y={H - 3} textAnchor="middle" fontSize="8" fontWeight={isActive ? 800 : 600} fill={isActive ? '#7B4028' : '#8B746B'}>{d.d}</text>
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
  }));
  const base = useStore((s) => s.profile.baseCurrency);
  const privacy = useStore((s) => s.privacy);
  const slide = useStore((s) => s.budgetsUi.bentoSlide);
  const swipe = useSwipe({ onLeft: demoStore.cycleBudgetBento, onRight: demoStore.cycleBudgetBento });
  const { o, weekly, last30, budgets } = data;
  const fmt = (v) => privacy ? '••••' : fmtFull(v, base);
  const compact = (v) => privacy ? '••••' : fmtCompact(v, base);
  const goalPct = o.goals.target ? Math.round((o.goals.progressed / o.goals.target) * 100) : 0;
  const topCategories = (o.categories.top || []).slice(0, 3);

  const open = (label) => {
    if (COLLECTION[label]) return demoStore.openCollection(COLLECTION[label]);
    if (label === 'Overview' || label === 'Customize') return demoStore.openLayout();
    if (label === 'Weekly' || label === 'Last 30 days' || label === 'Trend' || label === 'Analytics') return demoStore.go('reports');
    if (label === 'Budgets') return demoStore.go('budgets');
    if (label === 'Goals') return demoStore.go('goals');
    if (label === 'Assets') return demoStore.go('assets');
    if (label === 'Bill Splitter' || label === 'Bills') return demoStore.go('billSplitter');
    if (label === 'Loans') return demoStore.go('loans');
    if (label === 'Accounts') return demoStore.go('accounts');
    if (label === 'Reports') return demoStore.go('reports');
    return demoStore.openProfile();
  };

  return (
    <div className="bento-grid">
      <Card icon={Landmark} title="Accounts" onClick={() => open('Accounts')}>
        <div className="bento-foot">
          <span className="bento-count">{o.accounts.count} accounts</span>
          <strong className="bento-number">{compact(o.accounts.total)}</strong>
        </div>
      </Card>

      <Card icon={ChartNoAxesCombined} title="Reports" onClick={() => open('Reports')}>
        <div className="bento-foot">
          <span className="bento-count">{o.reports.count} transactions</span>
          <strong className="bento-number">{compact(o.reports.total)}</strong>
        </div>
      </Card>

      <Card icon={PiggyBank} title="Budgets" onClick={() => open('Budgets')} {...swipe}>
        <div className="bento-foot">
          <span className="bento-count">{budgets.length} Budgets</span>
          <strong className="bento-number">{compact(budgets.reduce((sum, b) => sum + (b.limit || 0), 0))}</strong>
        </div>
        <Dots count={Math.max(1, budgets.length)} active={slide % Math.max(1, budgets.length)} />
      </Card>

      <Card icon={Building2} title="Assets" onClick={() => open('Assets')}>
        <div className="bento-foot">
          <span className="bento-count">{o.assets.count} Assets</span>
          <strong className="bento-number">{compact(o.assets.portfolio)}</strong>
          <small className="bento-sub">Total</small>
        </div>
      </Card>

      <Card icon={Users} title="Bill Splitter" onClick={() => open('Bill Splitter')}>
        <div className="bento-stacked">
          <strong className="bento-number sm">{o.bills.count} Bills</strong>
          <strong className="bento-number sm">{o.bills.pending} Active</strong>
          <strong className="bento-number">{compact(o.billSplitter.total)}</strong>
          <small className="bento-sub">Total</small>
        </div>
      </Card>

      <Card icon={CreditCard} title="Loans" onClick={() => open('Loans')}>
        <div className="bento-stacked">
          <strong className="bento-number sm">{o.loans.lending} Lending</strong>
          <strong className="bento-number sm">{o.loans.borrowing} Borrowing</strong>
          <strong className="bento-number">{compact(o.loans.balance)}</strong>
          <small className="bento-sub">Loan Balance</small>
        </div>
      </Card>

      <Card icon={Target} title="Goals" onClick={() => open('Goals')}>
        <div className="bento-foot">
          <span className="bento-count">{o.goals.active} Active</span>
          <WavyProgress pct={Math.max(0, Math.min(100, goalPct))} color="#D9C8C0" track="#F2E6E0" height={8} stroke={3} />
          <small className="bento-sub">Progress: {fmt(o.goals.progressed)} / {fmt(o.goals.target)}</small>
        </div>
      </Card>

      <Card icon={Tag} title="Labels" onClick={() => open('labels')}>
        <div className="bento-foot">
          <strong className="bento-number">{o.labels.count} Labels</strong>
          <small className="bento-sub">You have spent the most on {o.labels.top}, totaling {fmt(o.labels.topTotal)}.</small>
        </div>
      </Card>

      <Card icon={TrendingUp} title="Analytics" onClick={() => open('Analytics')}>
        <div className="bento-foot">
          <span className="bento-label">This month spending</span>
          <strong className="bento-number">{compact(o.analyticsMonth.value)}</strong>
          <small className="bento-trend">↗ {o.analyticsMonth.deltaPct >= 0 ? '+' : ''}{o.analyticsMonth.deltaPct}% vs last month</small>
        </div>
      </Card>

      <Card icon={CalendarClock} title="Recurring" onClick={() => open('recurring')}>
        <div className="bento-foot">
          <strong className="bento-number sm">{o.recurring.active} Active</strong>
          <strong className="bento-number">{compact(o.recurring.monthly)}</strong>
          <small className="bento-sub">Monthly Payment</small>
        </div>
      </Card>

      <Card icon={Shapes} title="Categories" onClick={() => open('categories')}>
        <div className="bento-foot">
          <strong className="bento-number sm">{o.categories.categories} Categories</strong>
          <div className="bento-list">
            {topCategories.map((c) => (
              <div key={c.label} className="bento-list-row"><i style={{ background: c.color }} /><span>{c.label}</span><b>{fmt(c.total)}</b></div>
            ))}
          </div>
        </div>
      </Card>

      <Card icon={BarChart3} title="Weekly" chevron={false} onClick={() => open('Weekly')}>
        <div className="bento-weekly-head">
          <span>This Week<b>{compact(weekly.thisWeek)}</b></span>
          <span>Last Week<b>{compact(weekly.lastWeek)}</b></span>
        </div>
        <WeeklyBars weekly={weekly} base={base} />
      </Card>

      <Card icon={ArrowUpRight} title="Last 30 days" chevron={false} onClick={() => open('Last 30 days')}>
        <Sparkline data={last30} />
      </Card>

      <Card icon={MapPin} title="Places" onClick={() => open('places')}>
        <div className="bento-foot">
          <strong className="bento-number">{o.places.count} Places</strong>
          <small className="bento-sub">You have spent the most at {o.places.top}, totaling {fmt(o.places.topTotal)}.</small>
        </div>
      </Card>

      <Card icon={UserRound} title="Person" onClick={() => open('people')}>
        <div className="bento-foot">
          <strong className="bento-number">{o.people.count} Person</strong>
          <small className="bento-sub">You have spent the most with {o.people.top}, totaling {fmt(o.people.topTotal)}.</small>
        </div>
      </Card>

      <Card icon={Trophy} title="Achievements" onClick={() => open('achievements')}>
        <div className="bento-foot">
          <strong className="bento-number">{o.achievements.unlocked} / {o.achievements.total} unlocked</strong>
          <small className="bento-sub">{o.achievements.pct}% completed</small>
          <WavyProgress pct={o.achievements.pct} color="#7B4028" track="#F3D9CF" height={10} stroke={4} label={`${o.achievements.pct}% complete`} />
          <div className="bento-achievement">
            <span className="bento-achievement-badge">✓</span>
            <div><small>LAST EARNED</small><strong>{o.achievements.last.title}</strong></div>
            <span>{o.achievements.last.date}</span>
          </div>
        </div>
      </Card>
    </div>
  );
}
