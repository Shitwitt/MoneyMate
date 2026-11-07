import React, { useState } from 'react';
import { CalendarDays, ChevronLeft, ChevronRight, Plus } from 'lucide-react';

import { SectionHead } from './ui.jsx';
import { demoStore, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { calendarHeatmap } from '../data/derive.js';

export default function CalendarHeatmap() {
  const heatmap = useStore((s) => calendarHeatmap(s));
  const base = useStore((s) => s.profile.baseCurrency);
  const today = useStore((s) => s.today);
  const [selected, setSelected] = useState(today);
  const [hovered, setHovered] = useState(null);
  const chosenDate = hovered || selected;
  const cells = heatmap.cells;
  const chosen = cells.find((c) => c.date === chosenDate) || { date: chosenDate, amount: 0, count: 0 };
  const colorFor = (cell) => {
    if (!cell.date) return 'transparent';
    if (cell.level === 0) return heatmap.zero;
    if (cell.level === 2) return heatmap.high;
    return heatmap.medium;
  };

  return (
    <section className="calendar-section" aria-label="Spending calendar">
      <SectionHead
        title={heatmap.month}
        action="Reports"
        onAction={() => demoStore.go('reports')}
      />
      <div className="calendar-card">
        <div className="calendar-top">
          <button type="button" aria-label="Previous month" onClick={() => demoStore.go('reports')}><ChevronLeft /></button>
          <strong><CalendarDays /> Spending heatmap</strong>
          <button type="button" aria-label="Next month" onClick={() => demoStore.go('reports')}><ChevronRight /></button>
        </div>
        <div className="weekday-row">{['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => <span key={d}>{d}</span>)}</div>
        <div
          className="heatmap-grid"
          role="grid"
          data-scrub="true"
          data-active-date={chosenDate}
          onTouchMove={(e) => {
            const el = document.elementFromPoint(e.touches[0].clientX, e.touches[0].clientY);
            const date = el?.getAttribute?.('data-date');
            if (date) setHovered(date);
          }}
        >
          {cells.map((cell) => cell.date ? (
            <button
              type="button"
              key={cell.key}
              data-date={cell.date}
              className={`heat-cell${chosenDate === cell.date ? ' selected' : ''}${cell.isToday ? ' today' : ''}`}
              style={{ background: colorFor(cell) }}
              aria-label={`${cell.date}: ${cell.count} transactions, ${fmtFull(cell.amount, base)}`}
              onMouseEnter={() => setHovered(cell.date)}
              onTouchStart={() => { setSelected(cell.date); setHovered(cell.date); }}
              onClick={() => setSelected(cell.date)}
            >
              <span>{cell.day}</span>
            </button>
          ) : <span key={cell.key} className="heat-cell blank" />)}
        </div>
        <div className="heatmap-legend">
          <span>Less</span><i style={{ background: heatmap.zero }} /><i style={{ background: heatmap.medium }} /><i style={{ background: heatmap.high }} /><span>More</span>
        </div>
        <div className="heat-summary">
          <div>
            <strong>{chosen.date}</strong>
            <small>{chosen.count || 0} txns · {fmtFull(chosen.amount || 0, base)}</small>
          </div>
          <button type="button" onClick={() => demoStore.openTransactionEditor({ date: chosen.date })}>
            <Plus /> Add transaction on this date
          </button>
        </div>
      </div>
    </section>
  );
}
