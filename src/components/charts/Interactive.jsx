import React, { useEffect, useId, useMemo, useRef, useState } from 'react';

/* ============================================================
   Reusable interactive SVG chart system.
   Every surface supports touch-hold/drag and mouse hover/move.
   ============================================================ */

export function useScrub(count, { onChange, initial = null } = {}) {
  const [active, setActiveState] = useState(initial);
  const ref = useRef(null);
  const dragging = useRef(false);
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;

  const setActive = (i) => {
    const next = i == null ? null : Math.max(0, Math.min(count - 1, i));
    setActiveState(next);
    if (onChangeRef.current) onChangeRef.current(next);
  };

  const fromClientX = (clientX, padLeft = 0, padRight = 0) => {
    const el = ref.current;
    if (!el || count <= 0) return;
    const rect = el.getBoundingClientRect();
    if (!rect.width) return;
    const frac = (clientX - rect.left) / rect.width;
    const lo = padLeft;
    const hi = 1 - padRight;
    const clamped = Math.max(0, Math.min(1, (frac - lo) / Math.max(0.001, hi - lo)));
    setActive(Math.round(clamped * (count - 1)));
  };

  const bind = (padLeft = 0, padRight = 0) => ({
    onTouchStart: (e) => {
      e.stopPropagation();
      dragging.current = true;
      if (e.touches?.[0]) fromClientX(e.touches[0].clientX, padLeft, padRight);
    },
    onTouchMove: (e) => {
      if (e.cancelable) e.preventDefault();
      if (e.touches?.[0]) fromClientX(e.touches[0].clientX, padLeft, padRight);
    },
    onTouchEnd: () => { dragging.current = false; },
    onMouseDown: (e) => {
      e.stopPropagation();
      dragging.current = true;
      fromClientX(e.clientX, padLeft, padRight);
    },
    onMouseMove: (e) => {
      // hover AND drag both scrub
      fromClientX(e.clientX, padLeft, padRight);
    },
    onMouseUp: () => { dragging.current = false; },
    onMouseLeave: () => {
      if (!dragging.current) setActive(null);
      dragging.current = false;
    },
    onClick: (e) => e.stopPropagation(),
  });

  return { active, setActive, ref, bind, dragging };
}

/**
 * InteractiveChart renders an SVG plus an HTML tooltip/crosshair.
 * `children` may be a render function receiving { active, xAt, xCenter, plotW }.
 */
export function InteractiveChart({
  count,
  width = 300,
  height = 180,
  padL = 0,
  padR = 0,
  padT = 0,
  padB = 0,
  className = '',
  ariaLabel = 'Interactive chart',
  crosshair = true,
  crosshairColor = '#7B4028',
  tooltip,
  tooltipVariant = 'pill',
  onScrub,
  children,
  style,
}) {
  const { active, setActive, ref, bind } = useScrub(count, { onChange: onScrub });
  const plotW = Math.max(1, width - padL - padR);
  const xAt = (i) => padL + (count <= 1 ? plotW / 2 : (i / (count - 1)) * plotW);
  const xCenter = (i) => padL + ((i + 0.5) / count) * plotW;
  const activeX = active == null ? null : xAt(active);
  const handlers = bind(padL / width, padR / width);

  return (
    <div
      ref={ref}
      className={`chart-surface ${className}`}
      data-scrub="true"
      data-active-index={active == null ? '' : active}
      style={{ position: 'relative', touchAction: 'none', ...style }}
      {...handlers}
    >
      <svg viewBox={`0 0 ${width} ${height}`} role="img" aria-label={ariaLabel} preserveAspectRatio="none">
        {typeof children === 'function' ? children({ active, setActive, xAt, xCenter, plotW, width, height, padL, padR, padT, padB }) : children}
        {crosshair && active != null ? (
          <g className="chart-crosshair" aria-hidden="true">
            <line
              x1={activeX}
              x2={activeX}
              y1={padT}
              y2={height - padB}
              stroke={crosshairColor}
              strokeWidth="1.2"
              strokeDasharray="4 4"
            />
          </g>
        ) : null}
      </svg>
      {active != null && tooltip ? (
        <div
          className={`chart-tooltip ${tooltipVariant}`}
          style={{ left: `${Math.max(8, Math.min(92, (activeX / width) * 100))}%` }}
          role="status"
        >
          {typeof tooltip === 'function' ? tooltip(active) : tooltip}
        </div>
      ) : null}
    </div>
  );
}

export function ChartTooltipPill({ children }) {
  return <span className="chart-tooltip-pill">{children}</span>;
}

export function ChartTooltipCard({ title, rows }) {
  return (
    <div className="chart-tooltip-card">
      {title ? <strong>{title}</strong> : null}
      {rows.map((r) => (
        <div key={r.label} className="chart-tooltip-row">
          <span>{r.label}</span>
          <b>{r.value}</b>
        </div>
      ))}
    </div>
  );
}

