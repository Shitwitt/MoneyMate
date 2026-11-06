import React from 'react';

/**
 * Stepped area sparkline — rises in 4 steps left → right, ends with a solid node.
 */
export default function Sparkline({ points = [] }) {
  const W = 150;
  const H = 74;
  const pad = 3;
  const n = points.length;

  const x = (i) => pad + (i / (n - 1)) * (W - pad * 2 - 6);
  const y = (v) => H - pad - (v / 100) * (H - pad * 2);

  // stepped path: hold value, then jump vertically
  let line = '';
  points.forEach((v, i) => {
    const px = x(i);
    const py = y(v);
    if (i === 0) line += `M${px.toFixed(2)},${py.toFixed(2)}`;
    else line += `L${px.toFixed(2)},${y(points[i - 1]).toFixed(2)} L${px.toFixed(2)},${py.toFixed(2)}`;
  });

  const area = `${line} L${x(n - 1).toFixed(2)},${H} L${pad},${H} Z`;
  const lastX = x(n - 1);
  const lastY = y(points[n - 1]);

  return (
    <svg className="spark-chart" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" role="img" aria-label="Last 30 days spending trend, rising">
      <defs>
        <linearGradient id="sparkFill" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#388E3C" stopOpacity="0.25" />
          <stop offset="100%" stopColor="#388E3C" stopOpacity="0.05" />
        </linearGradient>
      </defs>
      <path d={area} fill="url(#sparkFill)" />
      <path d={line} fill="none" stroke="#388E3C" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" />
      <circle cx={lastX} cy={lastY} r="3.6" fill="#388E3C" />
    </svg>
  );
}
