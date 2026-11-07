import React from 'react';
import { ArrowLeft, X } from 'lucide-react';
import { demoStore } from '../../data/demoStore.js';

/* ---------- dark-aware app bar ---------- */

export function DarkHeader({ title, right, onBack }) {
  return (
    <header className="dark-header">
      <button type="button" className="dark-back" aria-label="Back" onClick={onBack || (() => demoStore.back())}>
        <ArrowLeft />
      </button>
      <h1 className="dark-title">{title}</h1>
      <div className="dark-right">{right}</div>
    </header>
  );
}

export function PageBadge({ children }) {
  return <span className="page-badge">{children}</span>;
}

export function InfoButton({ onClick, label = 'How this works' }) {
  return (
    <button type="button" className="info-btn" aria-label={label} onClick={onClick}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round">
        <circle cx="12" cy="12" r="9" />
        <path d="M12 11v5.5M12 7.6v.1" />
      </svg>
    </button>
  );
}

/* ---------- bottom sheet modal (light or dark) ---------- */

export function SheetModal({ title, intro, items, onClose, tone = 'light', children, footer }) {
  return (
    <div className={`sheet-scrim tone-${tone}`} role="presentation" onClick={onClose}>
      <div
        className={`sheet tone-${tone}`}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sheet-head">
          <h2>{title}</h2>
          <button type="button" className="sheet-close" aria-label="Close" onClick={onClose}>
            <X />
          </button>
        </div>
        {intro ? <p className="sheet-intro">{intro}</p> : null}

        <div className="sheet-items">
          {items
            ? items.map((it) => (
                <div className="sheet-item" key={it.title}>
                  <span className="sheet-ico">{it.icon}</span>
                  <div>
                    <div className="sheet-item-title">{it.title}</div>
                    {(it.lines || (it.text ? [it.text] : [])).map((l) => (
                      <p className="sheet-line" key={l}>
                        {l}
                      </p>
                    ))}
                  </div>
                </div>
              ))
            : null}
          {children}
        </div>

        {footer !== null ? (
          <button type="button" className="sheet-cta" onClick={onClose}>
            Got it
          </button>
        ) : null}
      </div>
    </div>
  );
}

/* ---------- segmented control (bottom pill bar) ---------- */

export function SegmentedBar({ options, value, onChange, className = '' }) {
  return (
    <div className={`seg-bar ${className}`.trim()} role="tablist">
      {options.map((o) => (
        <button
          key={o.id}
          type="button"
          role="tab"
          aria-selected={value === o.id}
          className={`seg-pill${value === o.id ? ' on' : ''}`}
          onClick={() => onChange(o.id)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

/* ---------- avatar stack ---------- */

export function AvatarStack({ people, size = 24 }) {
  return (
    <span className="avatar-stack">
      {people.map((p, i) => (
        <span
          key={p.id || p.name}
          className="avatar"
          style={{
            width: size,
            height: size,
            background: p.color || '#00897B',
            marginLeft: i ? -6 : 0,
            fontSize: size * 0.42,
            zIndex: people.length - i,
          }}
          title={p.name}
        >
          {p.name.charAt(0).toUpperCase()}
        </span>
      ))}
    </span>
  );
}
