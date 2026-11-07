import React, { useEffect, useRef, useState } from 'react';
import {
  ArrowLeft,
  Check,
  ChevronRight,
  CloudUpload,
  Download,
  FileJson,
  FlaskConical,
  Globe2,
  History,
  IdCard,
  LockKeyhole,
  Moon,
  Search,
  ShieldCheck,
  Sun,
  Triangle,
  Upload,
  UserRound,
  X,
} from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { useStore } from '../hooks/useStore.js';
import {
  CURRENCY_CATALOG,
  FEATURED_LANGUAGES,
  LANGUAGES,
  MORE_LANGUAGES,
  PRESET_AVATARS,
  currencyMeta,
  languageBadge,
  languageById,
  readImageFile,
  searchLanguages,
  t,
} from '../data/demoStore.js';

const TOTAL_STEPS = 14;

const FOOTERS = {
  2: ['Welcome to Paisa', 'Effortlessly track your expenses, simply and securely.', 'Get started'],
  3: ['Manage Your Budgets', 'Set and track budgets to stay on top of your finances', 'Next'],
  4: ['Track Your Loans', 'Keep track of your loans and repayments', 'Next'],
  5: ['Set Financial Goals', 'Achieve your financial goals with personalized plans', 'Next'],
  6: ['Subscriptions & Recurring', 'Manage and track your subscriptions easily', 'Next'],
  7: ['Categories', 'Organize your expenses with unlimited custom categories', 'Next'],
  8: ['Support for 35+ Languages', 'Paisa is available in over 35 languages, making it accessible to users worldwide. Switch between languages anytime in settings.', 'Next'],
  9: ['Financial Reports', 'Financial reports to help you understand your spending habits', 'Next'],
  10: ['Split Bills Effortlessly', 'Create shared bills, track every participant and settle balances in one tap.', 'Next'],
  11: ['Track Every Asset', 'Property, vehicles, investments and valuables stay organised with live totals.', 'Next'],
  12: ['Privacy Comes First', 'Hide balances instantly, keep data on your device and export a backup whenever you want.', 'Next'],
};

const PHONE_SHOTS = new Set([2, 3, 4, 5, 6, 7, 9]);

const TOUR_SLIDES = {
  10: {
    icon: <Triangle />, title: 'Bill Splitter', subtitle: 'Shared expenses, perfectly balanced',
    rows: [
      ['Road Trip Expenses', '$330.00', 'Pending'],
      ['Dinner at Restaurant', '$94.00', 'Settled'],
      ['Net balance', 'Alice +$165.00', 'Bob -$165.00'],
    ],
    accent: '#FBB69D',
  },
  11: {
    icon: <ShieldCheck />, title: 'Assets', subtitle: 'A live portfolio of everything you own',
    rows: [
      ['Total portfolio', '$736,114.85', '2 assets'],
      ['Primary Residence', '$361,087.00', 'Real estate'],
      ['Rental Property', '$375,027.85', 'Real estate'],
    ],
    accent: '#B3DFDB',
  },
  12: {
    icon: <LockKeyhole />, title: 'Privacy & backups', subtitle: 'Your data stays under your control',
    rows: [
      ['Hide balances', 'One tap', 'Privacy mode'],
      ['Local backup', 'JSON export', 'Offline'],
      ['Theme', 'Light / Dark', 'Expressive'],
    ],
    accent: '#D8C1F5',
  },
};

function WalletLogo() {
  return (
    <svg className="ob-wallet-logo" viewBox="0 0 120 120" aria-label="Paisa wallet" role="img">
      <defs>
        <linearGradient id="obGold" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#E1BE80" />
          <stop offset="1" stopColor="#B98B4C" />
        </linearGradient>
      </defs>
      <circle cx="72" cy="51" r="34" fill="#8D5334" />
      <path d="M28 31h51a9 9 0 0 1 9 9v51a9 9 0 0 1-9 9H28z" fill="#8D5334" opacity=".96" />
      <path d="M28 27h54a8 8 0 0 1 8 8v54a8 8 0 0 1-8 8H28z" fill="url(#obGold)" />
      <path d="M28 27h54a8 8 0 0 1 8 8v10H28z" fill="#C8A26A" opacity=".72" />
      <path d="M31 69h57v8H31z" fill="#F3E2A9" />
      <rect x="60" y="41" width="12" height="9" rx="1.5" fill="#F3E2A9" />
      <path d="M28 89v8a8 8 0 0 0 8 8" fill="none" stroke="#8D5334" strokeWidth="3" strokeLinecap="round" />
    </svg>
  );
}

