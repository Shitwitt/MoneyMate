import React from 'react';
import { Banknote } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { SectionHead } from './ui.jsx';

export default function Templates() {
  const templates = useStore((s) => s.templates);
  const privacy = useStore((s) => s.privacy);

  return (
    <>
      <SectionHead
        title="Templates"
        tone="sand"
        action="See all"
        onAction={() => demoStore.toast('All templates')}
      />
      <div className="tpl-row">
        {templates.map((t) => (
          <button
            type="button"
            className="tpl-card"
            key={t.id}
            onClick={() => demoStore.toast(`Quick-add “${t.name}”`)}
          >
            <span className="tpl-top">
              <span className="tpl-ico" style={{ background: t.color }}>
                <Banknote />
              </span>
              {t.amount > 0 ? (
                <span className="tpl-amt">
                  {privacy ? '₹••••' : `₹${t.amount.toFixed(2)}`}
                </span>
              ) : null}
            </span>
            <span>
              <span className="tpl-name" style={{ display: 'block' }}>
                {t.name}
              </span>
              <span className="tpl-type" style={{ display: 'block' }}>
                Expense
              </span>
            </span>
          </button>
        ))}
      </div>
    </>
  );
}
