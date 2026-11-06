import React from 'react';
import { CalendarDays, ChevronRight } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';

/**
 * Calendar heatmap: a 3-column trailing slice of October + the full
 * 7-column November grid, rendered as one 10-column grid.
 */
export default function CalendarHeatmap() {
  const h = useStore((s) => s.heatmap);

  const cell = (day, level, key, isToday = false, month = 'Nov') => (
    <div
      key={key}
      className={`heat-cell${level ? ` l${level}` : ''}${isToday ? ' today' : ''}${day ? ' press' : ''}`}
      title={day ? `${month} ${day} 2026` : undefined}
    >
      {day ?? ''}
    </div>
  );

  return (
    <section className="panel">
      <div className="card-head" style={{ marginBottom: 2 }}>
        <span className="head-icon" aria-hidden="true">
          <CalendarDays />
        </span>
        <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--text)' }}>Calendar heatmap</span>
        <button
          type="button"
          className="chev"
          style={{ marginLeft: 'auto', color: 'var(--text)', display: 'grid', placeItems: 'center' }}
          aria-label="Open calendar"
          onClick={() => demoStore.toast('Calendar — opens in a later step')}
        >
          <ChevronRight size={17} strokeWidth={2.4} />
        </button>
      </div>

      <div className="heat-month">
        <span>{h.month}</span>
      </div>

      <div className="heat-grid">
        {/* October tail — 3 columns */}
        {h.octoberTail.map((row, r) =>
          row.map((day, c) =>
            day == null ? (
              <div key={`o-${r}-${c}`} className="heat-cell blank" />
            ) : (
              cell(day, h.octLevels[day] ?? 0, `o-${r}-${c}`, false, 'Oct')
            ),
          ),
        )}

        {/* November — 7 columns, week by week */}
        {h.november.map((row, r) =>
          row.map((day, c) =>
            day == null ? (
              <div key={`n-${r}-${c}`} className="heat-cell blank" />
            ) : (
              cell(day, h.novLevels[day] ?? 0, `n-${r}-${c}`, day === h.today)
            ),
          ),
        )}
      </div>
    </section>
  );
}