function OnboardModal({ title, subtitle, onClose, children, wide = false }) {
  return (
    <div className="ob-modal-scrim" role="presentation" onMouseDown={onClose}>
      <section
        className={`ob-modal${wide ? ' wide' : ''}`}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <header className="ob-modal-head">
          <div><h2>{title}</h2>{subtitle ? <p>{subtitle}</p> : null}</div>
          <button type="button" className="ob-icon-btn" onClick={onClose} aria-label="Close"><X /></button>
        </header>
        <div className="ob-modal-body">{children}</div>
      </section>
    </div>
  );
}

function LanguageModal({ language, onClose }) {
  const [query, setQuery] = useState('');
  const matches = searchLanguages(query);
  return (
    <OnboardModal title="Choose your language" subtitle={`${LANGUAGES.length} languages available`} onClose={onClose} wide>
      <label className="ob-search-field">
        <Search />
        <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search language or code" aria-label="Search language" autoFocus />
      </label>
      <div className="ob-language-list">
        {matches.map((l) => (
          <button
            type="button"
            key={l.code}
            className={`ob-language-row${l.code === language ? ' selected' : ''}`}
            onClick={() => { demoStore.setLanguage(l.code); onClose(); }}
          >
            <span className="ob-language-flag">{l.flag}</span>
            <span className="ob-language-names"><b>{l.native}</b><small>{l.name}</small></span>
            <span className="ob-language-code">{l.short}</span>
            {l.code === language ? <Check /> : null}
          </button>
        ))}
      </div>
    </OnboardModal>
  );
}

function CloudBackupDialog({ onClose, restoreInputRef, onRestoreFile }) {
  const cloudBackup = useStore((s) => s.status.cloudBackup);
  return (
    <OnboardModal title="Google Drive Backup" subtitle="Import or export a portable JSON backup of your live data." onClose={onClose}>
      <div className="ob-cloud-hero"><CloudUpload /></div>
      <button type="button" className={`ob-toggle-row${cloudBackup ? ' on' : ''}`} onClick={() => demoStore.setCloudBackup(!cloudBackup)}>
        <span><b>Cloud backup ready</b><small>{cloudBackup ? 'Connected on this device' : 'Enable local cloud-backup badge'}</small></span>
        <span className="ob-switch"><i /></span>
      </button>
      <div className="ob-backup-actions">
        <button type="button" className="ob-outline-btn" onClick={demoStore.downloadBackup}><Download /> Export local backup</button>
        <button type="button" className="ob-outline-btn" onClick={() => restoreInputRef.current?.click()}><Upload /> Import backup JSON</button>
      </div>
      <p className="ob-note"><FileJson /> Backups include accounts, transactions, budgets, assets, bills, loans, goals, profile, language and onboarding state.</p>
      <input
        ref={restoreInputRef}
        type="file"
        accept=".json,application/json"
        hidden
        onChange={(e) => { const file = e.target.files?.[0]; if (file) onRestoreFile(file); e.target.value = ''; }}
      />
    </OnboardModal>
  );
}

function PhoneFrame({ step }) {
  if (PHONE_SHOTS.has(step)) {
    return (
      <div className="ob-phone" aria-label={`Feature preview ${step}`}>
        <img src={`/onboarding/step${step}.jpg`} alt={`Paisa feature preview ${step}`} draggable="false" />
        <div className="ob-phone-fade" />
      </div>
    );
  }
  const slide = TOUR_SLIDES[step] || TOUR_SLIDES[10];
  return (
    <div className="ob-phone ob-tour-phone" aria-label={`Feature preview ${step}`}>
      <div className="ob-tour-island" />
      <div className="ob-tour-status"><b>1:34</b><span>••••</span><span>▰</span></div>
      <div className="ob-tour-header"><ArrowLeft /><b>{slide.title}</b><span>ⓘ</span></div>
      <div className="ob-tour-tile" style={{ background: slide.accent }}>
        <span className="ob-tour-icon">{slide.icon}</span>
        <div><strong>{slide.subtitle}</strong><small>Live, persisted data</small></div>
      </div>
      <div className="ob-tour-list">
        {slide.rows.map((row) => (
          <div className="ob-tour-row" key={row[0]}>
            <b>{row[0]}</b><span>{row[1]}</span><small>{row[2]}</small>
          </div>
        ))}
      </div>
      <div className="ob-tour-fab">+</div>
      <div className="ob-phone-fade" />
    </div>
  );
}

