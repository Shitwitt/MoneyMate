import React, { useEffect } from 'react';
import { Landmark, Save, Trash2 } from 'lucide-react';

import { useStore } from '../hooks/useStore.js';
import { demoStore, CURRENCIES, CURRENCY_SYMBOL } from '../data/demoStore.js';
import { assetTypes, paletteMain } from '../data/step3Data.js';
import { DarkHeader } from '../components/step3/ui3.jsx';

const FALLBACK = {
  id: null,
  name: '',
  type: 'Real estate',
  value: '',
  purchasePrice: '',
  units: 1,
  unitName: '',
  description: '',
  currency: 'USD',
  primary: '#00796B',
  accent: '#009688',
};

export default function AssetEditorView() {
  const params = useStore((s) => s.route.params);
  const assets = useStore((s) => s.assets);
  const existing = assets.find((a) => a.id === params.id);
  const [form, setForm] = React.useState(() => ({ ...FALLBACK, ...(existing || {}) }));

  useEffect(() => {
    setForm({ ...FALLBACK, ...(assets.find((a) => a.id === params.id) || {}) });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params.id]);

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));
  const save = (e) => {
    e.preventDefault();
    demoStore.saveAsset({
      ...form,
      name: form.name.trim() || 'Untitled asset',
      value: Number(form.value) || 0,
      purchasePrice: form.purchasePrice === '' ? null : Number(form.purchasePrice),
      units: Number(form.units) || 1,
    });
  };

  return (
    <div className="view asset-editor">
      <DarkHeader
        title={existing ? 'Edit Asset' : 'New Asset'}
        right={existing ? (
          <button type="button" className="dark-icon-btn danger" aria-label="Delete asset" onClick={() => demoStore.deleteAsset(form.id)}><Trash2 /></button>
        ) : null}
      />
      <form className="modal-form asset-form" onSubmit={save}>
        <div className="ae-row">
          <span className="ae-icon-circle"><Landmark /></span>
          <input className="ae-input ae-name" value={form.name} placeholder="Asset name" aria-label="Asset name" onChange={(e) => set('name', e.target.value)} />
        </div>
        <label className="form-field">Current Value<input className="ae-input ae-input-full" type="number" step="0.01" value={form.value} aria-label="Current value" onChange={(e) => set('value', e.target.value)} /></label>
        <label className="form-field">Purchase Price<input className="ae-input ae-input-full" type="number" step="0.01" value={form.purchasePrice ?? ''} aria-label="Purchase price" onChange={(e) => set('purchasePrice', e.target.value)} /></label>
        <div className="form-grid two">
          <label className="form-field">Units / Quantity<input className="ae-input" type="number" step="0.01" value={form.units} aria-label="Quantity" onChange={(e) => set('units', e.target.value)} /></label>
          <label className="form-field">Unit Name<input className="ae-input" value={form.unitName || ''} placeholder="sq ft, shares…" aria-label="Unit name" onChange={(e) => set('unitName', e.target.value)} /></label>
        </div>
        <label className="form-field">Description<textarea className="ae-input ae-input-full" rows="2" value={form.description || ''} aria-label="Description" onChange={(e) => set('description', e.target.value)} /></label>
        <div className="form-grid two">
          <label className="form-field">Currency
            <select className="ae-input" value={form.currency} onChange={(e) => set('currency', e.target.value)}>
              {CURRENCIES.map((c) => <option key={c} value={c}>{CURRENCY_SYMBOL[c]} {c}</option>)}
            </select>
          </label>
          <label className="form-field">Asset Type
            <select className="ae-input" value={form.type} onChange={(e) => set('type', e.target.value)}>
              {assetTypes.map((t) => <option key={t} value={t}>{t}</option>)}
            </select>
          </label>
        </div>
        <div className="form-grid two">
          <label className="form-field">Primary color<input type="color" value={form.primary} onChange={(e) => set('primary', e.target.value)} aria-label="Primary color" /></label>
          <label className="form-field">Accent color<input type="color" value={form.accent} onChange={(e) => set('accent', e.target.value)} aria-label="Accent color" /></label>
        </div>
        <div className="form-chips">
          {paletteMain.map((c) => (
            <button type="button" key={c} style={{ width: 26, height: 26, borderRadius: '50%', background: c, border: form.primary === c ? '2px solid #fff' : '1px solid #4A372F' }} aria-label={`Use ${c}`} onClick={() => set('primary', c)} />
          ))}
        </div>
        <button type="submit" className="btn primary"><Save /> {existing ? 'Update asset' : 'Add asset'}</button>
      </form>
    </div>
  );
}
