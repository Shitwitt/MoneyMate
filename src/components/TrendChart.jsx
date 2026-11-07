import React from 'react';
import { ChevronLeft, ChevronRight, TrendingUp } from 'lucide-react';

import { SectionHead } from './ui.jsx';
import { InteractiveChart, ChartTooltipCard } from './charts/Interactive.jsx';
import { demoStore, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { trendSeries } from '../data/derive.js';

const W = 320;
const H = 158;
const PAD = { l: 34, r: 8, t: 10, b: 22 };

export default function TrendChart() {
  const data = useStore((s) => trendSeries(s));
  const base = useStore((s) => s.profile.baseCurrency);
  const prevMonth = useStore((s) => {
    const d = new Date(`${s.today}T00:00:00Z`);
    d.setUTCMonth(d.getUTCMonth() - 1);
    return d.toLocaleDateString('en-US', { month: 'short', timeZone: 'UTC' });
  });

  const y = (v) => H - PAD.b - ((v - data.minV) / Math.max(1, data.maxV - data.minV)) * (H - PAD.t - PAD.b);
  const line = (arr, from = 0, to = arr.length - 1) => arr.slice(from, to + 1)
    .map((v, i) => `${i === 0 ? 'M' : 'L'}${PAD.l + ((from + i) / 30) * (W - PAD.l - PAD.r)},${y(v).toFixed(2)}`)
    .join(' ');

  return (
    <section className="trend-section" aria-label="Spending trend">
      <SectionHead title="Monthly trend" action="Reports" onAction={() => demoStore.go('reports')} />
      <div className="trend-card">
        <div className="trend-top">
          <button type="button" aria-label="Previous month" onClick={() => demoStore.go('reports')}><ChevronLeft /></button>
          <strong><TrendingUp /> This month vs last month</strong>
          <button type="button" aria-label="Next month" onClick={() => demoStore.go('reports')}><ChevronRight /></button>
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
          ariaLabel="Cumulative trend chart with last month, this month and projected spending"
          tooltip={(i) => (
            <ChartTooltipCard
              title={`Day ${i + 1}`}
              rows={[
                { label: 'This Month', value: fmtFull(data.thisMonth[i], base) },
                { label: `Last Month (${prevMonth})`, value: fmtFull(data.lastMonth[i], base) },
                { label: 'Projected', value: fmtFull(data.projected[i], base) },
              ]}
            />
          )}
          tooltipVariant="card"
          style={{ height: H }}
        >
          {({ active, xAt }) => (
            <>
              {[0, 0.5, 1].map((f) => {
                const v = data.maxV * f;
                return (
                  <g key={f}>
                    <line x1={PAD.l} x2={W - PAD.r} y1={y(v)} y2={y(v)} stroke="#E9D9D0" strokeWidth="0.6" />
                    <text x={PAD.l - 4} y={y(v) + 3} textAnchor="end" fontSize="8" fill="#8B746B">{Math.round(v / 1000)}k</text>
                  </g>
                );
              })}
              {[1, 6, 11, 16, 21, 26, 31].map((d) => (
                <text key={d} x={xAt(d - 1)} y={H - 5} textAnchor="middle" fontSize="8" fill="#8B746B">{d}</text>
              ))}
              <path d={line(data.lastMonth)} fill="none" stroke="#B7A096" strokeWidth="1.8" strokeDasharray="4 4" />
              <path d={line(data.thisMonth, 0, data.today - 1)} fill="none" stroke="#7B4028" strokeWidth="2.6" strokeLinecap="round" />
              <path d={line(data.projected, data.today - 1)} fill="none" stroke="#7B4028" strokeWidth="2" strokeDasharray="6 5" opacity="0.8" />
              {active != null ? (
                <g>
                  <circle cx={xAt(active)} cy={y(data.lastMonth[active])} r="3.2" fill="#B7A096" />
                  <circle cx={xAt(active)} cy={y(data.thisMonth[active])} r="3.8" fill="#7B4028" stroke="#fff" strokeWidth="1.5" />
                  <circle cx={xAt(active)} cy={y(data.projected[active])} r="3" fill="#FFB59A" />
                </g>
              ) : null}
            </>
          )}
        </InteractiveChart>
        <div className="pace-legend">
          <span><i style={{ borderColor: '#7B4028' }} />This Month</span>
          <span><i style={{ borderColor: '#B7A096', borderTopStyle: 'dotted' }} />Last Month ({prevMonth})</span>
          <span><i style={{ borderColor: '#FFB59A', borderTopStyle: 'dashed' }} />Projected</span>
        </div>
      </div>
    </section>
  );
}