function StepFooter({ step, language, onNext, children }) {
  const tr = (key, fallback) => t(key, language, fallback);
  const data = FOOTERS[step];
  if (!data) return null;
  const [title, subtitle, button] = data;
  return (
    <footer className="ob-footer">
      {children}
      <h1>{step === 2 ? tr('Welcome to Paisa', title) : title}</h1>
      <p>{subtitle}</p>
      <button type="button" className="ob-primary" onClick={onNext} data-testid="onboarding-next">
        {button === 'Next' ? tr('Next', button) : button}
      </button>
    </footer>
  );
}

function EntryStep({ onStartFresh, onRestore, restoreInputRef, onDemo, onCloud, language }) {
  const tr = (key, fallback) => t(key, language, fallback);
  return (
    <>
      <div className="ob-entry-main">
        <WalletLogo />
        <div className="ob-entry-actions">
          <button type="button" className="ob-action-card" onClick={onCloud} data-testid="google-drive-backup">
            <span className="ob-action-icon"><Triangle /></span>
            <b>Google Drive Backup</b>
            <span className="ob-action-end"><LockKeyhole /></span>
          </button>
          <button type="button" className="ob-action-card" onClick={() => restoreInputRef.current?.click()} data-testid="restore-local-backup">
            <span className="ob-action-icon"><History /></span>
            <b>Restore Local Backup</b>
            <span className="ob-action-end"><ChevronRight /></span>
          </button>
          <button type="button" className="ob-action-card" onClick={onDemo} data-testid="try-demo-mode">
            <span className="ob-action-icon"><FlaskConical /></span>
            <b>Try Demo Mode</b>
            <span className="ob-action-end"><ChevronRight /></span>
          </button>
        </div>
        <input
          ref={restoreInputRef}
          type="file"
          accept=".json,application/json"
          hidden
          onChange={(e) => { const file = e.target.files?.[0]; if (file) onRestore(file); e.target.value = ''; }}
        />
      </div>
      <footer className="ob-footer ob-entry-footer">
        <h1>Set up Paisa</h1>
        <p>Start fresh, bring back an existing backup, or explore Paisa with sample data.</p>
        <button type="button" className="ob-primary" onClick={onStartFresh} data-testid="start-fresh">{tr('Start fresh', 'Start fresh')}</button>
      </footer>
    </>
  );
}

function LanguageStep({ language, onSelect, onMore }) {
  return (
    <div className="ob-language-step">
      <div className="ob-globe-circle"><Globe2 /></div>
      <div className="ob-language-cloud" role="group" aria-label="Featured languages">
        {FEATURED_LANGUAGES.map((l) => (
          <button
            type="button"
            key={l.code}
            className={`ob-language-pill${language === l.code ? ' selected' : ''}`}
            onClick={() => onSelect(l.code)}
            aria-pressed={language === l.code}
          >
            {l.native}
          </button>
        ))}
        <button type="button" className="ob-language-pill more" onClick={onMore}>+24 more</button>
      </div>
    </div>
  );
}

function ProfileStep({ draftName, setDraftName, draftPhoto, setDraftPhoto, onNext, language }) {
  const [pickerOpen, setPickerOpen] = useState(false);
  const photoInputRef = useRef(null);
  const tr = (key, fallback) => t(key, language, fallback);
  const chooseFile = async (file) => {
    try {
      const src = await readImageFile(file);
      setDraftPhoto(src);
      demoStore.setProfilePhoto(src);
      setPickerOpen(false);
      demoStore.toast('Profile photo updated');
    } catch (err) {
      demoStore.toast('Could not read that image');
    }
  };
  return (
    <div className="ob-profile-step">
      <div className="ob-avatar-wrap">
        <button
          type="button"
          className="ob-avatar-circle"
          onClick={() => setPickerOpen((v) => !v)}
          aria-label="Upload profile photo"
          data-testid="avatar-uploader"
        >
          {draftPhoto ? <img src={draftPhoto} alt="Selected profile" /> : <UserRound />}
        </button>
        {pickerOpen ? (
          <div className="ob-avatar-popover" role="dialog" aria-label="Choose an avatar">
            <button type="button" className="ob-avatar-option" onClick={() => photoInputRef.current?.click()}>
              <Upload /> <b>Upload photo</b><small>From your device</small>
            </button>
            <div className="ob-preset-grid">
              {PRESET_AVATARS.map((a) => (
                <button
                  type="button"
                  key={a.id}
                  aria-label={a.label}
                  onClick={() => { setDraftPhoto(a.src); demoStore.setProfilePhoto(a.src); setPickerOpen(false); }}
                >
                  <img src={a.src} alt="" />
                </button>
              ))}
            </div>
            {draftPhoto ? (
              <button type="button" className="ob-text-btn" onClick={() => { setDraftPhoto(''); demoStore.setProfilePhoto(''); setPickerOpen(false); }}>Remove photo</button>
            ) : null}
          </div>
        ) : null}
        <input
          ref={photoInputRef}
          type="file"
          accept="image/*"
          hidden
          onChange={(e) => { const file = e.target.files?.[0]; if (file) chooseFile(file); e.target.value = ''; }}
        />
      </div>
      <label className="ob-name-field">
        <IdCard />
        <input
          value={draftName}
          onChange={(e) => setDraftName(e.target.value)}
          placeholder="Enter user name"
          aria-label="User name"
          data-testid="user-name"
          autoComplete="name"
        />
      </label>
      <footer className="ob-footer ob-profile-footer">
        <h1>{tr('What should we call you?', 'What should we call you?')}</h1>
        <p>This helps us personalize your experience</p>
        <button
          type="button"
          className={`ob-primary${draftName.trim() ? '' : ' disabled'}`}
          disabled={!draftName.trim()}
          onClick={onNext}
          data-testid="profile-next"
        >
          {tr('Next', 'Next')}
        </button>
      </footer>
    </div>
  );
}

