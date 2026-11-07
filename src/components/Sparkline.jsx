import React, { useState } from 'react';

import { InteractiveChart } from './charts/Interactive.jsx';
import { fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';

export default function Sparkline({ data }) {
  const [active, setActive] = useState(null);
  const base = useStore((s) => s.profile.baseCurrency);
  const privacy = useStore((s) => s.privacy);
  const points = data?.points || [];
  const W = 300;
  const H = 88;
  const padL = 4;
  const padR = 4;
  const padT = 8;
  const padB = 10;
  const y = (pct) => H - padB - ((Number(pct) || 0) / 100) * (H - padT - padB);
  const activePoint = active == null ? null : points[active];
  const shown = activePoint ? activePoint.amount : data?.total || 0;
  const label = activePoint
    ? new Date(`${activePoint.date}T00:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    : 'Last 30 days';

  return (
    <div className="spark-live" data-live-sparkline="true">
      <div className="spark-head">
        <div>
          <b>{privacy ? '••••' : fmtFull(shown, base)}</b>
          <small>{label}</small>
        </div>
        <span className={`spark-badge ${data?.deltaPct >= 0 ? 'up' : 'down'}`}>{data?.deltaPct >= 0 ? '+' : ''}{data?.deltaPct || 0}%</span>
      </div>
      <InteractiveChart
        count={points.length}
        width={W}
        height={H}
        padL={padL}
        padR={padR}
        padT={padT}
        padB={padB}
        ariaLabel="Last 30 days cumulative spending sparkline"
        crosshairColor="#388E3C"
        onScrub={setActive}
        tooltip={(i) => {
          const p = points[i];
          const date = new Date(`${p.date}T00:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
          return `${date}: ${fmtFull(p.amount, base)}`;
        }}
        tooltipVariant="pill"
        style={{ height: H }}
      >
        {({ active: a, xAt }) => {
          const path = points.map((p, i) => (i === 0
            ? `M${xAt(i).toFixed(2)},${y(p.cumPct).toFixed(2)}`
            : `H${xAt(i).toFixed(2)} V${y(p.cumPct).toFixed(2)}`)).join(' ');
          const area = points.length
            ? `${path} L${xAt(points.length - 1).toFixed(2)},${H - padB} L${xAt(0).toFixed(2)},${H - padB} Z`
            : '';
          return (
            <>
              <defs>
                <linearGradient id="spark-live-fill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#388E3C" stopOpacity="0.32" />
                  <stop offset="100%" stopColor="#388E3C" stopOpacity="0.02" />
                </linearGradient>
              </defs>
              <path d={area} fill="url(#spark-live-fill)" />
              <path d={path} fill="none" stroke="#388E3C" strokeWidth="2" strokeLinejoin="round" />
              {a != null && points[a] ? (
                <g>
                  <circle cx={xAt(a)} cy={y(points[a].cumPct)} r="7" fill="#388E3C" opacity="0.18" />
                  <circle cx={xAt(a)} cy={y(points[a].cumPct)} r="3.5" fill="#FFF" stroke="#388E3C" strokeWidth="2" />
                </g>
              ) : null}
            </>
          );
        }}
      </InteractiveChart>
    </div>
  );
}
