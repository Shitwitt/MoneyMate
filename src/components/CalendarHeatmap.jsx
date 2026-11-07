import React, { useState } from 'react';
import { CalendarDays, ChevronRight, Plus } from 'lucide-react';

import { demoStore, fmtFull } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import { calendarHeatmap } from '../data/derive.js';

function previousMonthStart(today) {
  const [y, m] = today.split('-').map(Number);
  const d = new Date(Date.UTC(y, m - 2, 1));
  return d.toISOString().slice(0, 10);
}

function MiniMonth({ cells, palette, selectedDate, onPick }) {
  return (
    <div className="mini-month">
      {cells.map((cell) => cell.date ? (
        <button
          type="button"
          key={cell.key}
          data-date={cell.date}
          className={`heat-cell${selectedDate === cell.date ? ' selected' : ''}`}
          style={{ background: cell.level === 2 ? palette.high : cell.level === 1 ? palette.medium : palette.zero }}
          aria-label={`${cell.date}: ${cell.count} transactions, ${fmtFull(cell.amount, palette.base)}`}
          onClick={() => onPick(cell.date)}
        >
          <span>{cell.day}</span>
        </button>
      ) : <span key={cell.key} className="heat-cell blank" />)}
    </div>
  );
}

export default function CalendarHeatmap() {
  const snapshot = useStore((s) => ({
    today: s.today,
    transactions: s.transactions,
    baseCurrency: s.profile.baseCurrency,
  }));
  const [selected, setSelected] = useState(snapshot.today);
  const [hovered, setHovered] = useState(null);

  const state = {
    today: snapshot.today,
    transactions: snapshot.transactions,
    profile: { baseCurrency: snapshot.baseCurrency },
  };
  const current = calendarHeatmap(state);
  const previous = calendarHeatmap({ ...state, today: previousMonthStart(snapshot.today) });
  const chosenDate = hovered || selected;
  const allCells = [...previous.cells, ...current.cells];
  const chosen = allCells.find((c) => c.date === chosenDate) || { date: chosenDate, amount: 0, count: 0 };
  const palette = { ...current, base: snapshot.baseCurrency };
  const monthTitle = new Date(`${snapshot.today}T00:00:00Z`).toLocaleDateString('en-US', { month: 'short', year: 'numeric', timeZone: 'UTC' });

  return (
    <section className="calendar-section" aria-label="Spending calendar">
      <div className="calendar-card" role="group" aria-label="Spending calendar heatmap">
        <button type="button" className="calendar-card-head" onClick={() => demoStore.go('reports')} aria-label="Open reports calendar">
          <strong><CalendarDays /> Calendar heatmap</strong>
          <ChevronRight />
        </button>
        <h3 className="calendar-month-title">{monthTitle}</h3>
        <h4 className="calendar-subtitle">Spending heatmap</h4>
        <div
          className="heatmap-months"
          data-scrub="true"
          data-active-date={chosenDate}
          onTouchMove={(e) => {
            const el = document.elementFromPoint(e.touches[0].clientX, e.touches[0].clientY);
            const date = el?.getAttribute?.('data-date');
            if (date) setHovered(date);
          }}
          onMouseLeave={() => setHovered(null)}
        >
          <div className="heatmap-month-wrap prev"><MiniMonth cells={previous.cells} palette={palette} selectedDate={chosenDate} onPick={setSelected} /></div>
          <div className="heatmap-month-wrap current"><MiniMonth cells={current.cells} palette={palette} selectedDate={chosenDate} onPick={setSelected} /></div>
        </div>
      </div>
      <div className="heat-summary">
        <div>
          <strong>{chosen.date}</strong>
          <small>{chosen.count || 0} txns · {fmtFull(chosen.amount || 0, snapshot.baseCurrency)}</small>
        </div>
        <button type="button" onClick={() => demoStore.openTransactionEditor({ date: chosen.date })}>
          <Plus /> Add transaction on this date
        </button>
      </div>
    </section>
  );
}