function CurrencyStep({ draftCurrency, setDraftCurrency, onFinish, language }) {
  const [query, setQuery] = useState('');
  const tr = (key, fallback) => t(key, language, fallback);
  const q = query.trim().toLowerCase();
  const matches = CURRENCY_CATALOG.filter((c) => [c.name, c.id, c.symbol, c.locale].some((v) => String(v).toLowerCase().includes(q)));
  const selected = draftCurrency ? currencyMeta(draftCurrency) : null;
  const select = (id) => { setDraftCurrency(id); demoStore.setBaseCurrency(id); };
  return (
    <div className="ob-currency-step">
      <div className="ob-dollar-circle">$</div>
      <button type="button" className="ob-currency-summary" onClick={() => document.querySelector('.ob-currency-search input')?.focus()}>
        <span className="ob-currency-badge">{selected ? selected.symbol : '$'}</span>
        <span><b>{selected ? selected.name : 'Select currency'}</b><small>{selected ? selected.id : '$'}</small></span>
        <ChevronRight />
      </button>
      <label className="ob-search-field ob-currency-search">
        <Search />
        <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search currency (e.g., INR, USD, EUR)..." aria-label="Search currency" />
      </label>
      <div className="ob-currency-list" role="listbox" aria-label="Base currency">
        {matches.map((c) => (
          <button
            type="button"
            key={c.id}
            role="option"
            aria-selected={draftCurrency === c.id}
            className={`ob-currency-row${draftCurrency === c.id ? ' selected' : ''}`}
            onClick={() => select(c.id)}
            data-testid={`currency-${c.id}`}
          >
            <span className="ob-currency-badge">{c.symbol}</span>
            <span className="ob-currency-names"><b>{c.name}</b><small>{c.id} · {c.locale} · {c.decimals} decimals</small></span>
            <span className="ob-currency-rule">{c.compact === 'indian' ? 'K / L / Cr' : 'K / M / B'}</span>
            {draftCurrency === c.id ? <Check /> : null}
          </button>
        ))}
      </div>
      <footer className="ob-footer ob-currency-footer">
        <h1>{tr('Select your currency', 'Select your currency')}</h1>
        <p>Choose the main currency for your accounts and reports.</p>
        <button
          type="button"
          className={`ob-primary${draftCurrency ? '' : ' disabled'}`}
          disabled={!draftCurrency}
          onClick={onFinish}
          data-testid="finish-setup"
        >
          {tr('Finish setup', 'Finish setup')}
        </button>
      </footer>
    </div>
  );
}

