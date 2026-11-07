import React from 'react';
import {
  Wallet,
  Plus,
  Trash2,
  CalendarDays,
  Sparkles,
  Pencil,
  TrendingUp,
  Landmark,
  PiggyBank,
  DollarSign,
} from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, usd } from '../data/demoStore.js';
import { budgets as budgetData } from '../data/step2Data.js';
import { SubHeader, WavyProgress, ExitDemoPill } from '../components/step2/ui2.jsx';

/* pace chart: expense line, ideal pace, limit */
function PaceChart({ total, spentPct }) {
  const W = 300;
  const H = 200;
  const padL = 30;
  const padR = 30;
  const padT = 10;
  const padB = 30;
  const plotW = W - padL - padR;
  const plotH = H - padT - padB;
  const maxV = 4000;
  const yTicks = [4000, 3000, 2000, 1000, 0];
  const xLabels = [
    { frac: 0, label: 'Oct 25' },
    { frac: 0.33, label: 'Nov 4' },
    { frac: 0.66, label: '14' },
    { frac: 1, label: '24' },
  ];
  const yV = (v) => padT + ((maxV - v) / maxV) * plotH;
  const xF = (f) => padL + f * plotW;
  const limitY = yV(total);

  return (
    <svg className="pace-svg" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Budget pace chart">
      {yTicks.map((t) => (
        <g key={t}>
          <line x1={padL} x2={W - padR} y1={yV(t)} y2={yV(t)} stroke="#F1E7E2" strokeWidth="1" />
          <text x={padL - 7} y={yV(t) + 3.4} textAnchor="end" fontSize="9.5" fontWeight="600" fill="#8A756B">
            {t === 0 ? '0' : `${t / 1000}K`}
          </text>
        </g>
      ))}

      {/* limit */}
      <line x1={padL} x2={W - padR} y1={limitY} y2={limitY} stroke="#C62828" strokeWidth="1.8" strokeDasharray="7 5" />
      <text x={W - padR + 2} y={limitY + 3.4} fontSize="9.5" fontWeight="800" fill="#C62828">
        Limit
      </text>

      {/* ideal pace */}
      <line x1={xF(0)} y1={yV(0)} x2={xF(1)} y2={limitY} stroke="#9E9E9E" strokeWidth="1.6" strokeDasharray="5 5" />

      {/* expense */}
      <line
        x1={xF(0)}
        y1={yV(0)}
        x2={xF(0.2)}
        y2={yV(0) - 1.5}
        stroke="#3949AB"
        strokeWidth="2.5"
        strokeLinecap="round"
      />

      {xLabels.map((x) => (
        <text key={x.label} x={xF(x.frac)} y={H - 8} textAnchor="middle" fontSize="10" fontWeight="600" fill="#5A463E">
          {x.label}
        </text>
      ))}
    </svg>
  );
}

function ChipIcon({ icon }) {
  if (icon === 'dollar') return <DollarSign aria-hidden="true" />;
  return null;
}

function RouteIcon({ tone }) {
  if (tone === 'teal') return <Landmark className="route-ico teal" aria-hidden="true" />;
  if (tone === 'piggy') return <PiggyBank className="route-ico pink" aria-hidden="true" />;
  return <Landmark className="route-ico teal" aria-hidden="true" />;
}

