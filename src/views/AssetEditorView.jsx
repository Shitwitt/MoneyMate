import React from 'react';
import { Landmark, Trash2, Save, ChevronDown, ArrowLeftRight } from 'lucide-react';
import { useStore } from '../hooks/useStore.js';
import { demoStore } from '../data/demoStore.js';
import { assetTypes, paletteMain } from '../data/step3Data.js';
import { shadeRamp } from '../data/engine.js';
import { DarkHeader } from '../components/step3/ui3.jsx';

/** 361087 -> "361087.0" (the reference shows one decimal for values & units) */
function oneDecimal(v) {
  if (v === '' || v == null) return '';
  const n = Number(v);
  if (Number.isNaN(n)) return String(v);
  return Number.isInteger(n) ? n.toFixed(1) : String(n);
}

const FALLBACK = {
  id: null,
  name: '',
  type: 'Real estate',
  value: 0,
  units: 1,
  unit: '',
  note: '',
  purchase: null,
  currency: 'Default (USD $)',
  primary: '#009688',
  accent: '#009688',
};

export default function AssetEditorView() {
  const params = useStore((s) => s.route.params);
  const assets = useStore((s) => s.assets);
  const existing = assets.find((a) => a.id === params.id);

  const [form, setForm] = React.useState(() => {
    const base = { ...FALLBACK, ...(existing || {}) };
    return { ...base, value: oneDecimal(base.value), units: oneDecimal(base.units) };
  });
  const [colorTab, setColorTab] = React.useState('primary');
  const [typeOpen, setTypeOpen] = React.useState(false);
  const [currencyOpen, setCurrencyOpen] = React.useState(false);

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));
  const activeColor = colorTab === 'primary' ? form.primary : form.accent;
  const ramp = shadeRamp(activeColor, 10);

  const pick = (hex) => {
    if (colorTab === 'primary') set('primary', hex);
    else set('accent', hex);
  };

  const save = () => {
    const payload = {
      ...form,
      id: form.id || `as${Date.now()}`,
      name: form.name.trim() || 'Untitled asset',
      value: Number(form.value) || 0,
      units: form.units === '' ? 1 : Number(form.units) || 0,
    };
    demoStore.saveAsset(payload);
  };

  return (
    <div className="view asset-editor">
      <DarkHeader
        title="Asset"
        right={
          form.id ? (
            <button
              type="button"
              className="icon-btn trash"
              aria-label="Delete asset"
              onClick={() => demoStore.deleteAsset(form.id)}
            >
              <Trash2 />
            </button>
          ) : null
        }
      />

      {/* icon + name */}
      <div className="ae-row">
        <span className="ae-icon-circle">
          <Landmark />
        </span>
        <input
          className="ae-input ae-name"
          value={form.name}
          placeholder="Asset name"
          aria-label="Asset name"
          onChange={(e) => set('name', e.target.value)}
        />
      </div>

      {/* value */}
      <input
        className="ae-input ae-input-full"
        value={form.value}
        inputMode="decimal"
        aria-label="Current value"
        onChange={(e) => set('value', e.target.value.replace(/[^0-9.]/g, ''))}
      />

      {/* units + unit label */}
      <div className="ae-split">
        <input
          className="ae-input"
          value={form.units}
          inputMode="decimal"
          aria-label="Quantity"
          onChange={(e) => set('units', e.target.value.replace(/[^0-9.]/g, ''))}
        />
        <input
          className="ae-input"
          value={form.unit}
          placeholder="Unit"
          aria-label="Unit"
          onChange={(e) => set('unit', e.target.value)}
        />
      </div>

      {/* note */}
      <input
        className="ae-input ae-input-full"
        value={form.note}
        placeholder="Description / notes"
        aria-label="Description"
        onChange={(e) => set('note', e.target.value)}
      />

      {/* currency selector */}
      <button type="button" className="ae-selector" onClick={() => setCurrencyOpen((v) => !v)}>
        <span className="ae-sel-ico">
          <ArrowLeftRight />
        </span>
        <span className="ae-sel-mid">
          <span className="ae-sel-label">Currency</span>
          <span className="ae-sel-value">{form.currency}</span>
        </span>
        <ChevronDown className="ae-caret" />
      </button>
      {currencyOpen ? (
        <div className="ae-options">
          {['Default (USD $)', 'INR (₹)', 'EUR (€)', 'GBP (£)'].map((c) => (
            <button
              key={c}
              type="button"
              className={`ae-option${form.currency === c ? ' on' : ''}`}
              onClick={() => {
                set('currency', c);
                setCurrencyOpen(false);
              }}
            >
              {c}
            </button>
          ))}
        </div>
      ) : null}

      {/* asset type */}
      <button type="button" className="ae-selector" onClick={() => setTypeOpen((v) => !v)}>
        <span className="ae-sel-ico">
          <Landmark />
        </span>
        <span className="ae-sel-mid">
          <span className="ae-sel-label">Asset type</span>
          <span className="ae-sel-value">{form.type.charAt(0).toUpperCase() + form.type.slice(1)}</span>
        </span>
        <ChevronDown className="ae-caret" />
      </button>
      {typeOpen ? (
        <div className="ae-options">
          {assetTypes.map((t) => (
            <button
              key={t}
              type="button"
              className={`ae-option${form.type === t ? ' on' : ''}`}
              onClick={() => {
                set('type', t);
                setTypeOpen(false);
              }}
            >
              {t}
            </button>
          ))}
        </div>
      ) : null}

      {/* colours */}
      <h3 className="ae-colors-title">Colors</h3>
      <div className="ae-tabs" role="tablist">
        <button
          type="button"
          role="tab"
          aria-selected={colorTab === 'primary'}
          className={`ae-tab${colorTab === 'primary' ? ' on' : ''}`}
          onClick={() => setColorTab('primary')}
        >
          Primary
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={colorTab === 'accent'}
          className={`ae-tab${colorTab === 'accent' ? ' on' : ''}`}
          onClick={() => setColorTab('accent')}
        >
          Accent
        </button>
      </div>

      <div className="ae-swatches" role="group" aria-label="Primary palette">
        {paletteMain.map((c) => (
          <button
            key={c}
            type="button"
            className={`swatch-btn${activeColor.toUpperCase() === c ? ' on' : ''}`}
            style={{ background: c }}
            aria-label={c}
            onClick={() => pick(c)}
          >
            {activeColor.toUpperCase() === c ? (
              <svg viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="3" strokeLinecap="round">
                <path d="m5 13 4.5 4.5L19 7" />
              </svg>
            ) : null}
          </button>
        ))}
      </div>

      <div className="ae-swatches tones" role="group" aria-label="Shade tones">
        {ramp.map((c) => (
          <button
            key={c}
            type="button"
            className={`swatch-btn${activeColor.toUpperCase() === c.toUpperCase() ? ' on' : ''}`}
            style={{ background: c }}
            aria-label={`${c} tone`}
            onClick={() => pick(c)}
          >
            {activeColor.toUpperCase() === c.toUpperCase() ? (
              <svg viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="3" strokeLinecap="round">
                <path d="m5 13 4.5 4.5L19 7" />
              </svg>
            ) : null}
          </button>
        ))}
      </div>

      <button type="button" className="ae-submit" onClick={save}>
        <Save />
        {form.id ? 'Update asset' : 'Save asset'}
      </button>
    </div>
  );
}