export default function OnboardingWizard() {
  const onboarding = useStore((s) => s.onboarding);
  const language = useStore((s) => s.language || 'en');
  const profile = useStore((s) => s.profile);
  const theme = useStore((s) => s.theme);
  const step = Math.max(1, Math.min(TOTAL_STEPS, Number(onboarding.step) || 1));

  const [languageModalOpen, setLanguageModalOpen] = useState(false);
  const [cloudDialogOpen, setCloudDialogOpen] = useState(false);
  const [draftName, setDraftName] = useState(profile.name && profile.name !== 'Raj' ? profile.name : '');
  const [draftPhoto, setDraftPhoto] = useState(profile.photo || '');
  const [draftCurrency, setDraftCurrency] = useState('');
  const restoreInputRef = useRef(null);
  const cloudRestoreRef = useRef(null);
  const touchStart = useRef({ x: 0, y: 0 });

  useEffect(() => {
    if (typeof document === 'undefined') return undefined;
    document.body.classList.add('onboarding-active');
    return () => document.body.classList.remove('onboarding-active');
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return undefined;
    window.history.replaceState({ onboardingStep: step }, '', `#setup-${step}`);
    const onPop = () => demoStore.previousOnboardingStep();
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, [step]);

  const next = () => {
    if (step >= TOTAL_STEPS) return;
    if (step === 13) {
      const name = draftName.trim();
      if (!name) return;
      demoStore.setProfile({ name, photo: draftPhoto });
    }
    demoStore.nextOnboardingStep();
  };

  const finish = () => {
    if (!draftCurrency) return;
    demoStore.completeOnboarding({
      name: draftName.trim() || 'Raj',
      photo: draftPhoto,
      language,
      baseCurrency: draftCurrency,
      theme,
    });
  };

  const restoreFile = async (file) => {
    try {
      const text = await file.text();
      const ok = demoStore.restoreBackup(text);
      if (!ok) demoStore.toast('That file is not a valid Paisa backup');
    } catch (err) {
      demoStore.toast('Could not read backup file');
    }
  };

  const onTouchStart = (e) => {
    const p = e.touches?.[0];
    if (p) touchStart.current = { x: p.clientX, y: p.clientY };
  };
  const onTouchEnd = (e) => {
    const p = e.changedTouches?.[0];
    if (!p) return;
    const dx = p.clientX - touchStart.current.x;
    const dy = p.clientY - touchStart.current.y;
    if (dx > 70 && Math.abs(dx) > Math.abs(dy) * 1.4) demoStore.previousOnboardingStep();
  };

  let content;
  if (step === 1) {
    content = (
      <EntryStep
        language={language}
        onStartFresh={demoStore.startOnboardingFresh}
        onRestore={restoreFile}
        restoreInputRef={restoreInputRef}
        onDemo={demoStore.tryDemoMode}
        onCloud={() => setCloudDialogOpen(true)}
      />
    );
  } else if (PHONE_SHOTS.has(step) || TOUR_SLIDES[step]) {
    content = (
      <>
        <div className="ob-phone-stage"><PhoneFrame step={step} /></div>
        <StepFooter step={step} language={language} onNext={next} />
      </>
    );
  } else if (step === 8) {
    content = (
      <>
        <LanguageStep language={language} onSelect={demoStore.setLanguage} onMore={() => setLanguageModalOpen(true)} />
        <StepFooter step={step} language={language} onNext={next} />
      </>
    );
  } else if (step === 13) {
    content = (
      <ProfileStep
        draftName={draftName}
        setDraftName={setDraftName}
        draftPhoto={draftPhoto}
        setDraftPhoto={setDraftPhoto}
        onNext={next}
        language={language}
      />
    );
  } else if (step === 14) {
    content = (
      <CurrencyStep
        draftCurrency={draftCurrency}
        setDraftCurrency={setDraftCurrency}
        onFinish={finish}
        language={language}
      />
    );
  }

  const showSkip = step >= 10 && step <= 12;
  const activeLang = languageById(language);

  return (
    <div className="ob-root" onTouchStart={onTouchStart} onTouchEnd={onTouchEnd} data-testid="onboarding-wizard">
      <div className="ob-osbar" aria-hidden="true">
        <span>1:55</span>
        <span className="ob-os-icons">⌁ 5G ▰ 84</span>
      </div>
      <header className="ob-topbar">
        <button
          type="button"
          className="ob-language-badge"
          onClick={() => setLanguageModalOpen(true)}
          aria-label={`Change language, currently ${activeLang.name}`}
          data-testid="language-pill"
        >
          {languageBadge(language)}
        </button>
        <span className="ob-step-count" data-testid="step-count">{`${step}/${TOTAL_STEPS}`}</span>
        {showSkip ? (
          <button type="button" className="ob-skip" onClick={() => demoStore.setOnboardingStep(13)}>Skip to Setup</button>
        ) : <span className="ob-top-spacer" />}
      </header>

      <main className="ob-main" key={step}>{content}</main>

      {step > 1 ? (
        <button type="button" className="ob-back-hit" onClick={demoStore.previousOnboardingStep} aria-label="Previous step" data-testid="onboarding-back">
          <ArrowLeft />
        </button>
      ) : null}

      {languageModalOpen ? <LanguageModal language={language} onClose={() => setLanguageModalOpen(false)} /> : null}
      {cloudDialogOpen ? (
        <CloudBackupDialog onClose={() => setCloudDialogOpen(false)} restoreInputRef={cloudRestoreRef} onRestoreFile={restoreFile} />
      ) : null}
    </div>
  );
}
