import React from 'react';
import { ArrowLeft, UserRound } from 'lucide-react';
import { demoStore } from '../../data/demoStore.js';

/* ---------- Top app bar for sub-screens ---------- */

export function SubHeader({ title, onBack, right, center = true }) {
  return (
    <header className="sub-header">
      <div className="sub-left">
        <button type="button" className="back-btn" aria-label="Back" onClick={onBack || (() => demoStore.back())}>
          <ArrowLeft />
        </button>
        <h1 className="sub-title">{title}</h1>
      </div>

      {center ? <ExitDemoPill /> : null}

      <div className="sub-right">
        {right}
        <button
          type="button"
          className="avatar-btn"
          aria-label="Profile"
          onClick={() => demoStore.toast('Profile menu')}
        >
          <UserRound />
        </button>
      </div>
    </header>
  );
}

export function ExitDemoPill() {
  return (
    <button type="button" className="exit-demo compact" onClick={() => demoStore.exitDemo()}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" aria-hidden="true">
        <path d="M6 6l12 12M18 6L6 18" />
      </svg>
      Exit Demo
    </button>
  );
}

/* ---------- Expressive wavy progress bar ----------
   Filled portion is a sinusoidal wave, the rest is a flat track. */

export function WavyProgress({ pct, color, track, height = 10, stroke = 4 }) {
  const W = 320;
  const left = Math.max(2.5, (W * pct) / 100);
  const mid = height / 2;
  const amp = height / 2 - stroke / 2 + 0.4;
  const waves = Math.max(1, Math.round(left / 46));
  const steps = Math.max(8, waves * 14);

  let d = '';
  for (let i = 0; i <= steps; i += 1) {
    const x = (left * i) / steps;
    const y = mid + Math.sin((i / steps) * Math.PI * 2 * waves - Math.PI / 2) * amp;
    d += i === 0 ? `M${x.toFixed(2)},${y.toFixed(2)}` : `L${x.toFixed(2)},${y.toFixed(2)}`;
  }

  return (
    <svg
      className="wavy"
      viewBox={`0 0 ${W} ${height}`}
      preserveAspectRatio="none"
      role="img"
      aria-label={`${pct}% used`}
    >
      <line
        x1={left}
        x2={W}
        y1={mid}
        y2={mid}
        stroke={track}
        strokeWidth={stroke}
        strokeLinecap="round"
      />
      <path d={d} fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" />
    </svg>
  );
}

/* ---------- mini chip ---------- */

export function MiniChip({ children, bg, fg, icon }) {
  return (
    <span className="mini-chip" style={{ background: bg, color: fg }}>
      {icon ? <span className="mc-ico">{icon}</span> : null}
      {children}
    </span>
  );
}

/* ---------- dot gauge ring ---------- */

export function RingGauge({ pct, size = 155, stroke = 18, track = '#EFE5DF', color = '#3949AB', children }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const dash = (c * Math.min(100, Math.max(0, pct))) / 100;
  return (
    <div className="ring-gauge" style={{ width: size, height: size }}>
      <svg viewBox={`0 0 ${size} ${size}`}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={track} strokeWidth={stroke} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={`${dash.toFixed(2)} ${c.toFixed(2)}`}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      <div className="ring-center">{children}</div>
    </div>
  );
}
