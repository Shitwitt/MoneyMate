import React, { useRef } from 'react';
import { ChevronRight } from 'lucide-react';

/* ---------- Section heading ---------- */

export function SectionHead({ title, action, onAction, tone }) {
  return (
    <div className={`section-head${tone === 'sand' ? ' on-sand' : ''}`}>
      <h2>{title}</h2>
      {action ? (
        <button type="button" className="see-all" onClick={onAction}>
          {action}
        </button>
      ) : null}
    </div>
  );
}

/* ---------- Bento card shell ---------- */

export function Card({
  icon: Icon,
  title,
  chevron = true,
  onClick,
  className = '',
  children,
  style,
  ariaLabel,
}) {
  const Comp = onClick ? 'button' : 'div';
  return (
    <Comp
      type={onClick ? 'button' : undefined}
      className={`card ${className}`.trim()}
      onClick={onClick}
      style={style}
      aria-label={ariaLabel || (onClick ? title : undefined)}
    >
      <div className="card-head">
        {Icon ? (
          <span className="head-icon" aria-hidden="true">
            <Icon />
          </span>
        ) : null}
        <span className="card-title">{title}</span>
        {chevron ? (
          <span className="chev" aria-hidden="true">
            <ChevronRight />
          </span>
        ) : null}
      </div>
      {children}
    </Comp>
  );
}

/* ---------- Pagination dots ---------- */

export function Dots({ count, active, className = 'dots' }) {
  return (
    <div className={className} aria-hidden="true">
      {Array.from({ length: count }).map((_, i) => (
        <i key={i} className={i === active ? 'on' : ''} />
      ))}
    </div>
  );
}

/* ---------- Swipe helper (pointer + touch) ---------- */

export function useSwipe({ onLeft, onRight, threshold = 34 }) {
  const start = useRef(null);

  const down = (e) => {
    start.current = e.touches ? e.touches[0].clientX : e.clientX;
  };
  const up = (e) => {
    if (start.current == null) return;
    const end = e.changedTouches ? e.changedTouches[0].clientX : e.clientX;
    const dx = end - start.current;
    start.current = null;
    if (Math.abs(dx) < threshold) return;
    if (dx < 0) onLeft?.();
    else onRight?.();
  };

  return {
    onTouchStart: down,
    onTouchEnd: up,
    onPointerDown: (e) => {
      if (e.pointerType === 'mouse') down(e);
    },
    onPointerUp: (e) => {
      if (e.pointerType === 'mouse') up(e);
    },
  };
}
