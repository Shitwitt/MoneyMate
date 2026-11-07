import React from 'react';
import { Split, Users, Handshake, Wallet, TrendingUp } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { howBillSplitterWorks } from '../data/step3Data.js';
import { billStatus, netBalances, settleUp, fmtMoney } from '../data/engine.js';
import { SheetModal } from '../components/step3/ui3.jsx';

const ICONS = { split: Split, users: Users, handshake: Handshake, wallet: Wallet, trend: TrendingUp };

export function HowBillSplitterModal() {
  return (
    <SheetModal
      title="How Bill Splitter Works"
      intro="Split bills with friends and track who owes what."
      tone="dark"
      onClose={() => demoStore.openBillsHow(false)}
      items={howBillSplitterWorks.map((i) => {
        const C = ICONS[i.icon] || Split;
        return { title: i.title, lines: i.lines, text: i.text, icon: <C /> };
      })}
    />
  );
}

export function NetBalancesModal() {
  const bills = useStore((s) => s.bills);
  const net = netBalances(bills.filter((b) => billStatus(b) === 'Pending'));
  const transfers = settleUp(bills.filter((b) => billStatus(b) === 'Pending'));

  return (
    <SheetModal
      title="Net Balances"
      intro="Net position across every active bill, and the fewest transfers that settle it."
      tone="dark"
      onClose={() => demoStore.openNetBalances(false)}
      footer={null}
    >
      <div className="net-list">
        {net.length === 0 ? <p className="sheet-line">Everyone is settled up. 🎉</p> : null}
        {net.map((n) => (
          <div className="net-row" key={n.name}>
            <span className="net-name">{n.name}</span>
            <span className={`net-amount${n.cents > 0 ? ' pos' : ' neg'}`}>
              {n.cents > 0
                ? `owes you ${fmtMoney(n.cents)}`
                : `you owe ${fmtMoney(-n.cents)}`}
            </span>
          </div>
        ))}
      </div>

      {transfers.length ? (
        <>
          <div className="net-divider" />
          <div className="net-heading">Settle up</div>
          {transfers.map((t) => (
            <div className="net-row transfer" key={`${t.from}-${t.to}`}>
              <span className="net-name">
                {t.from} → {t.to}
              </span>
              <span className="net-amount">{fmtMoney(t.cents)}</span>
            </div>
          ))}
        </>
      ) : null}

      <button type="button" className="sheet-cta" onClick={() => demoStore.openNetBalances(false)}>
        Got it
      </button>
    </SheetModal>
  );
}