/** Circular gauge whose dash offset is computed from the live percentage. */
export function RingGauge({ pct = 0, size = 56, stroke = 6, color = '#7B4028', track = '#EFE5DF', children, label }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const safe = Math.max(0, Math.min(100, Number(pct) || 0));
  const offset = c - (safe / 100) * c;
  const [hover, setHover] = useState(false);
  return (
    <div
      className="ring-gauge-wrap"
      data-scrub="true"
      onTouchStart={() => setHover(true)}
      onMouseEnter={() => setHover(true)}
      onMouseMove={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      onTouchEnd={() => setHover(false)}
      style={{ position: 'relative', width: size, height: size }}
    >
      <svg viewBox={`0 0 ${size} ${size}`} width={size} height={size} role="img" aria-label={label || `${safe}% used`}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={track} strokeWidth={stroke} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={offset}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      <span className="ring-gauge-center">{children ?? `${safe}%`}</span>
      {hover ? <span className="chart-tooltip pill">{`${safe}%`}</span> : null}
    </div>
  );
}

/** Material-3 sinusoidal progress bar, clipped to the exact percentage. */
export function WavyProgress({ pct = 0, color = '#7B4028', track = '#F5DCE0', height = 10, stroke = 3, cycles = 2.4, label }) {
  const uid = useId().replace(/:/g, '');
  const safe = Number(pct) || 0;
  const W = 320;
  const H = height;
  const mid = H / 2;
  const amp = Math.min(3.5, H / 3);
  const clipped = Math.max(0, Math.min(100, safe));
  const path = useMemo(() => {
    let d = '';
    const steps = 80;
    for (let i = 0; i <= steps; i += 1) {
      const x = (W * i) / steps;
      const y = mid + Math.sin((i / steps) * Math.PI * 2 * cycles) * amp;
      d += i === 0 ? `M${x.toFixed(2)},${y.toFixed(2)}` : `L${x.toFixed(2)},${y.toFixed(2)}`;
    }
    return d;
  }, [W, mid, amp, cycles]);
  const [hover, setHover] = useState(false);
  return (
    <div
      className="wavy-progress-wrap"
      data-scrub="true"
      onTouchStart={() => setHover(true)}
      onMouseEnter={() => setHover(true)}
      onMouseMove={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      onTouchEnd={() => setHover(false)}
      style={{ position: 'relative', height }}
      aria-label={label || `${safe}% complete`}
    >
      <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" style={{ width: '100%', height, display: 'block' }}>
        <defs>
          <clipPath id={`wavy-${uid}`}>
            <rect x="0" y="0" width={(W * clipped) / 100} height={H} />
          </clipPath>
        </defs>
        <line x1="0" x2={W} y1={mid} y2={mid} stroke={track} strokeWidth={stroke} strokeLinecap="round" />
        <g clipPath={`url(#wavy-${uid})`}>
          <path d={path} fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" />
        </g>
      </svg>
      {hover ? <span className="chart-tooltip pill">{`${safe}%`}</span> : null}
    </div>
  );
}

/** Interactive donut with hover/tap slice expansion and center readout. */
export function DonutChart({ slices = [], size = 220, stroke = 46, formatter = (v) => v, onActive, active: activeProp }) {
  const [internal, setInternal] = useState(0);
  const active = activeProp == null ? internal : Math.min(activeProp, Math.max(0, slices.length - 1));
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const total = slices.reduce((s, x) => s + (Number(x.amount) || 0), 0) || 1;
  let acc = 0;
  const current = slices[active] || slices[0] || { label: '—', amount: 0, pct: 0 };
  const activate = (i) => {
    setInternal(i);
    if (onActive) onActive(i, slices[i] || null);
  };
  useEffect(() => {
    if (internal >= slices.length) setInternal(0);
  }, [slices.length, internal]);

  return (
    <div className="interactive-donut" data-scrub="true" style={{ width: size, height: size, position: 'relative' }}>
      <svg viewBox={`0 0 ${size} ${size}`} role="img" aria-label="Interactive breakdown donut">
        {slices.map((s, i) => {
          const len = ((Number(s.amount) || 0) / total) * c;
          const dashOffset = -acc;
          acc += len;
          const isActive = i === active;
          return (
            <circle
              key={`${s.label}-${i}`}
              cx={size / 2}
              cy={size / 2}
              r={r}
              fill="none"
              stroke={s.color}
              strokeWidth={isActive ? stroke + 8 : stroke}
              strokeDasharray={`${Math.max(0, len - 1)} ${c - Math.max(0, len - 1)}`}
              strokeDashoffset={dashOffset}
              transform={`rotate(-90 ${size / 2} ${size / 2})`}
              opacity={isActive ? 1 : 0.86}
              style={{ cursor: 'pointer', transition: 'stroke-width .18s ease, opacity .18s ease' }}
              onMouseEnter={() => activate(i)}
              onMouseMove={() => activate(i)}
              onTouchStart={() => activate(i)}
              onClick={() => activate(i)}
            />
          );
        })}
      </svg>
      <div className="donut-center" aria-live="polite">
        <strong>{current.label}</strong>
        <span>{formatter(current.amount)}</span>
        <small>{Number(current.pct || 0).toFixed(1)}% share</small>
      </div>
    </div>
  );
}
