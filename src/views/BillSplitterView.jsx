import React from 'react';
import { Plus, Wallet, Split, Check, HandCoins } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { billStatus, fmtMoney, toCents } from '../data/engine.js';
import { DarkHeader, PageBadge, InfoButton, SegmentedBar, AvatarStack } from '../components/step3/ui3.jsx';

const MODE_LABEL = { equal: 'Equal', percentage: 'Percentage', custom: 'Custom' };

export default function BillSplitterView() {
  const bills = useStore((s) => s.bills);
  const tab = useStore((s) => s.billsUi.tab);

  const active = bills.filter((b) => billStatus(b) === 'Pending');
  const settled = bills.filter((b) => billStatus(b) === 'Settled');
  const list = tab === 'active' ? active : settled;

  return (
    <div className="view dark-view bill-splitter">
      <DarkHeader title="Bill Splitter" right={<PageBadge>{bills.length}/{bills.length}</PageBadge>} />

      <div className="dark-subhead">
        <span className="dark-count">
          {list.length} bill splitter{list.length === 1 ? '' : 's'}
        </span>
        <div className="dark-actions">
          <button
            type="button"
            className="dark-icon-btn"
            aria-label="Net balances"
            onClick={() => demoStore.openNetBalances(true)}
          >
            <HandCoins />
          </button>
          <InfoButton label="How bill splitter works" onClick={() => demoStore.openBillsHow(true)} />
        </div>
      </div>

      {list.length === 0 ? (
        <p className="dark-empty">
          No {tab} bills yet. Tap <b>+</b> to split a bill with friends.
        </p>
      ) : null}

      <div className="bill-list">
        {list.map((b) => {
          const status = billStatus(b);
          return (
            <button
              type="button"
              className="bill-row"
              key={b.id}
              onClick={() => demoStore.go('billDetails', { id: b.id })}
            >
              <span className="bill-ico" style={{ background: b.iconBg }}>
                <Wallet />
              </span>
              <span className="bill-mid">
                <span className="bill-title">{b.title}</span>
                <span className="bill-meta">
                  <AvatarStack people={b.participants} />
                  <span className="pill-split">
                    <Split />
                    {MODE_LABEL[b.mode]}
                  </span>
                  {status === 'Settled' ? (
                    <span className="pill-settled">
                      <Check />
                      Settled
                    </span>
                  ) : null}
                </span>
              </span>
              <span className="bill-amount">{fmtMoney(toCents(b.total), { symbol: '' })}</span>
            </button>
          );
        })}
      </div>

      <button
        type="button"
        className="dark-fab"
        aria-label="Add bill splitter"
        onClick={() => demoStore.go('billEditor', {})}
      >
        <Plus />
      </button>

      <div className="dark-bottom-bar">
        <SegmentedBar
          options={[
            { id: 'active', label: 'Active' },
            { id: 'settled', label: 'Settled' },
          ]}
          value={tab}
          onChange={demoStore.setBillsTab}
        />
      </div>
    </div>
  );
}
