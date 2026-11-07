import React from 'react';
import { Users } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { contacts } from '../data/step3Data.js';
import { toCents } from '../data/engine.js';
import { DarkHeader, SegmentedBar } from '../components/step3/ui3.jsx';

const KIND_STYLE = {
  lending: { accent: '#3949AB', surface: '#252542', textSoft: '#A5A7C4', track: '#343559', fill: '#5C6BC0', pillBg: '#2F3159', pillFg: '#5C6BC0' },
  borrowing: { accent: '#8E24AA', surface: '#2A1F2E', textSoft: '#BBA8C0', track: '#3E2C45', fill: '#AB47BC', pillBg: '#3A2B41', pillFg: '#BA68C8' },
};

export default function LoanEditorView() {
  const params = useStore((s) => s.route.params);
  const loans = useStore((s) => s.loans);
  const existing = loans.find((l) => l.id === params.id);

  const [kind, setKind] = React.useState(existing?.kind || 'lending');
  const [title, setTitle] = React.useState(existing?.title || '');
  const [person, setPerson] = React.useState(existing?.person || contacts[0].name);
  const [total, setTotal] = React.useState(existing ? String(existing.total) : '');
  const [paid, setPaid] = React.useState(existing ? String(existing.paid) : '0');
  const [due, setDue] = React.useState(existing?.due || '2027-11-19');
  const [account, setAccount] = React.useState(existing?.account || 'Demo Bank');

  const save = () => {
    const style = KIND_STYLE[kind];
    const loan = {
      id: existing?.id || `ln${Date.now()}`,
      title: title.trim() || 'Untitled loan',
      subtitle: existing?.subtitle || `${kind === 'lending' ? 'Lent to' : 'Borrowed from'} ${person}`,
      kind,
      person,
      total: toCents(Number(total) || 0) / 100,
      paid: Math.min(toCents(Number(total) || 0), toCents(Number(paid) || 0)) / 100,
      due,
      account,
      tileFg: '#FFFFFF',
      ...style,
    };
    demoStore.saveLoan(loan);
  };

  return (
    <div className="view dark-view loan-editor">
      <DarkHeader title={existing ? 'Edit Loan' : 'New Loan'} />

      <div className="d-block">
        <span className="d-label">Type</span>
        <SegmentedBar
          options={[
            { id: 'lending', label: 'Lending' },
            { id: 'borrowing', label: 'Borrowing' },
          ]}
          value={kind}
          onChange={setKind}
        />
      </div>

      <label className="d-input-wrap">
        <span className="d-label">Title</span>
        <input className="d-input" value={title} placeholder="e.g. Car Loan" onChange={(e) => setTitle(e.target.value)} />
      </label>

      <div className="d-block">
        <span className="d-label">
          <Users /> Person
        </span>
        <div className="contact-row">
          {contacts.map((c) => (
            <button
              key={c.id}
              type="button"
              className={`contact-chip${person === c.name ? ' on' : ''}`}
              style={person === c.name ? { borderColor: c.color } : undefined}
              onClick={() => setPerson(c.name)}
            >
              <span className="avatar sm" style={{ background: c.color }}>
                {c.name.charAt(0)}
              </span>
              {c.name}
            </button>
          ))}
        </div>
      </div>

      <label className="d-input-wrap">
        <span className="d-label">Principal amount</span>
        <input
          className="d-input"
          value={total}
          inputMode="decimal"
          placeholder="0.00"
          onChange={(e) => setTotal(e.target.value.replace(/[^0-9.]/g, ''))}
        />
      </label>

      <label className="d-input-wrap">
        <span className="d-label">Already paid</span>
        <input
          className="d-input"
          value={paid}
          inputMode="decimal"
          placeholder="0.00"
          onChange={(e) => setPaid(e.target.value.replace(/[^0-9.]/g, ''))}
        />
      </label>

      <label className="d-input-wrap">
        <span className="d-label">Due date</span>
        <input className="d-input" type="date" value={due} onChange={(e) => setDue(e.target.value)} />
      </label>

      <label className="d-input-wrap">
        <span className="d-label">Account</span>
        <input className="d-input" value={account} onChange={(e) => setAccount(e.target.value)} />
      </label>

      <button type="button" className="dark-submit" onClick={save}>
        {existing ? 'Update loan' : 'Create loan'}
      </button>
    </div>
  );
}
