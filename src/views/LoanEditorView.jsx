import React from 'react';
import { UserRound, CalendarDays, Save } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { accountCatalog, expenseCategories, incomeCategories } from '../data/step4Data.js';
import { SegmentedBar } from '../components/step3/ui3.jsx';
import {
  ColorPicker,
  AccountPicker,
  CategoryPicker,
  PersonPicker,
  AddMini,
} from '../components/step4/ui4.jsx';

const PEOPLE = ['Alice', 'Bob', 'Carol', 'Dan'];

/** 16619 -> "16619.0" (the reference always shows one decimal) */
function oneDecimal(v) {
  if (v === '' || v == null) return '';
  const n = Number(v);
  if (Number.isNaN(n)) return String(v);
  return Number.isInteger(n) ? n.toFixed(1) : String(n);
}

function usDate(iso) {
  if (!iso) return '--/--/----';
  const d = new Date(`${iso}T00:00:00`);
  return d.toLocaleDateString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' });
}

export default function LoanEditorView() {
  const params = useStore((s) => s.route.params);
  const loans = useStore((s) => s.loans);
  const existing = loans.find((l) => l.id === params.id);

  const [kind, setKind] = React.useState(existing?.kind || 'lending');
  const [title, setTitle] = React.useState(existing?.title || '');
  const [amount, setAmount] = React.useState(existing ? oneDecimal(existing.amount) : '');
  const [notes, setNotes] = React.useState(existing?.notes || '');
  const [start, setStart] = React.useState(existing?.start || '2026-08-13');
  const [end, setEnd] = React.useState(existing?.end || '2027-11-19');
  const [person, setPerson] = React.useState(existing?.person || 'Alice');
  const [account, setAccount] = React.useState(existing?.account || '');
  const [category, setCategory] = React.useState(existing?.category || '');
  const [primary, setPrimary] = React.useState(existing?.color || '#3F51B5');
  const [accent, setAccent] = React.useState(existing?.accent || '#FF9C27');
  const [people, setPeople] = React.useState(PEOPLE);
  const [acctList, setAcctList] = React.useState(accountCatalog);
  const [addPerson, setAddPerson] = React.useState(false);
  const [addAccount, setAddAccount] = React.useState(false);

  const cats = kind === 'lending' ? expenseCategories : incomeCategories;

  // switching direction clears a category from the other side
  React.useEffect(() => {
    if (category && !cats.some((c) => c.name === category)) setCategory('');
  }, [kind]); // eslint-disable-line react-hooks/exhaustive-deps

  const save = () => {
    const id = existing?.id || `ln-${Date.now().toString(36)}`;
    demoStore.saveLoan({
      id,
      title: title.trim() || 'Untitled Loan',
      kind,
      person,
      amount: Number(amount) || 0,
      account,
      category,
      start,
      end,
      notes,
      color: primary,
      accent,
      status: existing?.status || 'active',
    });
  };

  return (
    <div className="view dark-view loan-editor s4">
      <header className="dark-header">
        <button type="button" className="dark-back" aria-label="Back" onClick={() => demoStore.back()}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <path d="M19 12H5m6-7-7 7 7 7" />
          </svg>
        </button>
        <h1 className="dark-title">Loan</h1>
      </header>

      <SegmentedBar
        className="s4-seg"
        options={[
          { id: 'lending', label: 'Lending' },
          { id: 'borrowing', label: 'Borrowing' },
        ]}
        value={kind}
        onChange={setKind}
      />

      {/* icon + name */}
      <div className="ed-row">
        <button type="button" className="ed-icon" aria-label="Loan icon">
          <UserRound />
        </button>
        <input
          className="ed-input"
          value={title}
          placeholder="Ex: Car Loan"
          aria-label="Loan name"
          onChange={(e) => setTitle(e.target.value)}
        />
      </div>

      <input
        className="ed-input ed-full"
        value={amount}
        inputMode="decimal"
        placeholder="Amount"
        aria-label="Principal amount"
        onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ''))}
      />

      <input
        className="ed-input ed-full"
        value={notes}
        placeholder="Notes"
        aria-label="Notes"
        onChange={(e) => setNotes(e.target.value)}
      />

      <div className="ed-dates">
        <label className="ed-date">
          <span className="ed-date-label">
            <CalendarDays />
            Start date
          </span>
          <span className="ed-date-value">{usDate(start)}</span>
          <input type="date" value={start} onChange={(e) => setStart(e.target.value)} aria-label="Start date" />
        </label>
        <label className="ed-date">
          <span className="ed-date-label">
            <CalendarDays />
            End date
          </span>
          <span className="ed-date-value">{usDate(end)}</span>
          <input type="date" value={end} onChange={(e) => setEnd(e.target.value)} aria-label="End date" />
        </label>
      </div>

      <PersonPicker
        people={people}
        value={person}
        onChange={setPerson}
        onAdd={() => setAddPerson(true)}
      />

      <AccountPicker
        accounts={acctList}
        value={account}
        onChange={setAccount}
        onAdd={() => setAddAccount(true)}
      />

      <CategoryPicker
        categories={cats}
        value={category}
        onChange={setCategory}
        onAdd={() => setCategory(`${kind === 'lending' ? 'Expense' : 'Income'} custom`)}
      />

      <ColorPicker
        primary={primary}
        accent={accent}
        onChange={(which, hex) => (which === 'accent' ? setAccent(hex) : setPrimary(hex))}
      />

      <button type="button" className="ed-submit" onClick={save}>
        <Save />
        {existing ? 'Update Loan' : 'Add Loan'}
      </button>

      {addPerson ? (
        <AddMini
          title="Add person"
          placeholder="Name"
          onSave={(name) => {
            setPeople((p) => (p.includes(name) ? p : [...p, name]));
            setPerson(name);
          }}
          onClose={() => setAddPerson(false)}
        />
      ) : null}
      {addAccount ? (
        <AddMini
          title="Add account"
          placeholder="Account name"
          onSave={(name) => {
            const row = { id: `ac-${Date.now()}`, name, color: '#00897B', icon: 'bank' };
            setAcctList((l) => [...l, row]);
            setAccount(name);
          }}
          onClose={() => setAddAccount(false)}
        />
      ) : null}
    </div>
  );
}
