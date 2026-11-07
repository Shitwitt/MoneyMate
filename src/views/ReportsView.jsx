import React from 'react';
import {
  ChevronRight,
  ChevronDown,
  ChevronUp,
  Lock,
  Sparkles,
  PiggyBank,
  CalendarDays,
  ReceiptText,
  TrendingUp,
  ChartColumn,
  ChartSpline,
  ChartPie,
  Target,
  Banknote,
  Trophy,
  Network,
  BarChart3,
} from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, usd } from '../data/demoStore.js';
import { reportMonths, reportByMonth, financialReports } from '../data/step2Data.js';
import { SubHeader, ExitDemoPill } from '../components/step2/ui2.jsx';

const DIMENSIONS = ['Category', 'Account', 'Label', 'Person', 'Places'];
const REPORT_ICONS = {
  bars: ChartColumn,
  pie: ChartPie,
  target: Target,
  cash: Banknote,
  trophy: Trophy,
};

/* ---------------- chart ---------------- */

function ReportsChart({ mode, data }) {
  const W = 300;
  const H = 186;
  const padL = 34;
  const padR = 10;
  const padT = 10;
  const padB = 24;
  const plotW = W - padL - padR;
  const plotH = H - padT - padB;
  const maxV = 8000;
  const yTicks = [8000, 6000, 4000, 2000, 0];
  const xTicks = [1, 6, 11, 16, 21, 26];
  const xD = (d) => padL + ((d - 1) / 29) * plotW;
  const yV = (v) => padT + ((maxV - v) / maxV) * plotH;
  const baseY = yV(0);

  if (mode === 'bars') {
    const incomeH = (data.income / maxV) * plotH;
    return (
      <svg className="rp-chart" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Income and expense bars">
        {yTicks.map((t) => (
          <g key={t}>
            <line x1={padL} x2={W - padR} y1={yV(t)} y2={yV(t)} stroke="#F1E7E2" strokeWidth="1" />
            <text x={padL - 8} y={yV(t) + 3.5} textAnchor="end" fontSize="9.5" fontWeight="600" fill="#8A756B">
              {t === 0 ? '0' : `${t / 1000}K`}
            </text>
          </g>
        ))}
        {/* green income bar at day 1 */}
        <rect
          x={xD(1) - 5}
          y={baseY - incomeH}
          width="9"
          height={incomeH}
          rx="3.5"
          fill="#4CAF50"
        />
        {/* tiny red expense tick at day 3 */}
        <rect x={xD(3) - 4} y={baseY - 5} width="8" height="5" rx="2" fill="#E53935" />
        {xTicks.map((d) => (
          <g key={d}>
            <line x1={xD(d)} x2={xD(d)} y1={baseY} y2={baseY + 4} stroke="#D9CCC5" strokeWidth="1" />
            <text x={xD(d)} y={H - 7} textAnchor="middle" fontSize="9.5" fontWeight="600" fill="#8A756B">
              {d}
            </text>
          </g>
        ))}
      </svg>
    );
  }

  // line mode: green node line at 0 with a spike at day 1, hollow nodes each day
  const spikeY = yV(data.income);
  const nodes = Array.from({ length: 30 }, (_, i) => i + 1);
  return (
    <svg className="rp-chart" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Income and expense line chart">
      {yTicks.map((t) => (
        <g key={t}>
          <line x1={padL} x2={W - padR} y1={yV(t)} y2={yV(t)} stroke="#F1E7E2" strokeWidth="1" />
          <text x={padL - 8} y={yV(t) + 3.5} textAnchor="end" fontSize="9.5" fontWeight="600" fill="#8A756B">
            {t === 0 ? '0' : `${t / 1000}K`}
          </text>
        </g>
      ))}

      {/* dashed smoothing curve day 1 -> 4 */}
      <path
        d={`M${xD(1)},${spikeY} C${xD(1.6)},${spikeY + 30} ${xD(2.4)},${baseY - 6} ${xD(4)},${baseY}`}
        fill="none"
        stroke="#A5D6A7"
        strokeWidth="2"
        strokeDasharray="4 4"
        strokeLinecap="round"
      />

      {/* green line */}
      <path
        d={`M${xD(1)},${spikeY} L${xD(1)},${spikeY} L${xD(2)},${baseY} L${xD(30)},${baseY}`}
        fill="none"
        stroke="#4CAF50"
        strokeWidth="2.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />

      {/* hollow green nodes on every day */}
      {nodes.map((d) => (
        <circle
          key={d}
          cx={xD(d)}
          cy={baseY}
          r={d === 1 ? 4.2 : 3.4}
          fill="#FDF3EE"
          stroke="#4CAF50"
          strokeWidth="1.8"
        />
      ))}

      {/* income node at top of spike */}
      <circle cx={xD(1)} cy={spikeY} r="4.4" fill="#FDF3EE" stroke="#4CAF50" strokeWidth="2" />
      {/* red expense node at day 1 */}
      <circle cx={xD(1)} cy={baseY - 3} r="3.6" fill="#FDF3EE" stroke="#E53935" strokeWidth="2" />

      {xTicks.map((d) => (
        <text key={d} x={xD(d)} y={H - 7} textAnchor="middle" fontSize="9.5" fontWeight="600" fill="#8A756B">
          {d}
        </text>
      ))}
    </svg>
  );
}

