import React from 'react';
import { Plus, Users, Check } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { toCents, billShares, participantBalances, fmtMoney } from '../data/engine.js';
import { DarkHeader, SegmentedBar } from '../components/step3/ui3.jsx';
import { AddMini } from '../components/step4/ui4.jsx';

export default function BillEditorView() {
  const params = useStore((s) => s.route.params);
  const bills = useStore((s) => s.bills);
  const contactList = useStore((s) => s.people);
  const [addPersonOpen, setAddPersonOpen] = React.useState(false);
  const existing = bills.find((b) => b.id === params.id);

  const [title, setTitle] = React.useState(existing?.title || '');
  const [total, setTotal] = React.useState(existing ? String(existing.total) : '');
  const [mode, setMode] = React.useState(existing?.mode || 'equal');
  const [people, setPeople] = React.useState(() =>
    existing
      ? existing.participants.map((p) => ({ ...p }))
      : [contactList[0], contactList[1]].filter(Boolean).map((c, i) => ({ ...c, percent: 50, share: 0, paid: 0, payer: i === 0 })),
  );

  const totalCents = toCents(Number(total) || 0);
  const draft = {
    total: totalCents / 100,
    mode,
    payerId: (people.find((p) => p.payer) || people[0])?.id,
    participants: people,
  };
  const shares = billShares(draft);
  const rows = participantBalances(draft);

  const togglePerson = (c) => {
    setPeople((prev) =>
      prev.some((p) => p.id === c.id) ? prev.filter((p) => p.id !== c.id) : [...prev, { ...c, percent: 0, share: 0, paid: 0 }],
    );
  };

  const setPayer = (id) => {
    setPeople((prev) => prev.map((p) => ({ ...p, payer: p.id === id })));
  };

  const setPercent = (id, v) => {
    setPeople((prev) => prev.map((p) => (p.id === id ? { ...p, percent: Number(v) || 0 } : p)));
  };

  const setShare = (id, v) => {
    setPeople((prev) => prev.map((p) => (p.id === id ? { ...p, share: Number(v) || 0 } : p)));
  };

  const pctSum = people.reduce((a, p) => a + (Number(p.percent) || 0), 0);

  const save = () => {
    const pctTotal = people.reduce((a, p) => a + (Number(p.percent) || 0), 0) || 100;
    const normalised = people.map((p) => ({
      ...p,
      // percentages are normalised so they always sum to 100
      percent: mode === 'percentage' ? ((Number(p.percent) || 0) / pctTotal) * 100 : 100 / people.length,
      share: mode === 'custom' ? Number(p.share) || 0 : 0,
      paid: p.payer ? 0 : Number(p.paid) || 0,
    }));
    const bill = {
      id: existing?.id || `bs${Date.now()}`,
      title: title.trim() || 'Untitled bill',
      total: totalCents / 100,
      mode,
      iconBg: existing?.iconBg || '#43A047',
      icon: 'wallet',
      payerId: (normalised.find((p) => p.payer) || normalised[0])?.id,
      participants: normalised.map(({ payer, ...p }) => p),
    };
    demoStore.saveBill(bill);
  };

  return (
    <div className="view dark-view bill-editor">
      <DarkHeader title={existing ? 'Edit Bill Splitter' : 'New Bill Splitter'} />

      <label className="d-input-wrap">
        <span className="d-label">Title</span>
        <input
          className="d-input"
          value={title}
          placeholder="e.g. Road Trip Expenses"
          onChange={(e) => setTitle(e.target.value)}
        />
      </label>

      <label className="d-input-wrap">
        <span className="d-label">Total amount</span>
        <input
          className="d-input"
          value={total}
          inputMode="decimal"
          placeholder="0.00"
          onChange={(e) => setTotal(e.target.value.replace(/[^0-9.]/g, ''))}
        />
      </label>

      <div className="d-block">
        <span className="d-label">Split type</span>
        <SegmentedBar
          options={[
            { id: 'equal', label: 'Equal' },
            { id: 'percentage', label: 'Percentage' },
            { id: 'custom', label: 'Custom' },
          ]}
          value={mode}
          onChange={setMode}
        />
      </div>

      <div className="d-block">
        <span className="d-label">
          <Users /> Participants
        </span>
        <div className="contact-row">
          {contactList.map((c) => {
            const on = people.some((p) => p.id === c.id);
            return (
              <button
                key={c.id}
                type="button"
                className={`contact-chip${on ? ' on' : ''}`}
                style={on ? { borderColor: c.color } : undefined}
                onClick={() => togglePerson(c)}
              >
                <span className="avatar sm" style={{ background: c.color }}>
                  {c.name.charAt(0)}
                </span>
                {c.name}
                {on ? <Check className="cc-check" /> : <Plus className="cc-check" />}
              </button>
            );
          })}
          <button type="button" className="contact-chip" onClick={() => setAddPersonOpen(true)}><Plus /> Add person</button>
        </div>
      </div>

      {addPersonOpen ? (
        <AddMini title="Add person" placeholder="Name" onSave={(name) => demoStore.savePerson({ name, color: '#00897B' })} onClose={() => setAddPersonOpen(false)} />
      ) : null}

      {mode === 'percentage' ? (
        <div className="d-block">
          <span className="d-label">
            Percentages {pctSum !== 100 ? <em>({pctSum}% — normalised on save)</em> : null}
          </span>
          {people.map((p) => (
            <div className="pct-row" key={p.id}>
              <span>{p.name}</span>
              <input
                className="pct-input"
                value={p.percent}
                inputMode="decimal"
                aria-label={`${p.name} percentage`}
                onChange={(e) => setPercent(p.id, e.target.value.replace(/[^0-9.]/g, ''))}
              />
              <span className="pct-amount">{fmtMoney(shares[people.indexOf(p)] || 0)}</span>
            </div>
          ))}
        </div>
      ) : null}

      {mode === 'custom' ? (
        <div className="d-block">
          <span className="d-label">Custom shares</span>
          {people.map((p) => (
            <div className="pct-row" key={p.id}>
              <span>{p.name}</span>
              <input className="pct-input" value={p.share} inputMode="decimal" aria-label={`${p.name} custom share`} onChange={(e) => setShare(p.id, e.target.value.replace(/[^0-9.]/g, ''))} />
              <span className="pct-amount">{fmtMoney(toCents(Number(p.share) || 0))}</span>
            </div>
          ))}
        </div>
      ) : null}

      <div className="d-block">
        <span className="d-label">Who paid?</span>
        <div className="payer-row">
          {people.map((p) => (
            <button
              key={p.id}
              type="button"
              className={`payer-btn${p.payer ? ' on' : ''}`}
              onClick={() => setPayer(p.id)}
            >
              {p.name}
            </button>
          ))}
        </div>
      </div>

      <div className="d-block">
        <span className="d-label">Shares</span>
        {rows.map((r) => (
          <div className="share-row" key={r.id}>
            <span>{r.name}</span>
            <span className="share-amt">{fmtMoney(r.share)}</span>
          </div>
        ))}
        <p className="d-hint">
          Shares reconcile to {fmtMoney(totalCents)} using the largest-remainder method.
        </p>
      </div>

      <button type="button" className="dark-submit" onClick={save}>
        {existing ? 'Update bill' : 'Create bill'}
      </button>
    </div>
  );
}
