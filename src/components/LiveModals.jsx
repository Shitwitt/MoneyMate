import React, { useState } from 'react';
import { X, Plus, Trash2, Check, Search, RotateCcw } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, fmtExact, fmtFull, usd, CURRENCIES, CURRENCY_SYMBOL, convert } from '../data/demoStore.js';
import {
  budgetMath,
  collectionData,
  balanceBreakdown,
  reportsData,
  accountBalances,
} from '../data/derive.js';
import { participantBalances } from '../data/engine.js';
import { HOME_SECTIONS } from '../data/liveData.js';

/* ============================================================
   Shared modal chrome + controlled form primitives
   ============================================================ */

export function ModalShell({ title, subtitle, onClose, children, footer, wide = false }) {
  return (
    <div className="modal-scrim" role="presentation" onMouseDown={onClose}>
      <section
        className={`modal-card${wide ? ' wide' : ''}`}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <header className="modal-head">
          <div>
            <h2>{title}</h2>
            {subtitle ? <p>{subtitle}</p> : null}
          </div>
          <button type="button" className="modal-x" aria-label="Close" onClick={onClose}>
            <X />
          </button>
        </header>
        <div className="modal-body">{children}</div>
        {footer ? <footer className="modal-foot">{footer}</footer> : null}
      </section>
    </div>
  );
}

function Field({ label, children, hint }) {
  return (
    <label className="form-field">
      <span>{label}</span>
      {children}
      {hint ? <small>{hint}</small> : null}
    </label>
  );
}

