import React from 'react';
import {
  Landmark,
  BarChart3,
  PiggyBank,
  Vault,
  Split,
  Banknote,
  Target,
  Tag,
  TrendingUp,
  CalendarClock,
  Shapes,
  MapPin,
  UserRound,
  UserCog,
  Trophy,
  ArrowDownRight,
  Timer,
  ChartNoAxesColumn,
  Wallet,
  User,
} from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, fmtCompact, fmtShort, fmtThousands } from '../data/demoStore.js';
import { Card, Dots, useSwipe } from './ui.jsx';
import Sparkline from './Sparkline.jsx';

const MASK = '₹••••••';

/* small icon set used inside cards */
const CatIcon = ({ icon }) => {
  if (icon === 'dollar') return <span className="dollar-glyph">$</span>;
  if (icon === 'wallet') return <Wallet />;
  return <User />;
};

function WeeklyBars({ weekly }) {
  return (
    <div className="bars" role="img" aria-label="Spending by weekday">
      {weekly.days.map((d) => (
        <div className="bar-col" key={d.d}>
          <div className="bar-track">
            <div className="bar-fill" style={{ height: `${d.v}%` }} />
          </div>
          <span className={`bar-day${d.d === weekly.highlight ? ' on' : ''}`}>{d.d}</span>
        </div>
      ))}
    </div>
  );
}

function HabitGauge({ score }) {
  const R = 25;
  const C = 2 * Math.PI * R;
  const pct = score / 100;
  // scalloped arc path: 34 small bumps around 62% of the circle
  const bumps = 26;
  const sweep = 360 * 0.62 * pct;
  const startA = 128;
  let d = '';
  for (let i = 0; i <= bumps; i += 1) {
    const a = startA + (sweep * i) / bumps;
    const rad = (a * Math.PI) / 180;
    const r = i % 2 === 0 ? R + 1.7 : R - 1.7;
    const x = 28 + r * Math.cos(rad);
    const y = 28 + r * Math.sin(rad);
    d += i === 0 ? `M${x.toFixed(2)},${y.toFixed(2)}` : `L${x.toFixed(2)},${y.toFixed(2)}`;
  }
  return (
    <div className="gauge" role="img" aria-label={`Habit score ${score} out of 100`}>
      <svg viewBox="0 0 56 56">
        <circle cx="28" cy="28" r={R} fill="none" stroke="#E8F3E4" strokeWidth="4.5" />
        <path d={d} fill="none" stroke="#8BC34A" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
      <span>{score}</span>
    </div>
  );
}

function WavyProgress({ pct }) {
  const W = 100;
  const H = 10;
  const activeW = (W * pct) / 100;
  // sinusoidal wave across the filled portion
  let d = '';
  const steps = 40;
  for (let i = 0; i <= steps; i += 1) {
    const x = (activeW * i) / steps;
    const y = 5 + Math.sin((i / steps) * Math.PI * 4) * 2.6;
    d += i === 0 ? `M${x.toFixed(2)},${y.toFixed(2)}` : `L${x.toFixed(2)},${y.toFixed(2)}`;
  }
  return (
    <svg className="ach-wave" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" aria-hidden="true">
      <line x1="0" y1="5" x2={W} y2="5" stroke="#F5DCE0" strokeWidth="3" strokeLinecap="round" />
      <path d={d} fill="none" stroke="#7B4028" strokeWidth="3" strokeLinecap="round" />
    </svg>
  );
}