/* ---------------- donut ---------------- */

function DonutChart({ slices, size = 240 }) {
  const stroke = 50;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  let acc = 0;
  const total = slices.reduce((s, x) => s + x.pct, 0) || 100;

  return (
    <div className="donut-wrap" style={{ width: size, height: size }}>
      <svg viewBox={`0 0 ${size} ${size}`} role="img" aria-label="Category breakdown donut">
        {slices.map((s) => {
          const len = (s.pct / total) * c;
          const el = (
            <circle
              key={s.label}
              cx={size / 2}
              cy={size / 2}
              r={r}
              fill="none"
              stroke={s.color}
              strokeWidth={stroke}
              strokeDasharray={`${len} ${c - len}`}
              strokeDashoffset={-acc}
              transform={`rotate(-90 ${size / 2} ${size / 2})`}
            />
          );
          acc += len;
          return el;
        })}
        {/* leader line to the label underneath */}
        <path
          d={`M${size * 0.62},${size * 0.9} q 8,12 -6,16`}
          fill="none"
          stroke="#00897B"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
      </svg>
    </div>
  );
}

/* ---------------- view ---------------- */

export default function ReportsView() {
  const ui = useStore((s) => s.reportsUi);
  const data = reportByMonth[ui.month];
  const ins = data.insights;
  const primary = data.donut[0];

  const typeLabel = ui.type;

  return (
    <div className="view">
      <SubHeader
        title="Reports"
        center={false}
        right={
          <>
            <ExitDemoPill />
            <button
              type="button"
              className="icon-btn"
              aria-label="Filter reports"
              onClick={() => demoStore.toast('Report filters')}
            >
              <Network />
            </button>
          </>
        }
      />

      {/* month strip */}
      <div className="month-strip" role="tablist" aria-label="Report month">
        {reportMonths.map((m) => (
          <button
            key={m}
            type="button"
            role="tab"
            aria-selected={ui.month === m}
            className={`month-pill${ui.month === m ? ' on' : ''}`}
            onClick={() => demoStore.setReportMonth(m)}
          >
            {m}
          </button>
        ))}
      </div>

      {/* total balance */}
      <section className="rp-card">
        <div className="rp-card-head">
          <span className="rp-title-lg">Total balance</span>
          <span className="rp-title-lg">{usd(data.totalBalance)}</span>
        </div>

        <div className="rp-split">
          <div className="rp-sub income">
            <div className="rp-sub-top">
              <span className="rp-sub-label">
                <i className="dot green" />
                Income
              </span>
              <span className="rp-sub-delta pos">
                +{data.income.pct}%
                <TrendingUp aria-hidden="true" />
              </span>
            </div>
            <div className="rp-sub-value">{usd(data.income.value)}</div>
            <div className="rp-sub-was">was {usd(data.income.prev)}</div>
          </div>

          <div className="rp-sub expense">
            <div className="rp-sub-top">
              <span className="rp-sub-label">
                <i className="dot red" />
                Expense
              </span>
              <span className="rp-sub-delta neg">
                +{data.expense.pct}%
                <TrendingUp aria-hidden="true" />
              </span>
            </div>
            <div className="rp-sub-value">{usd(data.expense.value)}</div>
            <div className="rp-sub-was">was {usd(data.expense.prev)}</div>
          </div>
        </div>
      </section>

      {/* quick insights */}
      <section className="rp-card">
        <div className="rp-card-head">
          <span className="rp-head-left">
            <Sparkles aria-hidden="true" />
            Quick Insights
          </span>
          <span className="rp-badge">{data.txCount} Transactions</span>
        </div>

        <div className="rp-insights">
          <div className="rp-tile">
            <div className="rp-tile-head">
              <span className="rp-tile-ico green">
                <PiggyBank />
              </span>
              Savings Rate
            </div>
            <div className="rp-tile-main green">{ins.savingsRate.pct}</div>
            <div className="rp-tile-sub">{ins.savingsRate.amount}</div>
          </div>

          <div className="rp-tile">
            <div className="rp-tile-head">
              <span className="rp-tile-ico sand">
                <CalendarDays />
              </span>
              Avg. Daily
            </div>
            <div className="rp-tile-main">{ins.avgDaily.value}</div>
            <div className="rp-tile-sub">{ins.avgDaily.perDay}</div>
          </div>

          <div className="rp-tile">
            <div className="rp-tile-head">
              <span className="rp-tile-ico sand">
                <ReceiptText />
              </span>
              Average Transaction
            </div>
            <div className="rp-tile-main">{ins.avgTransaction.value}</div>
            <div className="rp-tile-sub">{ins.avgTransaction.sub}</div>
          </div>

          <div className="rp-tile">
            <div className="rp-tile-head">
              <span className="rp-tile-ico rose">
                <TrendingUp />
              </span>
              Peak Spending Day
            </div>
            <div className="rp-tile-main sm">{ins.peakDay.label}</div>
            <div className="rp-tile-sub danger">{ins.peakDay.amount}</div>
          </div>
        </div>

        <div className="rp-banner teal">
          <span className="rp-banner-ico">
            <BarChart3 />
          </span>
          <div className="rp-banner-mid">
            <span className="rp-banner-label">Top Category</span>
            <span className="rp-banner-title">{ins.topCategory.name}</span>
          </div>
          <div className="rp-banner-right">
            <span className="rp-banner-amount">{ins.topCategory.amount}</span>
            <span className="rp-pill teal">{ins.topCategory.pct}</span>
          </div>
        </div>

        <div className="rp-banner peach">
          <span className="rp-banner-ico green">
            <ChartSpline />
          </span>
          <div className="rp-banner-mid">
            <span className="rp-banner-label">Largest Expense</span>
            <span className="rp-banner-title">{ins.largest.title}</span>
            <span className="rp-banner-date">{ins.largest.date}</span>
          </div>
          <span className="rp-banner-amount danger">{ins.largest.amount}</span>
        </div>
      </section>

      {/* chart card */}
      <section className="rp-card">
        <div className="rp-card-head">
          <span className="rp-head-simple">Reports</span>
          <div className="seg-toggle" role="group" aria-label="Chart type">
            <button
              type="button"
              className={`seg-btn${ui.chartMode === 'bars' ? ' on' : ''}`}
              aria-pressed={ui.chartMode === 'bars'}
              aria-label="Bar chart"
              onClick={() => demoStore.setChartMode('bars')}
            >
              <ChartColumn />
            </button>
            <button
              type="button"
              className={`seg-btn${ui.chartMode === 'line' ? ' on' : ''}`}
              aria-pressed={ui.chartMode === 'line'}
              aria-label="Line chart"
              onClick={() => demoStore.setChartMode('line')}
            >
              <ChartSpline />
            </button>
          </div>
        </div>

        <ReportsChart mode={ui.chartMode} data={data.bars} />

        <div className="chart-legend">
          <span className="legend-item">
            <i className="dot red" /> Expense
          </span>
          <span className="legend-item">
            <i className="dot green" /> Income
          </span>
        </div>
      </section>

      {/* filters */}
      <div className="filter-row">
        <button type="button" className="filter-btn" onClick={() => demoStore.toggleReportType()}>
          {typeLabel}
          <ChevronDown aria-hidden="true" />
        </button>

        <button
          type="button"
          className="filter-btn"
          onClick={() => demoStore.toggleCategoryMenu()}
          aria-expanded={ui.menuOpen}
        >
          {ui.dimension}
          <ChevronDown aria-hidden="true" />
        </button>

        {ui.menuOpen ? (
          <>
            <button
              type="button"
              className="menu-scrim"
              aria-label="Close menu"
              onClick={() => demoStore.toggleCategoryMenu()}
            />
            <div className="dimension-menu" role="menu">
              {DIMENSIONS.map((d) => {
                const active = d === ui.dimension;
                const locked = d !== 'Category';
                return (
                  <button
                    key={d}
                    type="button"
                    role="menuitem"
                    className={`dimension-item${active ? ' active' : ''}`}
                    onClick={() => demoStore.setDimension(d)}
                  >
                    {d}
                    {locked ? <Lock className="lock" aria-hidden="true" /> : null}
                  </button>
                );
              })}
            </div>
          </>
        ) : null}
      </div>

      {/* donut */}
      <div className="donut-block">
        <DonutChart slices={data.donut} />
        <div className="donut-caption">
          <span>{primary.label}</span>
          <span>{data.donut.length === 1 ? '100%' : `${primary.pct}%`}</span>
        </div>
      </div>

      {/* breakdown accordion */}
      <div className="acc-head">
        <span>{typeLabel}</span>
        <button type="button" className="acc-toggle" onClick={() => demoStore.toggleDonut()} aria-expanded={ui.donutExpanded}>
          {ui.donutExpanded ? <ChevronDown /> : <ChevronUp />}
          {primary.amount}
        </button>
      </div>

      {ui.donutExpanded
        ? data.donut.map((s) => (
            <div className="breakdown-banner" key={s.label}>
              <span className="bb-ico">
                <BarChart3 />
              </span>
              <div className="bb-mid">
                <span className="bb-title">
                  {s.label} ({s.pct.toFixed(1)}%)
                </span>
                <span className="bb-sub">1 transaction</span>
                <span className="bb-italic">Includes sub-categories</span>
              </div>
              <span className="bb-amount">{s.amount}</span>
            </div>
          ))
        : null}

      {/* financial reports directory */}
      <h3 className="dir-heading">Financial Reports</h3>
      <div className="dir-card">
        {financialReports.map((r) => {
          const Icon = REPORT_ICONS[r.icon] || ChartColumn;
          return (
            <button
              type="button"
              className="dir-row"
              key={r.id}
              onClick={() => demoStore.toast(`${r.title} — report detail in a later step`)}
            >
              <span className="dir-ico">
                <Icon />
              </span>
              <span className="dir-mid">
                <span className="dir-title">{r.title}</span>
                <span className="dir-desc">{r.desc}</span>
              </span>
              <ChevronRight className="dir-chev" aria-hidden="true" />
            </button>
          );
        })}
      </div>

      <p className="report-note">
        <b>*Note</b> Overview details show only income and expense transactions from included
        accounts. Excluded accounts and transfer transactions are not counted towards totals or
        reports. Initial account balances can be viewed in Accounts section.
      </p>
    </div>
  );
}
