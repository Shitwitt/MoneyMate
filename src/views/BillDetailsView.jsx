import React from 'react';
import {
  Trash2,
  Check,
  CheckCircle2,
  Clock,
  Split,
  User,
  Wallet,
  MoreVertical,
  Pencil,
  AlertTriangle,
  PencilLine,
} from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { billStatus, participantBalances, fmtMoney, toCents } from '../data/engine.js';
import { DarkHeader } from '../components/step3/ui3.jsx';

const MODE_LABEL = { equal: 'Equal', custom: 'Custom', percentage: 'Percentage' };

function PaymentDialog({ billId, person, onClose }) {
  const [value, setValue] = React.useState(() => fmtMoney(person.paid, { symbol: '' }));
  const submit = (e) => {
    e.preventDefault();
    const amount = Number(String(value).replace(/[^0-9.]/g, '')) || 0;
    demoStore.setParticipantPaid(billId, person.id, amount);
    onClose();
  };
  return (
    <div className="dlg-scrim" role="presentation" onClick={onClose}>
      <form className="dlg" onSubmit={submit} onClick={(e) => e.stopPropagation()}>
        <h3>Edit payment</h3>
        <p className="dlg-sub">
          {person.name} owes {fmtMoney(person.owes)} of {fmtMoney(person.share)}
        </p>
        <label className="dlg-field">
          Amount paid
          <input
            autoFocus
            value={value}
            inputMode="decimal"
            onChange={(e) => setValue(e.target.value)}
            aria-label="Amount paid"
          />
        </label>
        <div className="dlg-quick">
          <button type="button" onClick={() => setValue(fmtMoney(person.owes, { symbol: '' }))}>
            Full share
          </button>
          <button type="button" onClick={() => setValue('')}>
            Clear
          </button>
        </div>
        <div className="dlg-actions">
          <button type="button" className="dlg-cancel" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="dlg-save">
            Save
          </button>
        </div>
      </form>
    </div>
  );
}

export default function BillDetailsView() {
  const params = useStore((s) => s.route.params);
  const bills = useStore((s) => s.bills);
  const menuFor = useStore((s) => s.billsUi.menuFor);
  const [editing, setEditing] = React.useState(null);

  const bill = bills.find((b) => b.id === params.id) || bills[0];
  if (!bill) return null;

  const rows = participantBalances(bill);
  const payer = rows.find((r) => r.isPayer);
  const status = billStatus(bill);

  return (
    <div className="view dark-view bill-details">
      <DarkHeader
        title="Bill Details"
        right={
          <>
            <button
              type="button"
              className="dark-icon-btn danger"
              aria-label="Delete bill"
              onClick={() => demoStore.deleteBill(bill.id)}
            >
              <Trash2 />
            </button>
            <button
              type="button"
              className="dark-icon-btn"
              aria-label="Settle all participants"
              onClick={() => demoStore.settleBill(bill.id)}
            >
              <CheckCircle2 />
            </button>
          </>
        }
      />

      {/* hero */}
      <section className="bill-hero">
        <div className="bh-top">
          <span className="bh-ico">
            <Wallet />
          </span>
          <h2 className="bh-title">{bill.title}</h2>
          <span className={`bh-status ${status === 'Settled' ? 'settled' : 'pending'}`}>
            {status === 'Settled' ? <Check /> : <Clock />}
            {status}
          </span>
        </div>
        <div className="bh-amount-row">
          <span className="bh-amount-label">Total Amount</span>
          <span className="bh-amount">{fmtMoney(toCents(bill.total))}</span>
        </div>
        <span className="bh-mode">
          <Split />
          {MODE_LABEL[bill.mode]} Split
        </span>
      </section>

      {/* paid by */}
      <h3 className="dark-section-title">Paid By</h3>
      <div className="paid-by-card">
        <span className="person-ico" style={{ background: payer?.color || '#009688' }}>
          <User />
        </span>
        <span className="person-mid">
          <span className="person-name">{payer?.name}</span>
          <span className="person-role">Payer</span>
        </span>
        <span className="paid-by-amount">{fmtMoney(toCents(bill.total))}</span>
      </div>

      {/* participants */}
      <h3 className="dark-section-title">Participants ({rows.length})</h3>
      <div className="participants">
        {rows.map((r) => {
          const open = menuFor === r.id;
          return (
            <div className="participant-card" key={r.id}>
              <div className="pc-top">
                <span className="person-ico" style={{ background: r.color }}>
                  <User />
                </span>
                <span className="person-mid">
                  <span className="person-name">{r.name}</span>
                  {r.isPayer ? <span className="person-role">Payer</span> : null}
                </span>

                {r.isPayer ? (
                  <span className={`pill-settled lg${r.owes === 0 ? '' : ' dim'}`}>
                    <Check />
                    Settled
                  </span>
                ) : (
                  <button
                    type="button"
                    className="dot-menu-btn"
                    aria-label={`Payment actions for ${r.name}`}
                    aria-expanded={open}
                    onClick={() => demoStore.openParticipantMenu(r.id)}
                  >
                    <MoreVertical />
                  </button>
                )}
              </div>

              {!r.isPayer ? (
                <div className="pc-progress" aria-label={`${Math.round(r.progress)}% paid`}>
                  <span style={{ width: `${r.progress}%` }} />
                </div>
              ) : null}

              <div className="pc-chips">
                <span className="pc-chip">
                  <Split />
                  Share {fmtMoney(r.share, { symbol: '' })}
                </span>
                <span className={`pc-chip${r.paid > 0 ? ' paid' : ''}`}>
                  <Wallet />
                  Paid {fmtMoney(r.paid, { symbol: '' })}
                </span>
                {r.owes > 0 ? (
                  <span className="pc-chip owes">
                    <AlertTriangle />
                    Owes {fmtMoney(r.owes, { symbol: '' })}
                  </span>
                ) : (
                  <span className="pc-chip settled">
                    <Check />
                    Settled
                  </span>
                )}
              </div>

              {open ? (
                <>
                  <button
                    type="button"
                    className="menu-scrim dark"
                    aria-label="Close menu"
                    onClick={() => demoStore.closeParticipantMenu()}
                  />
                  <div className="pc-menu" role="menu">
                    <button
                      type="button"
                      role="menuitem"
                      onClick={() => demoStore.markParticipantPaid(bill.id, r.id)}
                    >
                      <Check />
                      Mark as Paid
                    </button>
                    <button
                      type="button"
                      role="menuitem"
                      onClick={() => {
                        demoStore.closeParticipantMenu();
                        setEditing(r);
                      }}
                    >
                      <Pencil />
                      Edit Payment
                    </button>
                  </div>
                </>
              ) : null}
            </div>
          );
        })}
      </div>

      <button
        type="button"
        className="ext-fab"
        onClick={() => demoStore.go('billEditor', { id: bill.id })}
      >
        <PencilLine />
        Edit
      </button>

      {editing ? (
        <PaymentDialog
          billId={bill.id}
          person={editing}
          onClose={() => setEditing(null)}
        />
      ) : null}
    </div>
  );
}
