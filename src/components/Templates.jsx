import React from 'react';
import { Banknote, Plus } from 'lucide-react';

import { SectionHead } from './ui.jsx';
import { demoStore, fmtFull, maskFor } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';

export default function Templates() {
  const templates = useStore((s) => s.templates);
  const privacy = useStore((s) => s.privacy);
  const base = useStore((s) => s.profile.baseCurrency);
  const mask = maskFor(base);

  const useTemplate = (t) => {
    demoStore.openTransactionEditor({
      title: t.name,
      amount: t.amount,
      type: t.type,
      category: t.category,
      date: demoStore.getState().today,
    });
  };

  return (
    <section className="templates-section" aria-label="Templates">
      <SectionHead title="Templates" action="See all" onAction={() => demoStore.openCollection('templates')} />
      <div className="templates-row">
        {templates.map((t) => (
          <button type="button" key={t.id} className="template-card" onClick={() => useTemplate(t)} aria-label={`Use ${t.name} template`}>
            <span className="template-icon" style={{ background: t.color }}><Banknote /></span>
            <strong>{t.name}</strong>
            <small>{privacy ? mask : fmtFull(t.amount, base)}</small>
          </button>
        ))}
        <button type="button" className="template-card add" onClick={() => demoStore.openTemplateEditor()} aria-label="Add template">
          <span className="template-icon"><Plus /></span>
          <strong>Add template</strong>
          <small>Custom</small>
        </button>
      </div>
    </section>
  );
}
