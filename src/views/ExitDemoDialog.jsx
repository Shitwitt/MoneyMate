import React from 'react';
import { Sparkles, PencilLine, X } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';

/**
 * Shown by `✕ Exit Demo`. Either wipe the demo records and start with the
 * user's own data, or keep everything and keep editing freely.
 */
export default function ExitDemoDialog() {
  const counts = useStore((s) => s.transactions.length);
  const loans = useStore((s) => s.loans.length);
  const goals = useStore((s) => s.goals.length);
  const assets = useStore((s) => s.assets.length);
  const bills = useStore((s) => s.bills.length);
  const close = () => demoStore.openExitDialog(false);

  return (
    <div className="exit-scrim" role="presentation" onClick={close}>
      <div
        className="exit-dlg"
        role="dialog"
        aria-modal="true"
        aria-labelledby="exit-title"
        onClick={(e) => e.stopPropagation()}
      >
        <button type="button" className="exit-x" aria-label="Close" onClick={close}>
          <X />
        </button>

        <h2 id="exit-title">Leave the demo?</h2>
        <p className="exit-sub">
          You have <b>{counts}</b> transactions, <b>{loans}</b> loans, <b>{goals}</b> goals,{' '}
          <b>{assets}</b> assets and <b>{bills}</b> bills. Everything you changed is saved on this
          device.
        </p>

        <button type="button" className="exit-opt primary" onClick={() => demoStore.startFresh()}>
          <span className="exit-ico">
            <Sparkles />
          </span>
          <span>
            <b>Start Fresh</b>
            <em>My Own Data — clears every demo record</em>
          </span>
        </button>

        <button type="button" className="exit-opt" onClick={() => demoStore.keepDemoData()}>
          <span className="exit-ico">
            <PencilLine />
          </span>
          <span>
            <b>Keep Demo Data &amp; Edit Freely</b>
            <em>Everything stays, fully editable</em>
          </span>
        </button>

        <button type="button" className="exit-cancel" onClick={close}>
          Cancel
        </button>
      </div>
    </div>
  );
}
