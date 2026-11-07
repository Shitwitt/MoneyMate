import React from 'react';
import { ArrowLeft } from 'lucide-react';
import { demoStore } from '../../data/demoStore.js';
import { useT } from '../../hooks/useT.js';
import ProfileAvatar from '../ProfileAvatar.jsx';
import { WavyProgress as LiveWavyProgress, RingGauge as LiveRingGauge } from '../charts/Interactive.jsx';

/* ---------- Top app bar for sub-screens ---------- */

export function SubHeader({ title, onBack, right, center = true }) {
  const t = useT();
  return (
    <header className="sub-header">
      <div className="sub-left">
        <button type="button" className="back-btn" aria-label="Back" onClick={onBack || (() => demoStore.back())}>
          <ArrowLeft />
        </button>
        <h1 className="sub-title">{t(title)}</h1>
      </div>


      <div className="sub-right">
        {right}
        <ProfileAvatar label={t('Profile')} />
      </div>
    </header>
  );
}

/* ---------- Expressive wavy progress bar ----------
   Filled portion is a sinusoidal wave, the rest is a flat track. */

export function WavyProgress({ pct, color, track, height = 10, stroke = 4 }) {
  return <LiveWavyProgress pct={pct} color={color} track={track} height={height} stroke={stroke} />;
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
  return <LiveRingGauge pct={pct} size={size} stroke={stroke} track={track} color={color} label={`${pct}% used`}>{children}</LiveRingGauge>;
}
