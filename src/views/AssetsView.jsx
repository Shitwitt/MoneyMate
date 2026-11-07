import React from 'react';
import { Landmark, Plus } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { fmtMoney, groupAssets, portfolioTotal, toCents } from '../data/engine.js';
import { DarkHeader, PageBadge, InfoButton } from '../components/step3/ui3.jsx';

export default function AssetsView() {
  const assets = useStore((s) => s.assets);
  const total = portfolioTotal(assets);
  const groups = groupAssets(assets);

  return (
    <div className="view assets-view">
      <DarkHeader
        title="Assets"
        right={
          <>
            <PageBadge>{assets.length}/{assets.length}</PageBadge>
            <InfoButton label="How assets work" onClick={() => demoStore.openAssetsHow(true)} />
          </>
        }
      />

      <div className="assets-total">
        <div className="assets-total-label">Total</div>
        <div className="assets-total-value">{fmtMoney(toCents(total))}</div>
      </div>

      {groups.map((g) => (
        <section className="asset-group" key={g.type}>
          <div className="asset-group-head">
            <span>{g.type === 'Real estate' ? 'Real estate' : g.type.toLowerCase()}</span>
            <span>{g.short}</span>
          </div>

          <div className="asset-group-card">
            {g.items.map((a, i) => (
              <button
                type="button"
                className="asset-row"
                key={a.id}
                onClick={() => demoStore.editAsset(a.id)}
              >
                <span className="asset-tile" style={{ background: a.primary }}>
                  <Landmark />
                </span>
                <span className="asset-mid">
                  <span className="asset-name">{a.name}</span>
                  <span className="asset-note">
                    {a.note}
                    {a.purchase ? ` • ${fmtMoney(toCents(a.purchase))}` : ''}
                  </span>
                </span>
                <span className="asset-value">
                  {fmtMoney(toCents(a.value * (a.units || 1)), { symbol: '' })}
                </span>
              </button>
            ))}
          </div>
        </section>
      ))}

      <button type="button" className="asset-fab" aria-label="Add asset" onClick={() => demoStore.newAsset()}>
        <Plus />
      </button>
    </div>
  );
}