function Segmented({ value, onChange, options, name }) {
  return (
    <div className="form-segmented" role="group" aria-label={name}>
      {options.map((o) => (
        <button
          type="button"
          key={o.value}
          className={value === o.value ? 'on' : ''}
          aria-pressed={value === o.value}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

function ChipMulti({ options, value = [], onChange }) {
  const toggle = (v) => onChange(value.includes(v) ? value.filter((x) => x !== v) : [...value, v]);
  return (
    <div className="form-chips">
      {options.map((o) => (
        <button
          type="button"
          key={o.value}
          className={value.includes(o.value) ? 'on' : ''}
          aria-pressed={value.includes(o.value)}
          onClick={() => toggle(o.value)}
        >
          {value.includes(o.value) ? <Check /> : <Plus />}
          {o.label}
        </button>
      ))}
    </div>
  );
}

function InlineAdder({ label, collection, onAdded, extra = {} }) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState('');
  const [color, setColor] = useState('#7B4028');
  const [amount, setAmount] = useState('');
  const save = (e) => {
    e.preventDefault();
    const cleanName = name.trim();
    if (!cleanName) return;
    const item = {
      ...extra,
      name: cleanName,
      color,
      ...(collection === 'templates' || collection === 'recurring' ? { amount: Number(amount) || 0 } : {}),
    };
    demoStore.saveCollectionItem(collection, item);
    if (onAdded) onAdded(cleanName);
    setName('');
    setAmount('');
    setOpen(false);
  };
  if (!open) {
    return (
      <button type="button" className="inline-add" onClick={() => setOpen(true)}>
        <Plus /> {label}
      </button>
    );
  }
  return (
    <form className="inline-add-form" onSubmit={save}>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" aria-label={`${label} name`} autoFocus />
      {(collection === 'templates' || collection === 'recurring') ? (
        <input value={amount} onChange={(e) => setAmount(e.target.value)} type="number" step="0.01" placeholder="Amount" aria-label={`${label} amount`} />
      ) : null}
      <input type="color" value={color} onChange={(e) => setColor(e.target.value)} aria-label={`${label} color`} />
      <button type="submit" aria-label={`Save ${label}`}><Check /></button>
      <button type="button" onClick={() => setOpen(false)} aria-label={`Cancel ${label}`}><X /></button>
    </form>
  );
}

const toOptions = (items, valueKey = 'name', labelKey = 'name') =>
  items.map((x) => ({ value: x[valueKey], label: x[labelKey] || x.name || x.title }));

/* ============================================================
   Profile
   ============================================================ */

function ProfileModal() {
  const profile = useStore((s) => s.profile);
  const [name, setName] = useState(profile.name);
  const [baseCurrency, setBaseCurrency] = useState(profile.baseCurrency);
  const [liabilitiesOffset, setLiabilitiesOffset] = useState(profile.liabilitiesOffset);
  const [confirmClear, setConfirmClear] = useState(false);
  return (
    <ModalShell
      title="Your profile"
      subtitle="Live data is saved on this device."
      onClose={demoStore.closeModal}
      footer={
        <button
          type="button"
          className="btn primary"
          onClick={() => {
            demoStore.setProfile({ name: name.trim() || 'Raj', baseCurrency, liabilitiesOffset: Number(liabilitiesOffset) || 0 });
            demoStore.closeModal();
            demoStore.toast('Profile saved');
          }}
        >
          Save profile
        </button>
      }
    >
      <Field label="User name">
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Raj" />
      </Field>
      <Field label="Base currency">
        <select value={baseCurrency} onChange={(e) => setBaseCurrency(e.target.value)}>
          {CURRENCIES.map((c) => <option key={c} value={c}>{CURRENCY_SYMBOL[c]} {c}</option>)}
        </select>
      </Field>
      <Field label="Other liabilities / net-worth adjustment" hint="Included in the Total balance calculation.">
        <input type="number" step="0.01" value={liabilitiesOffset} onChange={(e) => setLiabilitiesOffset(e.target.value)} />
      </Field>
      <div className="modal-divider" />
      <div className="danger-zone">
        <div>
          <strong>Reset / Clear All Data</strong>
          <p>Wipes every account, transaction, budget, asset, bill, loan, goal and template. Balances become 0.</p>
        </div>
        {confirmClear ? (
          <div className="confirm-row">
            <button type="button" className="btn danger" onClick={() => { demoStore.clearAllData(); setConfirmClear(false); }}>
              Yes, clear everything
            </button>
            <button type="button" className="btn ghost" onClick={() => setConfirmClear(false)}>Cancel</button>
          </div>
        ) : (
          <button type="button" className="btn danger" onClick={() => setConfirmClear(true)}><Trash2 /> Clear all data</button>
        )}
        <button type="button" className="btn ghost" onClick={demoStore.restoreSampleData}><RotateCcw /> Restore sample records</button>
      </div>
    </ModalShell>
  );
}

/* ============================================================
   Universal Add / Edit Transaction
   ============================================================ */

function TransactionModal({ data }) {
  const state = useStore((s) => s);
  const base = state.profile.baseCurrency;
  const accounts = state.accounts;
  const [form, setForm] = useState(() => ({
    id: data.id || '',
    editing: Boolean(data.editing),
    type: data.type || 'expense',
    title: data.title || '',
    amount: data.amount ?? '',
    currency: data.currency || base,
    date: data.date || state.today,
    time: data.time || '09:00',
    account: data.account || accounts[0]?.name || '',
    from: data.from || data.account || accounts[0]?.name || '',
    to: data.to || accounts[1]?.name || accounts[0]?.name || '',
    category: data.category || '',
    budgetId: data.budgetId || '',
    loanId: data.loanId || '',
    goalId: data.goalId || '',
    person: data.person || '',
    place: data.place || '',
    labels: data.labels || [],
    notes: data.notes || '',
  }));
  const set = (patch) => setForm((f) => ({ ...f, ...patch }));
  const categories = state.categories.filter((c) => c.type === (form.type === 'income' ? 'income' : 'expense'));
  const numericAmount = Number(form.amount) || 0;
  const converted = convert(numericAmount, form.currency, base);
  const accountOptions = accounts.map((a) => ({ value: a.name, label: a.name }));

  const submit = (e) => {
    e.preventDefault();
    if (!numericAmount || !form.title.trim()) {
      demoStore.toast('Enter a title and an amount');
      return;
    }
    demoStore.saveTransaction({
      ...form,
      amount: numericAmount,
      account: form.type === 'transfer' ? form.from : form.account,
      from: form.type === 'transfer' ? form.from : null,
      to: form.type === 'transfer' ? form.to : null,
      category: form.type === 'transfer' ? '' : form.category,
      budgetId: form.budgetId || null,
      loanId: form.loanId || null,
      goalId: form.goalId || null,
      labels: form.labels,
    });
  };

  return (
    <ModalShell
      title={form.editing ? 'Edit transaction' : 'Add transaction'}
      subtitle="Every field is linked to live balances and charts."
      onClose={demoStore.closeModal}
      wide
      footer={
        <>
          {form.editing ? (
            <button type="button" className="btn danger" onClick={() => demoStore.deleteTransaction(form.id)}>
              <Trash2 /> Delete
            </button>
          ) : null}
          <button type="submit" form="transaction-form" className="btn primary">
            {form.editing ? 'Update transaction' : 'Save transaction'}
          </button>
        </>
      }
    >
      <form id="transaction-form" onSubmit={submit} className="modal-form">
        <Segmented
          name="Transaction type"
          value={form.type}
          onChange={(v) => set({ type: v, category: '' })}
          options={[{ value: 'expense', label: 'Expense' }, { value: 'income', label: 'Income' }, { value: 'transfer', label: 'Transfer' }]}
        />

        <Field label="Title / description">
          <input value={form.title} onChange={(e) => set({ title: e.target.value })} placeholder="Coffee, Salary, Fuel…" />
        </Field>

        <div className="form-grid two">
          <Field label="Amount">
            <input type="number" step="0.01" min="0" value={form.amount} onChange={(e) => set({ amount: e.target.value })} placeholder="0.00" />
          </Field>
          <Field label="Currency">
            <select value={form.currency} onChange={(e) => set({ currency: e.target.value })}>
              {CURRENCIES.map((c) => <option key={c} value={c}>{CURRENCY_SYMBOL[c]} {c}</option>)}
            </select>
          </Field>
        </div>
        {form.currency !== base ? (
          <p className="conversion-note">≈ {fmtExact(converted, base)} in {base}</p>
        ) : null}

        <div className="form-grid two">
          <Field label="Date">
            <input type="date" value={form.date} onChange={(e) => set({ date: e.target.value })} />
          </Field>
          <Field label="Time">
            <input type="time" value={form.time} onChange={(e) => set({ time: e.target.value })} />
          </Field>
        </div>

        {form.type === 'transfer' ? (
          <div className="form-grid two">
            <Field label="From account">
              <select value={form.from} onChange={(e) => set({ from: e.target.value })}>{accountOptions.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}</select>
            </Field>
            <Field label="To account">
              <select value={form.to} onChange={(e) => set({ to: e.target.value })}>{accountOptions.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}</select>
            </Field>
          </div>
        ) : (
          <Field label="Account">
            <select value={form.account} onChange={(e) => set({ account: e.target.value })}>{accountOptions.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}</select>
          </Field>
        )}

        {form.type !== 'transfer' ? (
          <>
            <Field label="Category">
              <div className="field-with-add">
                <select value={form.category} onChange={(e) => set({ category: e.target.value })}>
                  <option value="">Select category</option>
                  {categories.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}
                </select>
                <InlineAdder
                  label="Add category"
                  collection="categories"
                  extra={{ type: form.type, icon: 'wallet' }}
                  onAdded={(name) => set({ category: name })}
                />
              </div>
            </Field>

            <div className="form-grid two">
              <Field label="Link to budget">
                <select value={form.budgetId} onChange={(e) => set({ budgetId: e.target.value })}>
                  <option value="">None</option>
                  {state.budgets.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
                </select>
              </Field>
              <Field label="Link to loan">
                <select value={form.loanId} onChange={(e) => set({ loanId: e.target.value })}>
                  <option value="">None</option>
                  {state.loans.map((l) => <option key={l.id} value={l.id}>{l.title}</option>)}
                </select>
              </Field>
            </div>
            <Field label="Link to goal">
              <select value={form.goalId} onChange={(e) => set({ goalId: e.target.value })}>
                <option value="">None</option>
                {state.goals.map((g) => <option key={g.id} value={g.id}>{g.title}</option>)}
              </select>
            </Field>

            <div className="form-grid two">
              <Field label="Person">
                <div className="field-with-add">
                  <select value={form.person} onChange={(e) => set({ person: e.target.value })}>
                    <option value="">None</option>
                    {state.people.map((p) => <option key={p.id} value={p.name}>{p.name}</option>)}
                  </select>
                  <InlineAdder label="Add person" collection="people" onAdded={(name) => set({ person: name })} />
                </div>
              </Field>
              <Field label="Place">
                <div className="field-with-add">
                  <select value={form.place} onChange={(e) => set({ place: e.target.value })}>
                    <option value="">None</option>
                    {state.places.map((p) => <option key={p.id} value={p.name}>{p.name}</option>)}
                  </select>
                  <InlineAdder label="Add place" collection="places" onAdded={(name) => set({ place: name })} />
                </div>
              </Field>
            </div>
            <Field label="Labels">
              <div className="field-with-add">
                <ChipMulti
                  options={state.labels.map((l) => ({ value: l.name, label: l.name }))}
                  value={form.labels}
                  onChange={(labels) => set({ labels })}
                />
                <InlineAdder label="Add label" collection="labels" onAdded={(name) => set({ labels: [...form.labels, name] })} />
              </div>
            </Field>
          </>
        ) : null}

        <Field label="Notes">
          <textarea value={form.notes} onChange={(e) => set({ notes: e.target.value })} placeholder="Optional" rows="2" />
        </Field>
      </form>
    </ModalShell>
  );
}

/* ============================================================
   Account / Budget / Template editors
   ============================================================ */

function AccountModal({ data }) {
  const [form, setForm] = useState(data);
  const set = (patch) => setForm((f) => ({ ...f, ...patch }));
  return (
    <ModalShell
      title={form.editing ? 'Edit account' : 'Add account'}
      subtitle="Saving updates the carousel and Total balance."
      onClose={demoStore.closeModal}
      footer={
        <>
          {form.editing ? <button type="button" className="btn danger" onClick={() => demoStore.deleteAccount(form.id)}><Trash2 /> Delete</button> : null}
          <button type="submit" form="account-form" className="btn primary">Save account</button>
        </>
      }
    >
      <form id="account-form" className="modal-form" onSubmit={(e) => { e.preventDefault(); demoStore.saveAccount(form); }}>
        <Field label="Account name"><input value={form.name} onChange={(e) => set({ name: e.target.value })} /></Field>
        <Field label="Account holder name"><input value={form.holder} onChange={(e) => set({ holder: e.target.value })} /></Field>
        <div className="form-grid two">
          <Field label="Initial / current balance"><input type="number" step="0.01" value={form.balance} onChange={(e) => set({ balance: e.target.value })} /></Field>
          <Field label="Last 4 digits"><input value={form.last4} maxLength={4} onChange={(e) => set({ last4: e.target.value.replace(/\D/g, '') })} /></Field>
        </div>
        <div className="form-grid two">
          <Field label="Account type">
            <select value={form.type} onChange={(e) => set({ type: e.target.value })}>
              {['Bank', 'Card', 'Cash', 'Wallet'].map((x) => <option key={x} value={x}>{x}</option>)}
            </select>
          </Field>
          <Field label="Currency">
            <select value={form.currency} onChange={(e) => set({ currency: e.target.value })}>
              {CURRENCIES.map((c) => <option key={c} value={c}>{CURRENCY_SYMBOL[c]} {c}</option>)}
            </select>
          </Field>
        </div>
        <Field label="Color"><input type="color" value={form.color} onChange={(e) => set({ color: e.target.value })} /></Field>
        <label className="form-check"><input type="checkbox" checked={form.includeInTotals} onChange={(e) => set({ includeInTotals: e.target.checked })} /> Include in totals</label>
      </form>
    </ModalShell>
  );
}

function BudgetModal({ data }) {
  const categories = useStore((s) => s.categories.filter((c) => c.type === 'expense'));
  const [form, setForm] = useState(data);
  const set = (patch) => setForm((f) => ({ ...f, ...patch }));
  const preview = useStore((s) => budgetMath(form, s));
  return (
    <ModalShell
      title={form.editing ? 'Edit budget' : 'Add budget'}
      subtitle={`Live: spent ${fmtFull(preview.spent)} · remaining ${fmtFull(preview.remaining)} · ${preview.usedPct}% used`}
      onClose={demoStore.closeModal}
      wide
      footer={
        <>
          {form.editing ? <button type="button" className="btn danger" onClick={() => demoStore.deleteBudget(form.id)}><Trash2 /> Delete</button> : null}
          <button type="submit" form="budget-form" className="btn primary">Save budget</button>
        </>
      }
    >
      <form id="budget-form" className="modal-form" onSubmit={(e) => { e.preventDefault(); demoStore.saveBudget(form); }}>
        <Field label="Budget name"><input value={form.name} onChange={(e) => set({ name: e.target.value })} /></Field>
        <div className="form-grid two">
          <Field label="Budget limit"><input type="number" step="0.01" value={form.limit} onChange={(e) => set({ limit: e.target.value })} /></Field>
          <Field label="Budget for">
            <select value={form.for} onChange={(e) => set({ for: e.target.value })}>
              <option value="Expense">Expense</option><option value="Income">Income</option>
            </select>
          </Field>
        </div>
        <div className="form-grid two">
          <Field label="Budget type">
            <select value={form.type} onChange={(e) => set({ type: e.target.value })}>
              <option value="Category">Category</option><option value="Overall">Overall</option>
            </select>
          </Field>
          <Field label="Budget mode">
            <select value={form.mode} onChange={(e) => set({ mode: e.target.value })}>
              <option value="Automatic">Automatic</option><option value="Manual">Manual</option>
            </select>
          </Field>
        </div>
        <div className="form-grid two">
          <Field label="Period">
            <select value={form.period} onChange={(e) => set({ period: e.target.value })}>
              {['Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom'].map((x) => <option key={x} value={x}>{x}</option>)}
            </select>
          </Field>
          <Field label="Color"><input type="color" value={form.color} onChange={(e) => set({ color: e.target.value })} /></Field>
        </div>
        <div className="form-grid two">
          <Field label="Start date"><input type="date" value={form.start} onChange={(e) => set({ start: e.target.value })} /></Field>
          <Field label="End date"><input type="date" value={form.end} onChange={(e) => set({ end: e.target.value })} /></Field>
        </div>
        <Field label="Linked categories">
          <ChipMulti options={categories.map((c) => ({ value: c.name, label: c.name }))} value={form.categories} onChange={(v) => set({ categories: v })} />
        </Field>
        <div className="live-math">
          <span>Daily safe spend</span><b>{fmtFull(preview.dailySafeSpend)}/day for {preview.daysLeft} more days</b>
        </div>
      </form>
    </ModalShell>
  );
}

function TemplateModal({ data }) {
  const categories = useStore((s) => s.categories);
  const [form, setForm] = useState(data);
  const set = (patch) => setForm((f) => ({ ...f, ...patch }));
  return (
    <ModalShell
      title={form.editing ? 'Edit template' : 'Add template'}
      onClose={demoStore.closeModal}
      footer={
        <>
          {form.editing ? <button type="button" className="btn danger" onClick={() => demoStore.deleteTemplate(form.id)}><Trash2 /> Delete</button> : null}
          <button type="submit" form="template-form" className="btn primary">Save template</button>
        </>
      }
    >
      <form id="template-form" className="modal-form" onSubmit={(e) => { e.preventDefault(); demoStore.saveTemplate(form); }}>
        <Field label="Template name"><input value={form.name} onChange={(e) => set({ name: e.target.value })} placeholder="Ex: Trip to Japan" /></Field>
        <div className="form-grid two">
          <Field label="Amount"><input type="number" step="0.01" value={form.amount} onChange={(e) => set({ amount: e.target.value })} /></Field>
          <Field label="Type"><select value={form.type} onChange={(e) => set({ type: e.target.value })}><option value="expense">Expense</option><option value="income">Income</option></select></Field>
        </div>
        <Field label="Category"><select value={form.category} onChange={(e) => set({ category: e.target.value })}><option value="">None</option>{categories.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}</select></Field>
        <Field label="Color"><input type="color" value={form.color} onChange={(e) => set({ color: e.target.value })} /></Field>
      </form>
    </ModalShell>
  );
}


function FeedbackModal() {
  const feedback = useStore((s) => s.status.feedback || '');
  const [text, setText] = useState(feedback);
  return (
    <ModalShell
      title="Feedback"
      subtitle="Saved on this device with your live profile."
      onClose={demoStore.closeModal}
      footer={
        <button
          type="button"
          className="btn primary"
          onClick={() => { demoStore.saveFeedback(text); demoStore.closeModal(); demoStore.toast('Feedback saved'); }}
        >
          Save feedback
        </button>
      }
    >
      <Field label="Your notes">
        <textarea value={text} onChange={(e) => setText(e.target.value)} rows="5" placeholder="Tell us what should improve…" />
      </Field>
      <p className="empty-note">{text.length} characters</p>
    </ModalShell>
  );
}

/* ============================================================
   Generic collection manager, layout, balance breakdown
   ============================================================ */

function CollectionModal({ data }) {
  const name = data.name || 'templates';
  const collection = useStore((s) => collectionData(s, name));
  const [draft, setDraft] = useState({ name: '', amount: '', color: '#7B4028', type: 'expense', category: '', date: '' });
  const [editing, setEditing] = useState(null);
  const startEdit = (item) => {
    setEditing(item.id);
    setDraft({ ...item });
  };
  const save = (e) => {
    e.preventDefault();
    const item = { ...draft, id: editing || undefined };
    if (name === 'categories') item.type = draft.type || 'expense';
    demoStore.saveCollectionItem(name, item);
    setEditing(null);
    setDraft({ name: '', amount: '', color: '#7B4028', type: 'expense', category: '', date: '' });
  };
  return (
    <ModalShell title={collection.title} subtitle={`${collection.items.length} live records — edit or delete individually.`} onClose={demoStore.closeModal} wide>
      <div className="collection-list">
        {collection.items.map((item) => (
          <div className="collection-row" key={item.id}>
            <span className="collection-dot" style={{ background: item.color || '#7B4028' }} />
            <div>
              <strong>{item.name || item.title}</strong>
              <small>{item.amount != null ? fmtFull(Number(item.amount)) : item.type || ''}</small>
            </div>
            <button type="button" aria-label={`Edit ${item.name}`} onClick={() => startEdit(item)}>Edit</button>
            <button type="button" className="danger-icon" aria-label={`Delete ${item.name}`} onClick={() => demoStore.deleteCollectionItem(name, item.id)}><Trash2 /></button>
          </div>
        ))}
        {collection.items.length === 0 ? <p className="empty-note">No {name} yet. Add one below.</p> : null}
      </div>
      <form className="modal-form collection-form" onSubmit={save}>
        <h3>{editing ? 'Edit record' : `Add ${name.slice(0, -1)}`}</h3>
        <Field label="Name"><input value={draft.name || ''} onChange={(e) => setDraft({ ...draft, name: e.target.value })} /></Field>
        {(name === 'templates' || name === 'recurring') ? (
          <div className="form-grid two">
            <Field label="Amount"><input type="number" step="0.01" value={draft.amount || ''} onChange={(e) => setDraft({ ...draft, amount: e.target.value })} /></Field>
            {name === 'recurring' ? <Field label="Date"><input type="date" value={draft.date || ''} onChange={(e) => setDraft({ ...draft, date: e.target.value })} /></Field> : null}
          </div>
        ) : null}
        {name === 'categories' ? (
          <Field label="Category type"><select value={draft.type || 'expense'} onChange={(e) => setDraft({ ...draft, type: e.target.value })}><option value="expense">Expense</option><option value="income">Income</option></select></Field>
        ) : null}
        <Field label="Color"><input type="color" value={draft.color || '#7B4028'} onChange={(e) => setDraft({ ...draft, color: e.target.value })} /></Field>
        <button type="submit" className="btn primary">Save</button>
      </form>
    </ModalShell>
  );
}

function LayoutModal() {
  const active = useStore((s) => s.homeSections);
  return (
    <ModalShell title="Customize dashboard" subtitle="Show or hide live home sections." onClose={demoStore.closeModal}>
      <div className="layout-list">
        {HOME_SECTIONS.map((s) => (
          <label key={s.id} className="form-check">
            <input type="checkbox" checked={active.includes(s.id)} onChange={() => demoStore.toggleHomeSection(s.id)} />
            {s.label}
          </label>
        ))}
      </div>
    </ModalShell>
  );
}

function BalanceModal() {
  const data = useStore((s) => balanceBreakdown(s));
  const accounts = useStore((s) => accountBalances(s));
  return (
    <ModalShell title="Balance breakdown" subtitle={`All figures in ${data.base}.`} onClose={demoStore.closeModal} wide>
      <div className="balance-total">{fmtFull(data.total, data.base)}</div>
      <div className="collection-list">
        {accounts.map((a) => (
          <button type="button" className="collection-row clickable" key={a.id} onClick={() => demoStore.openAccountEditor(a.id)}>
            <span className="collection-dot" style={{ background: a.color }} />
            <div><strong>{a.name}</strong><small>{a.holder} · {a.type}</small></div>
            <b>{fmtFull(a.balance, data.base)}</b>
          </button>
        ))}
        <div className="collection-row">
          <span className="collection-dot" style={{ background: '#B0A19A' }} />
          <div><strong>Other liabilities</strong><small>Editable in profile</small></div>
          <b>{fmtFull(data.liabilities, data.base)}</b>
        </div>
      </div>
    </ModalShell>
  );
}

function ReportDetailModal({ data }) {
  const report = useStore((s) => reportsData(s));
  const groups = report.donut;
  return (
    <ModalShell title={`${data.id || 'Financial'} report`} subtitle={`${report.month} · ${report.txCount} transactions`} onClose={demoStore.closeModal} wide>
      <div className="collection-list">
        {groups.map((g) => (
          <button type="button" className="collection-row clickable" key={g.label} onClick={() => { demoStore.closeModal(); demoStore.openSearch(g.label); }}>
            <span className="collection-dot" style={{ background: g.color }} />
            <div><strong>{g.label}</strong><small>{g.count} transactions · {g.pct.toFixed(1)}%</small></div>
            <b>{fmtFull(g.amount)}</b>
          </button>
        ))}
        {groups.length === 0 ? <p className="empty-note">No transactions for this selection.</p> : null}
      </div>
    </ModalShell>
  );
}

/* ============================================================
   Context payment editors
   ============================================================ */

function PaymentModal({ data }) {
  const bill = useStore((s) => s.bills.find((b) => b.id === data.billId));
  const balances = bill ? participantBalances(bill) : [];
  const row = balances.find((p) => p.id === data.participantId) || balances[0];
  const share = row ? row.share / 100 : 0;
  const owed = row ? row.owes / 100 : 0;
  const [amount, setAmount] = useState(data.mode === 'markPaid' ? share : owed);
  if (!bill || !row) return null;
  return (
    <ModalShell title="Record payment" subtitle={`${row.name} · ${bill.title}`} onClose={demoStore.closeModal}
      footer={
        <>
          <button type="button" className="btn ghost" onClick={() => setAmount(share)}>Mark fully paid</button>
          <button type="submit" form="payment-form" className="btn primary">Save payment</button>
        </>
      }>
      <form id="payment-form" className="modal-form" onSubmit={(e) => { e.preventDefault(); demoStore.setParticipantPaid(bill.id, row.id, Number(amount)); }}>
        <div className="live-math"><span>Share</span><b>{usd(share)}</b></div>
        <div className="live-math"><span>Currently owes</span><b>{usd(owed)}</b></div>
        <Field label="Amount paid"><input type="number" step="0.01" min="0" value={amount} onChange={(e) => setAmount(e.target.value)} /></Field>
      </form>
    </ModalShell>
  );
}

function LoanPaymentModal({ data }) {
  const loan = useStore((s) => s.loans.find((l) => l.id === data.loanId) || s.loans[0]);
  const accounts = useStore((s) => s.accounts);
  const math = useStore((s) => (loan ? demoStore.loanMathFor(loan.id) : null));
  const [form, setForm] = useState(data);
  const set = (patch) => setForm((f) => ({ ...f, ...patch }));
  if (!loan) return null;
  return (
    <ModalShell title="Record loan payment / charge" subtitle={`Outstanding ${usd((math?.remaining || 0) / 100)}`} onClose={demoStore.closeModal}
      footer={<button type="submit" form="loan-payment-form" className="btn primary">Save</button>}>
      <form id="loan-payment-form" className="modal-form" onSubmit={(e) => { e.preventDefault(); demoStore.recordLoanPayment(loan.id, Number(form.amount), { date: form.date, account: form.account, type: form.type }); }}>
        <Segmented name="Entry type" value={form.type} onChange={(type) => set({ type })} options={[{ value: 'repayment', label: 'Repayment' }, { value: 'charge', label: 'Additional charge' }]} />
        <Field label="Amount"><input type="number" step="0.01" min="0" value={form.amount} onChange={(e) => set({ amount: e.target.value })} /></Field>
        <div className="form-grid two">
          <Field label="Date"><input type="date" value={form.date} onChange={(e) => set({ date: e.target.value })} /></Field>
          <Field label="Account"><select value={form.account} onChange={(e) => set({ account: e.target.value })}>{accounts.map((a) => <option key={a.id} value={a.name}>{a.name}</option>)}</select></Field>
        </div>
      </form>
    </ModalShell>
  );
}

function GoalDepositModal({ data }) {
  const goal = useStore((s) => s.goals.find((g) => g.id === data.goalId) || s.goals[0]);
  const accounts = useStore((s) => s.accounts);
  const [form, setForm] = useState(data);
  const set = (patch) => setForm((f) => ({ ...f, ...patch }));
  if (!goal) return null;
  return (
    <ModalShell title="Add savings" subtitle={goal.title} onClose={demoStore.closeModal}
      footer={<button type="submit" form="goal-deposit-form" className="btn primary">Save</button>}>
      <form id="goal-deposit-form" className="modal-form" onSubmit={(e) => {
        e.preventDefault();
        demoStore.addGoalTransaction(goal.id, { amount: Number(form.amount), type: form.type === 'withdraw' ? 'expense' : 'income', date: form.date, account: form.account });
      }}>
        <Segmented name="Movement" value={form.type} onChange={(type) => set({ type })} options={[{ value: 'deposit', label: 'Deposit' }, { value: 'withdraw', label: 'Withdrawal' }]} />
        <Field label="Amount"><input type="number" step="0.01" min="0" value={form.amount} onChange={(e) => set({ amount: e.target.value })} /></Field>
        <div className="form-grid two">
          <Field label="Date"><input type="date" value={form.date} onChange={(e) => set({ date: e.target.value })} /></Field>
          <Field label="Account"><select value={form.account} onChange={(e) => set({ account: e.target.value })}>{accounts.map((a) => <option key={a.id} value={a.name}>{a.name}</option>)}</select></Field>
        </div>
      </form>
    </ModalShell>
  );
}

/* ============================================================
   Router
   ============================================================ */

export default function LiveModals() {
  const modal = useStore((s) => s.ui.modal);
  const data = useStore((s) => s.ui.modalData);
  if (!modal) return null;
  const key = `${modal}-${data?.id || data?.name || data?.billId || 'new'}`;
  const props = { data: data || {} };
  const MODALS = {
    profile: ProfileModal,
    transaction: TransactionModal,
    account: AccountModal,
    budget: BudgetModal,
    template: TemplateModal,
    collection: CollectionModal,
    layout: LayoutModal,
    feedback: FeedbackModal,
    balance: BalanceModal,
    reportDetail: ReportDetailModal,
    payment: PaymentModal,
    loanPayment: LoanPaymentModal,
    goalDeposit: GoalDepositModal,
  };
  const Current = MODALS[modal];
  return Current ? <Current key={key} {...props} /> : null;
}
