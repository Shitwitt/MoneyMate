import React, { useEffect, useState } from 'react';
import {
  BarChart3,
  ChevronDown,
  Filter,
  PieChart,
  Plus,
  Sparkles,
  Wallet,
} from 'lucide-react';

import { SubHeader } from '../components/step2/ui2.jsx';
import { InteractiveChart, ChartTooltipCard, DonutChart, RingGauge, WavyProgress } from '../components/charts/Interactive.jsx';
import { demoStore, fmtExact, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { reportMonths, reportsData } from '../data/derive.js';
import { financialReports } from '../data/step2Data.js';

const DIMENSIONS = ['Category', 'Account', 'Label', 'Person', 'Places'];
const W = 320;
const H = 184;
const PAD = { l: 34, r: 8, t: 12, b: 24 };

export default function ReportsView() {
  const months = useStore((s) => reportMonths(s));
  const ui = useStore((s) => s.reportsUi);
  const base = useStore((s) => s.profile.baseCurrency);
  const data = useStore((s) => reportsData(s));
  const [activeSlice, setActiveSlice] = useState(0);
  const shortMonth = data.month.split(' ')[0];
  const days = Array.from({ length: 31 }, (_, i) => data.daily[i] || {
    day: i + 1,
    date: `${data.key}-${String(i + 1).padStart(2, '0')}`,
    income: 0,
    expense: 0,
  });
  const maxV = Math.max(1, ...days.map((d) => Math.max(d.income, d.expense))) * 1.1;
  const y = (v) => H - PAD.b - (v / maxV) * (H - PAD.t - PAD.b);
  const pathFor = (key) => days.map((d, i) => `${i === 0 ? 'M' : 'L'}${PAD.l + (i / 30) * (W - PAD.l - PAD.r)},${y(d[key]).toFixed(2)}`).join(' ');
  const savingsPct = Number(String(data.insights.savingsRate.pct).replace('%', '')) || 0;

  useEffect(() => setActiveSlice(0), [ui.month, ui.type, ui.dimension]);

  return (
    <div className="view reports-view">
      <SubHeader
        title="Reports"
        right={
          <button type="button" className="icon-btn" aria-label="Filter reports" onClick={demoStore.toggleCategoryMenu}>
            <Filter />
          </button>
        }
      />

      <div className="month-strip month-pills" role="tablist" aria-label="Report month">
        {months.map((m) => (
          <button
            key={m}
            type="button"
            role="tab"
            aria-selected={ui.month === m}
            className={ui.month === m ? 'on' : ''}
            onClick={() => demoStore.setReportMonth(m)}
          >
            {m}
          </button>
        ))}
      </div>

      <section className="rp-card live-card">
        <div className="rp-card-head">
          <span className="rp-title-lg">Total balance</span>
          <span className="rp-title-lg">{fmtFull(data.totalBalance, base)}</span>
        </div>
        <div className="rp-split">
          <div className="rp-sub income">
            <div className="rp-sub-top"><span className="rp-sub-label"><i className="dot green" /> Income</span><span className="rp-sub-delta pos">{data.income.pct}%</span></div>
            <div className="rp-sub-value">{fmtFull(data.income.value, base)}</div>
            <div className="rp-sub-was">was {fmtFull(data.income.prev, base)} last month</div>
          </div>
          <div className="rp-sub expense">
            <div className="rp-sub-top"><span className="rp-sub-label"><i className="dot red" /> Expense</span><span className="rp-sub-delta neg">{data.expense.pct}%</span></div>
            <div className="rp-sub-value">{fmtFull(data.expense.value, base)}</div>
            <div className="rp-sub-was">was {fmtFull(data.expense.prev, base)} last month</div>
          </div>
        </div>
      </section>

      <section className="rp-card live-card">
        <div className="rp-card-head">
          <span className="rp-head-left"><Sparkles /> Quick Insights</span>
          <span className="rp-badge">{data.txCount} Transactions</span>
        </div>
        <div className="rp-insights">
          <div className="rp-tile">
            <RingGauge pct={Math.max(0, Math.min(100, savingsPct))} size={62} stroke={7} color="#388E3C" label="Savings rate">
              <b>{savingsPct}%</b>
            </RingGauge>
            <div className="rp-tile-sub">{data.insights.savingsRate.amount}</div>
          </div>
          <div className="rp-tile"><div className="rp-tile-main">{data.insights.avgDaily.value}</div><div className="rp-tile-sub">{data.insights.avgDaily.perDay}</div></div>
          <div className="rp-tile"><div className="rp-tile-main">{data.insights.avgTransaction.value}</div><div className="rp-tile-sub">{data.insights.avgTransaction.sub}</div></div>
          <div className="rp-tile"><div className="rp-tile-main sm">{data.insights.peakDay.label}</div><div className="rp-tile-sub danger">{data.insights.peakDay.amount}</div></div>
        </div>
        <div className="rp-banner teal live-card">
          <div className="rp-banner-mid"><span className="rp-banner-label">Top Category</span><span className="rp-banner-title">{data.insights.topCategory.name}</span></div>
          <div className="rp-banner-right"><span className="rp-banner-amount">{data.insights.topCategory.amount}</span><span className="rp-pill teal">{data.insights.topCategory.pct}</span></div>
        </div>
        <div className="rp-banner peach live-card">
          <div className="rp-banner-mid"><span className="rp-banner-label">Largest Expense</span><span className="rp-banner-title">{data.insights.largest.title}</span><span className="rp-banner-date">{data.insights.largest.date}</span></div>
          <span className="rp-banner-amount danger">{data.insights.largest.amount}</span>
        </div>
      </section>

      <section className="rp-card live-card">
        <div className="rp-card-head">
          <span className="rp-head-simple"><BarChart3 /> Reports chart</span>
          <div className="seg-toggle" role="group" aria-label="Chart type">
            <button type="button" className={`seg-btn${ui.chartMode === 'bars' ? ' on' : ''}`} onClick={() => demoStore.setChartMode('bars')}>Bar</button>
            <button type="button" className={`seg-btn${ui.chartMode === 'line' ? ' on' : ''}`} onClick={() => demoStore.setChartMode('line')}>Line</button>
          </div>
        </div>
        <div className="chart-legend"><span className="legend-item"><i className="dot green" /> Income</span><span className="legend-item"><i className="dot red" /> Expense</span></div>
        <InteractiveChart
          count={31}
          width={W}
          height={H}
          padL={PAD.l}
          padR={PAD.r}
          padT={PAD.t}
          padB={PAD.b}
          crosshairColor="#7B4028"
          ariaLabel="Income and expenses by day chart"
          tooltip={(i) => (
            <ChartTooltipCard
              title={`${shortMonth} ${i + 1}`}
              rows={[
                { label: 'Income', value: fmtExact(days[i].income, base) },
                { label: 'Expense', value: fmtExact(days[i].expense, base) },
              ]}
            />
          )}
          tooltipVariant="card"
          style={{ height: H }}
        >
          {({ active, xAt, plotW }) => {
            const bw = plotW / 31;
            return (
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
                {[1, 6, 11, 16, 21, 26, 31].map((d) => <text key={d} x={xAt(d - 1)} y={H - 5} textAnchor="middle" fontSize="8" fill="#8B746B">{d}</text>)}
                {ui.chartMode === 'bars' ? days.map((d, i) => {
                  const x = xAt(i);
                  const iH = Math.max(1, (d.income / maxV) * (H - PAD.t - PAD.b));
                  const eH = Math.max(1, (d.expense / maxV) * (H - PAD.t - PAD.b));
                  return (
                    <g key={d.date} opacity={active == null || active === i ? 1 : 0.55}>
                      <rect x={x - bw * 0.42} y={H - PAD.b - iH} width={bw * 0.36} height={iH} rx="2" fill="#388E3C" />
                      <rect x={x} y={H - PAD.b - eH} width={bw * 0.36} height={eH} rx="2" fill="#E53935" />
                    </g>
                  );
                }) : (
                  <>
                    <path d={pathFor('income')} fill="none" stroke="#388E3C" strokeWidth="2.4" />
                    <path d={pathFor('expense')} fill="none" stroke="#E53935" strokeWidth="2.4" />
                    {days.map((d, i) => (
                      <g key={d.date} opacity={active == null || active === i ? 1 : 0.55}>
                        <circle cx={xAt(i)} cy={y(d.income)} r="2.4" fill="#388E3C" />
                        <circle cx={xAt(i)} cy={y(d.expense)} r="2.4" fill="#E53935" />
                      </g>
                    ))}
                  </>
                )}
                {active != null ? (
                  <g>
                    <circle cx={xAt(active)} cy={y(days[active].income)} r="4.2" fill="#388E3C" stroke="#fff" strokeWidth="1.5" />
                    <circle cx={xAt(active)} cy={y(days[active].expense)} r="4.2" fill="#E53935" stroke="#fff" strokeWidth="1.5" />
                  </g>
                ) : null}
              </>
            );
          }}
        </InteractiveChart>
      </section>

      <section className="rp-card live-card">
        <div className="rp-card-head">
          <span className="rp-head-simple"><PieChart /> Breakdown</span>
          <button type="button" className="btn ghost small" onClick={demoStore.toggleDonut} aria-expanded={ui.donutExpanded}>
            {ui.donutExpanded ? 'Collapse' : 'Expand'} <ChevronDown />
          </button>
        </div>
        <div className="filter-row">
          <button type="button" className="filter-btn" onClick={demoStore.toggleReportType}>{ui.type} ▾</button>
          <button type="button" className="filter-btn" onClick={demoStore.toggleCategoryMenu}>{ui.dimension} ▾</button>
          <button type="button" className="filter-btn" onClick={() => demoStore.openReportDetail('Monthly')}><Filter /> Filter reports</button>
        </div>
        {ui.menuOpen ? (
          <div className="dimension-menu" role="menu" aria-label="Breakdown dimension">
            {DIMENSIONS.map((d) => (
              <button type="button" key={d} role="menuitemradio" aria-checked={ui.dimension === d} onClick={() => demoStore.setDimension(d)}>{d}</button>
            ))}
          </div>
        ) : null}
        {ui.donutExpanded ? (
          <div className="donut-layout">
            <DonutChart
              slices={data.donut}
              active={activeSlice}
              onActive={(i) => setActiveSlice(i)}
              formatter={(v) => fmtExact(v, base)}
            />
            <div className="donut-breakdown">
              {data.donut.map((g, i) => (
                <button
                  type="button"
                  key={g.label}
                  className={`breakdown-row${activeSlice === i ? ' on' : ''}`}
                  onMouseEnter={() => setActiveSlice(i)}
                  onTouchStart={() => setActiveSlice(i)}
                  onClick={() => { setActiveSlice(i); demoStore.openReportDetail(g.label); }}
                >
                  <i className="swatch" style={{ background: g.color }} />
                  <strong>{g.label}</strong>
                  <b>{fmtExact(g.amount, base)}</b>
                  <small>{g.pct.toFixed(1)}%</small>
                </button>
              ))}
              {data.donut.map((g, i) => activeSlice === i ? <WavyProgress key={`wave-${g.label}`} pct={g.pct} color={g.color} track="#E9D9D0" height={6} stroke={3} /> : null)}
              {data.donut.length === 0 ? <p className="empty-note">No {ui.type.toLowerCase()} transactions for {data.month}.</p> : null}
            </div>
          </div>
        ) : null}
      </section>

      <section className="rp-card live-card">
        <div className="rp-card-head"><span className="rp-head-simple"><Wallet /> Financial Reports</span><span className="rp-badge">{data.month}</span></div>
        <div className="collection-list">
          {financialReports.map((r) => (
            <button type="button" className="collection-row clickable" key={r.id} onClick={() => demoStore.openReportDetail(r.title)}>
              <span className="collection-dot" style={{ background: '#7B4028' }} />
              <div><strong>{r.title}</strong><small>{r.desc}</small></div>
              <b>{data.txCount} txns</b>
            </button>
          ))}
        </div>
        <button type="button" className="btn primary" onClick={() => demoStore.openTransactionEditor()}><Plus /> Add transaction</button>
      </section>
    </div>
  );
}
