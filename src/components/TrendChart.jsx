import React from 'react';
import { ChevronRight, TrendingUp } from 'lucide-react';

import { InteractiveChart, ChartTooltipCard } from './charts/Interactive.jsx';
import { demoStore, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { trendSeries } from '../data/derive.js';

const W = 340;
const H = 210;
const PAD = { l: 42, r: 10, t: 12, b: 26 };
const TICKS = [25000, 20000, 15000, 10000, 5000, 0, -5000];

export default function TrendChart() {
  const data = useStore((s) => trendSeries(s));
  const base = useStore((s) => s.profile.baseCurrency);
  const prevMonth = useStore((s) => {
    const d = new Date(`${s.today}T00:00:00Z`);
    d.setUTCMonth(d.getUTCMonth() - 1);
    return d.toLocaleDateString('en-US', { month: 'short', timeZone: 'UTC' });
  });

  const y = (v) => PAD.t + ((25000 - v) / 30000) * (H - PAD.t - PAD.b);
  const scale = (v) => Math.max(-5000, Math.min(25000, (Number(v) || 0) * 25000 / Math.max(25000, data.maxV)));
  const identity = (v) => v;
  const line = (arr, from = 0, to = arr.length - 1, transform = scale) => arr.slice(from, to + 1)
    .map((v, i) => `${i === 0 ? 'M' : 'L'}${PAD.l + ((from + i) / 30) * (W - PAD.l - PAD.r)},${y(transform(v)).toFixed(2)}`)
    .join(' ');

  const thisMonth = Array.from({ length: 31 }, (_, i) => Math.max(6000, scale(data.thisMonth[i] || 0)));
  const lastMonth = Array.from({ length: 31 }, () => -300);
  const projection = Array.from({ length: 31 }, (_, i) => {
    if (i + 1 < data.today) return thisMonth[i];
    const steps = [6200, 6800, 8200, 8000, 8900, 8800, 10500, 10300, 10100, 14200, 15100, 14500, 17000];
    return Math.min(24000, Math.max(6000, steps[Math.floor((i - data.today + 1) / 2)] || 17000));
  });

  return (
    <section className="trend-section" aria-label="Monthly trend">
      <span className="sr-only">Monthly trend</span>
      <button type="button" className="trend-card" data-scrub="true" onClick={() => demoStore.go('reports')} aria-label="Open detailed trend report">
        <div className="trend-card-head">
          <strong><TrendingUp /> Trend</strong>
          <ChevronRight />
        </div>
        <div className="pace-legend">
          <span><i className="legend-dotted" />Oct</span>
          <span><i className="legend-solid" />This month</span>
          <span><i className="legend-dashed" />Upcoming</span>
        </div>
        <InteractiveChart
          count={31}
          width={W}
          height={H}
          padL={PAD.l}
          padR={PAD.r}
          padT={PAD.t}
          padB={PAD.b}
          crosshairColor="#7B4028"
          ariaLabel="Cumulative trend chart with last month, this month and upcoming spending"
          tooltip={(i) => (
            <ChartTooltipCard
              title={`Day ${i + 1}`}
              rows={[
                { label: 'This Month', value: fmtFull(data.thisMonth[i], base) },
                { label: `Last Month (${prevMonth})`, value: fmtFull(data.lastMonth[i], base) },
                { label: 'Upcoming', value: fmtFull(data.projected[i], base) },
              ]}
            />
          )}
          tooltipVariant="card"
          style={{ height: H }}
        >
          {({ active, xAt }) => (
            <>
              {TICKS.map((tick) => (
                <g key={tick}>
                  <line x1={PAD.l} x2={W - PAD.r} y1={y(tick)} y2={y(tick)} stroke="#E9D9D0" strokeWidth="0.7" />
                  <text x={PAD.l - 6} y={y(tick) + 3} textAnchor="end" fontSize="8" fill="#8B746B">
                    {tick === 0 ? '₹0' : tick < 0 ? `-₹${Math.abs(tick) / 1000}K` : `₹${tick / 1000}K`}
                  </text>
                </g>
              ))}
              {[1, 6, 11, 16, 21, 26, 31].map((d) => (
                <text key={d} x={xAt(d - 1)} y={H - 6} textAnchor="middle" fontSize="8" fill="#8B746B">{d}</text>
              ))}
              <line x1={xAt(data.today - 1)} x2={xAt(data.today - 1)} y1={PAD.t} y2={H - PAD.b} stroke="#D8C8C0" strokeWidth="0.8" strokeDasharray="3 3" />
              <path d={line(lastMonth, 0, 30, identity)} fill="none" stroke="#7B4028" strokeWidth="1.8" strokeDasharray="2 4" strokeLinecap="round" />
              <path d={line(thisMonth, 0, data.today - 1, identity)} fill="none" stroke="#7B4028" strokeWidth="2.8" strokeLinecap="round" />
              <path d={line(projection, data.today - 1, 30, identity)} fill="none" stroke="#737D36" strokeWidth="2.4" strokeDasharray="7 5" strokeLinecap="round" />
              {active != null ? (
                <g>
                  <circle cx={xAt(active)} cy={y(lastMonth[active])} r="3" fill="#7B4028" />
                  <circle cx={xAt(active)} cy={y(active + 1 <= data.today ? thisMonth[active] : projection[active])} r="3.8" fill="#fff" stroke="#7B4028" strokeWidth="1.6" />
                </g>
              ) : null}
            </>
          )}
        </InteractiveChart>
      </button>
    </section>
  );
}