export default function BudgetDetailView() {
  const params = useStore((s) => s.route.params);
  const showOnHome = useStore((s) => s.budgetsUi.showOnHome);
  const budget = budgetData.find((b) => b.id === params.id) || budgetData[0];
  const d = budget.detail;

  return (
    <div className="view">
      <SubHeader
        title="Budget"
        center={false}
        right={
          <>
            <ExitDemoPill />
            <button
              type="button"
              className="icon-btn dark"
              aria-label="Add transaction"
              onClick={() => demoStore.toast('Add transaction to this budget')}
            >
              <Plus />
            </button>
            <button
              type="button"
              className="icon-btn trash"
              aria-label="Delete budget"
              onClick={() => demoStore.toast('Delete budget?')}
            >
              <Trash2 />
            </button>
          </>
        }
      />

      {/* hero summary */}
      <section className="bd-hero">
        <div className="bd-hero-top">
          <span className="bd-tile" style={{ background: budget.tile, color: budget.tileFg }}>
            <Wallet />
          </span>
          <div className="bd-hero-mid">
            <div className="bd-name">{budget.name}</div>
            <div className="bc2-chips">
              <span className="mc" style={{ background: budget.accentSoft, color: budget.accent }}>
                Monthly
              </span>
              <span className="mc" style={{ background: budget.accentSoft, color: budget.accent }}>
                {budget.mode}
              </span>
              <span className="mc" style={{ background: budget.autoChip.bg, color: budget.autoChip.fg }}>
                {budget.autoChip.icon === 'auto' ? <Sparkles className="mc-ico" /> : null}
                {budget.autoChip.label}
              </span>
            </div>
          </div>
          <span className="status-pill good">{budget.status}</span>
        </div>

        <div className="bd-usage">
          <span className="bd-used">{budget.pct}% Used</span>
          <span className="bd-of">
            {usd(budget.spent)} of {usd(budget.total)}
          </span>
        </div>

        <WavyProgress pct={budget.pct} color={budget.accent} track="#DCE0F5" height={11} stroke={5} />

        <div className="bd-remain-split">
          <div>
            <div className="bd-small-label">Remaining</div>
            <div className="bd-amount">{usd(budget.remaining)}</div>
          </div>
          <div className="right">
            <div className="bd-small-label">Spent</div>
            <div className="bd-amount">{usd(budget.spent)}</div>
          </div>
        </div>

        <div className="bd-daily">
          <CalendarDays aria-hidden="true" />
          You can spend ${budget.perDay}/day for {budget.daysLeft} more days
        </div>
      </section>

      {/* show budget toggle */}
      <section className="bd-toggle-card">
        <div>
          <div className="bd-toggle-title">Show Budget</div>
          <div className="bd-toggle-sub">Track this budget on home screen</div>
        </div>
        <button
          type="button"
          role="switch"
          aria-checked={showOnHome}
          aria-label="Show budget on home screen"
          className={`m3-switch${showOnHome ? ' on' : ''}`}
          onClick={() => demoStore.toggleShowBudget()}
        >
          <span className="m3-thumb" />
        </button>
      </section>

      {/* pace chart */}
      <section className="bd-card">
        <h3 className="bd-card-title">Budget Progress</h3>
        <PaceChart total={budget.total} spentPct={budget.pct} />
        <div className="pace-legend">
          <span className="legend-item">
            <i className="swatch blue" /> Expense
          </span>
          <span className="legend-item">
            <i className="swatch dashed-grey" /> Ideal Pace
          </span>
          <span className="legend-item">
            <i className="swatch red" /> Limit
          </span>
        </div>
      </section>

      {/* category breakdown */}
      <section className="bd-card">
        <h3 className="bd-card-title">Category Breakdown</h3>
        <div className="bd-cat-row">
          <span className="bd-cat-ico">
            <Landmark />
          </span>
          <div className="bd-cat-mid">
            <div className="bd-cat-top">
              <span className="bd-cat-name">{d.category.label}</span>
              <span className="bd-cat-figures">
                {d.category.pct}% <b>{d.category.amount}</b>
              </span>
            </div>
            <div className="bd-cat-track">
              <span style={{ width: `${d.category.pct}%` }} />
            </div>
          </div>
        </div>
      </section>

      {/* recent transactions */}
      <h3 className="bd-section-title">Recent transactions</h3>
      <div className="tx-list bd">
        {d.recent.map((t) => (
          <button
            type="button"
            className="tx s2"
            key={t.id}
            onClick={() => demoStore.toast(`${t.title} — transaction details`)}
          >
            <span className="tx-ico s2" style={{ background: '#E53935', color: '#fff' }}>
              {t.icon === 'trend' ? <TrendingUp /> : <Landmark />}
            </span>
            <span className="tx-mid">
              <span className="tx-title s2" style={{ display: 'block' }}>
                {t.title}
              </span>
              <span className="tx-meta s2">
                {t.time} • {t.when} •{' '}
                <span className="tx-route">
                  <RouteIcon tone={t.accountTone} />
                  {t.account}
                </span>
              </span>
              <span className="chips s2">
                {t.chips.map((c, i) => (
                  <span className="chip s2" key={`${t.id}-${i}`} style={{ background: c.bg, color: c.fg }}>
                    <ChipIcon icon={c.icon} />
                    {c.label}
                  </span>
                ))}
              </span>
            </span>
            <span className="tx-amt" style={{ color: '#D32F2F' }}>
              {t.amount}
            </span>
          </button>
        ))}
      </div>

      <button
        type="button"
        className="edit-fab"
        onClick={() => demoStore.toast('Edit budget')}
      >
        <Pencil />
        Edit
      </button>
    </div>
  );
}