export default function BentoGrid() {
  const o = useStore((s) => s.overview);
  const privacy = useStore((s) => s.privacy);
  const budgetSlide = o.budgets.slide;

  const m = (fn, ...args) => (privacy ? MASK : fn(...args));
  const open = (label) => () => demoStore.toast(`${label} — opens in a later step`);
  const goAccounts = () => demoStore.go('accounts');
  const goReports = () => demoStore.go('reports');
  const goBudgets = () => demoStore.go('budgets');
  const goAssets = () => demoStore.go('assets');
  const goBills = () => demoStore.go('billSplitter');
  const goLoans = () => demoStore.go('loans');

  const miniSwipe = useSwipe({ onLeft: demoStore.cycleBudgetBento, onRight: demoStore.cycleBudgetBento });

  return (
    <div className="bento">
      {/* 1 — Accounts */}
      <Card icon={Landmark} title="Accounts" onClick={goAccounts}>
        <div className="card-foot">
          <div className="stat-sub">{o.accounts.count} accounts</div>
          <div className="big-value">{m(fmtCompact, o.accounts.total)}</div>
        </div>
      </Card>

      {/* 2 — Reports */}
      <Card icon={BarChart3} title="Reports" onClick={goReports}>
        <div className="card-foot">
          <div className="stat-sub">{o.reports.count} transactions</div>
          <div className="big-value">{m(fmtCompact, o.reports.total)}</div>
        </div>
      </Card>

      {/* 3 — Budgets (2-slide mini carousel) */}
      <Card
        icon={PiggyBank}
        title="Budgets"
        onClick={goBudgets}
        ariaLabel="Budgets — open budgets overview"
      >
        <div className="mini-carousel" {...miniSwipe}>
          <div className="mini-track" style={{ transform: `translateX(-${budgetSlide * 50}%)` }}>
            <div className="mini-slide">
              <div className="stat-line">
                <span className="stat-num">{o.budgets.count}</span>
                <span className="stat-label">Budgets</span>
              </div>
            </div>
            <div className="mini-slide slide-detail">
              <div className="detail-row">
                <span className="dl">Total</span>
                <span className="dv">{m(fmtShort, o.budgets.detail.total, 1)}</span>
              </div>
              <div className="detail-row">
                <span className="dl">Remaining</span>
                <span className="dv">{m(fmtCompact, o.budgets.detail.remaining)}</span>
              </div>
              <div className="detail-row">
                <span className="dl">Spent</span>
                <span className="dv red">{m(fmtCompact, o.budgets.detail.spent)}</span>
              </div>
            </div>
          </div>
        </div>
        <div className="dots" role="group" aria-label="Budget slides">
          {[0, 1].map((i) => (
            <button
              key={i}
              type="button"
              className={`dot-btn${i === budgetSlide ? ' on' : ''}`}
              aria-label={`Show budget slide ${i + 1}`}
              aria-pressed={i === budgetSlide}
              onClick={(e) => {
                e.stopPropagation();
                demoStore.setIn('overview.budgets.slide', i);
              }}
            />
          ))}
        </div>
      </Card>

      {/* 4 — Assets */}
      <Card icon={Vault} title="Assets" onClick={goAssets}>
        <div className="card-foot">
          <div className="stat-line">
            <span className="stat-num">{o.assets.count}</span>
            <span className="stat-label">Assets</span>
          </div>
          <div className="big-value">{m(fmtCompact, o.assets.total)}</div>
          <div className="muted-label">Total</div>
        </div>
      </Card>

      {/* 5 — Bill Splitter */}
      <Card icon={Split} title="Bill Splitter" onClick={goBills}>
        <div className="card-foot">
          <div className="stat-line">
            <span className="stat-num sm">{o.billSplitter.bills}</span>
            <span className="stat-sub" style={{ fontSize: 13 }}>
              Bills
            </span>
          </div>
          <div className="stat-line">
            <span className="stat-num sm">{o.billSplitter.active}</span>
            <span className="stat-sub" style={{ fontSize: 13 }}>
              Active
            </span>
          </div>
          <div className="big-value" style={{ fontSize: 22 }}>
            {m(fmtThousands, o.billSplitter.total)}
          </div>
          <div className="muted-label">Total</div>
        </div>
      </Card>

      {/* 6 — Loans */}
      <Card icon={Banknote} title="Loans" onClick={goLoans}>
        <div className="card-foot">
          <div className="stat-line">
            <span className="stat-num sm">{o.loans.lending}</span>
            <span className="stat-sub" style={{ fontSize: 13 }}>
              Lending
            </span>
          </div>
          <div className="stat-line">
            <span className="stat-num sm">{o.loans.borrowing}</span>
            <span className="stat-sub" style={{ fontSize: 13 }}>
              Borrowing
            </span>
          </div>
          <div className="big-value" style={{ fontSize: 22 }}>
            {m(fmtCompact, o.loans.balance)}
          </div>
          <div className="muted-label">Loan Balance</div>
        </div>
      </Card>

      {/* 7 — Goals */}
      <Card icon={Target} title="Goals" onClick={open('Goals')}>
        <div className="card-foot">
          <div className="stat-line">
            <span className="stat-num">{o.goals.active}</span>
            <span className="stat-label">Active</span>
          </div>
          <div className="goal-bar">
            <span
              style={{
                width: `${Math.max(
                  4,
                  Math.min(100, (Math.abs(o.goals.progressed) / o.goals.target) * 100),
                )}%`,
              }}
            />
          </div>
          <div className="goal-sub">
            Progress: {m(fmtCompact, o.goals.progressed)} / {m(fmtCompact, o.goals.target)}
          </div>
        </div>
      </Card>

      {/* 8 — Labels */}
      <Card icon={Tag} title="Labels" onClick={open('Labels')}>
        <div className="card-foot">
          <div className="stat-line">
            <span className="stat-num">{o.labels.count}</span>
            <span className="stat-label">Labels</span>
          </div>
          <div className="card-copy" style={{ marginTop: 6 }}>
            You have spent the most on {o.labels.top}, totaling {m(fmtThousands, o.labels.topTotal)}.
          </div>
        </div>
      </Card>

      {/* 9 — Analytics (monthly spending) */}
      <Card icon={TrendingUp} title="Analytics" onClick={goReports}>
        <div className="card-foot">
          <div className="muted-label" style={{ fontSize: 12.5 }}>
            This month spending
          </div>
          <div className="big-value">{m(fmtCompact, o.analyticsMonth.value)}</div>
          <div className="delta-row">
            <TrendingUp aria-hidden="true" />
            +{o.analyticsMonth.deltaPct}% vs last month
          </div>
        </div>
      </Card>

      {/* 10 — Recurring */}
      <Card icon={CalendarClock} title="Recurring" onClick={open('Recurring')}>
        <div className="card-foot">
          <div className="stat-line">
            <span className="stat-num">{o.recurring.active}</span>
            <span className="stat-label">Active</span>
          </div>
          <div className="big-value" style={{ marginTop: 4 }}>
            {m(fmtThousands, o.recurring.monthly)}
          </div>
          <div className="muted-label" style={{ fontSize: 12.5 }}>
            Monthly Payment
          </div>
        </div>
      </Card>

      {/* 11 — Categories */}
      <Card icon={Shapes} title="Categories" onClick={open('Categories')}>
        <div className="cat-body">
          <div className="stat-line">
            <span className="stat-num lg">{o.categories.count}</span>
            <span className="stat-label">Categories</span>
          </div>
          <div className="mini-list">
            {o.categories.top.map((c) => (
              <div className="mini-list-row" key={c.label}>
                <span className="ml-ico" style={{ color: c.color }} aria-hidden="true">
                  <CatIcon icon={c.icon} />
                </span>
                <span className="ml-name">{c.label}</span>
                <span className="ml-val">{m(fmtShort, c.total, 1)}</span>
              </div>
            ))}
          </div>
        </div>
      </Card>

      {/* 12 — Weekly */}
      <Card icon={ChartNoAxesColumn} title="Weekly" onClick={open('Weekly spend')}>
        <div>
          <div className="weekly-split">
            <div>
              <div className="wk-label">This Week</div>
              <div className="wk-val">{m(fmtFullPadded, o.weekly.thisWeek)}</div>
            </div>
            <div>
              <div className="wk-label">Last Week</div>
              <div className="wk-val">{m(fmtFullPadded, o.weekly.lastWeek)}</div>
            </div>
          </div>
          <WeeklyBars weekly={o.weekly} />
        </div>
      </Card>

      {/* 13 — Last 30 days */}
      <Card icon={TrendingUp} title="Last 30 Days" chevron={false} onClick={open('Last 30 days')}>
        <div style={{ marginTop: 10 }}>
          <div className="spark-metric">
            <span className="spark-value">{m(fmtThousands, o.last30.total)}</span>
            <span className="spark-badge" aria-hidden="true">
              <ArrowDownRight />
            </span>
            <span className="spark-delta">{o.last30.deltaPct}%</span>
          </div>
          <Sparkline points={o.last30.series} />
        </div>
      </Card>

      {/* 14 — Places */}
      <Card icon={MapPin} title="Places" onClick={open('Places')}>
        <div className="card-foot">
          <div className="stat-line">
            <span className="stat-num">{o.places.count}</span>
            <span className="stat-label">Places</span>
          </div>
          <div className="card-copy" style={{ marginTop: 6 }}>
            You have spent the most at {o.places.top}, totaling {m(fmtThousands, o.places.topTotal)}.
          </div>
        </div>
      </Card>

      {/* 15 — Person */}
      <Card icon={UserRound} title="Person" onClick={open('People')}>
        <div className="card-foot">
          <div className="stat-line">
            <span className="stat-num">{o.person.count}</span>
            <span className="stat-label">Person</span>
          </div>
          <div className="card-copy" style={{ marginTop: 6 }}>
            You have spent the most with {o.person.top}, totaling {m(fmtThousands, o.person.topTotal)}.
          </div>
        </div>
      </Card>

      {/* 16 — Analytics (habit) */}
      <Card icon={UserCog} title="Analytics" chevron={false} onClick={open('Habit analytics')}>
        <div className="habit-highlight">
          <Timer aria-hidden="true" />
          {o.habit.streakDays} days under average!
        </div>
        <div className="gauge-row">
          <HabitGauge score={o.habit.score} />
          <div className="legend">
            {o.habit.legend.map((l, i) => (
              <div className="legend-row" key={`${l.label}-${i}`}>
                <i style={{ background: l.color }} />
                {l.label}
              </div>
            ))}
          </div>
        </div>
      </Card>

      {/* 17 — Achievements */}
      <Card
        icon={Trophy}
        title="Achievements"
        chevron={false}
        className="achievements"
        onClick={open('Achievements')}
      >
        <div className="ach-top">
          <div className="ach-metric">
            <span className="n">{o.achievements.unlocked}</span>
            <span className="t">/ {o.achievements.total} unlocked</span>
          </div>
          <div className="ach-pct">{o.achievements.pct}% completed</div>
          <WavyProgress pct={o.achievements.pct} />
        </div>
        <div className="ach-footer">
          <span className="ach-badge" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="9" />
              <path d="m8.5 12.2 2.4 2.4 4.6-4.9" />
            </svg>
          </span>
          <span className="ach-meta">
            <span className="ek">Last earned</span>
            <span className="et">{o.achievements.last.title}</span>
          </span>
          <span className="ach-date">{o.achievements.last.date}</span>
        </div>
      </Card>
    </div>
  );
}

/* weekly values need two fixed decimals: ₹82.00 */
function fmtFullPadded(v) {
  return `₹${v.toFixed(2)}`;
}
