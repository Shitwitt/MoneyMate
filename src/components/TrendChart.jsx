import React from 'react';
import { TrendingUp, ChevronRight } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';

/**
 * Full-width "Trend" chart:
 *  - Oct series  : dotted brown line hugging ₹0 (days 1–31)
 *  - This month  : solid brown line flat at ~₹6.5K (days 1–7)
 *  - Upcoming    : dashed olive line rising from ₹6.5K to ~₹17K (days 7–31)
 *  - dashed vertical reference at today (day 7)
 */
export default function TrendChart() {
  const t = useStore((s) => s.trend);

  const W = 300;
  const H = 210;
  const padL = 38;
  const padR = 6;
  const padT = 8;
  const padB = 22;
  const plotW = W - padL - padR;
  const plotH = H - padT - padB;

  const maxV = 25000;
  const minV = -5000;

  const xDay = (d) => padL + ((d - 1) / 30) * plotW;
  const yVal = (v) => padT + ((maxV - v) / (maxV - minV)) * plotH;

  // Oct: flat near zero
  const octPts = Array.from({ length: 31 }, (_, i) => [xDay(i + 1), yVal(i === 0 ? -220 : -260)]);

  // This month: flat 6500
  const thisPts = [
    [xDay(1), yVal(t.thisMonth.value)],
    [xDay(7), yVal(t.thisMonth.value)],
  ];

  // Upcoming: day 7 → 31 mapped over the array
  const up = t.upcoming;
  const upPts = up.map((v, i) => [xDay(7 + (i / (up.length - 1)) * 24), yVal(v)]);

  const toPath = (pts) => pts.map((p, i) => `${i === 0 ? 'M' : 'L'}${p[0].toFixed(2)},${p[1].toFixed(2)}`).join(' ');

  const xTicks = [1, 6, 11, 16, 21, 26, 31];
  const yTicks = [
    { v: 25000, label: '₹25K' },
    { v: 20000, label: '₹20K' },
    { v: 15000, label: '₹15K' },
    { v: 10000, label: '₹10K' },
    { v: 5000, label: '₹5K' },
    { v: 0, label: '₹0' },
    { v: -5000, label: '-₹5K' },
  ];

  return (
    <section className="panel">
      <div className="card-head">
        <span className="head-icon" aria-hidden="true">
          <TrendingUp />
        </span>
        <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--text)' }}>Trend</span>
        <button
          type="button"
          className="chev"
          style={{ marginLeft: 'auto', color: 'var(--text)', display: 'grid', placeItems: 'center' }}
          aria-label="Open trend report"
          onClick={() => demoStore.toast('Trend report — opens in a later step')}
        >
          <ChevronRight size={17} strokeWidth={2.4} />
        </button>
      </div>

      <div className="legend-row-inline">
        <span className="legend-item">
          <span className="swatch dotted" />
          Oct
        </span>
        <span className="legend-item">
          <span className="swatch solid" />
          This month
        </span>
        <span className="legend-item">
          <span className="swatch dashed" />
          Upcoming
        </span>
      </div>

      <svg className="trend-svg" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Balance trend for November">
        {/* grid + y labels */}
        {yTicks.map((tick) => (
          <g key={tick.v}>
            <line
              x1={padL}
              x2={W - padR}
              y1={yVal(tick.v)}
              y2={yVal(tick.v)}
              stroke="#F5ECE8"
              strokeWidth="1"
            />
            <text
              x={padL - 7}
              y={yVal(tick.v) + 3.4}
              textAnchor="end"
              fontSize="8.5"
              fontWeight="600"
              fill="#8A756B"
            >
              {tick.label}
            </text>
          </g>
        ))}

        {/* today reference line */}
        <line
          x1={xDay(t.today)}
          x2={xDay(t.today)}
          y1={padT}
          y2={H - padB}
          stroke="#C9B3A8"
          strokeWidth="1"
          strokeDasharray="3 3"
        />

        {/* Oct dotted */}
        <path d={toPath(octPts)} fill="none" stroke="#7B4028" strokeWidth="2.2" strokeDasharray="1.6 3.4" strokeLinecap="round" />

        {/* This month solid */}
        <path d={toPath(thisPts)} fill="none" stroke="#7B4028" strokeWidth="2.5" strokeLinecap="round" />

        {/* Upcoming dashed */}
        <path d={toPath(upPts)} fill="none" stroke="#7E6B56" strokeWidth="2" strokeDasharray="5 4" strokeLinecap="round" />

        {/* x labels */}
        {xTicks.map((d) => (
          <text key={d} x={xDay(d)} y={H - 6} textAnchor="middle" fontSize="9" fontWeight="600" fill="#8A756B">
            {d}
          </text>
        ))}
      </svg>
    </section>
  );
}
