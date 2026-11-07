import React, { useEffect } from 'react';

import { useStore } from './hooks/useStore.js';
import { useT } from './hooks/useT.js';
import { demoStore, languageDirection } from './data/demoStore.js';

import TopBar from './components/TopBar.jsx';
import Greeting from './components/Greeting.jsx';
import HeroCard from './components/HeroCard.jsx';
import BentoGrid from './components/BentoGrid.jsx';
import Templates from './components/Templates.jsx';
import CalendarHeatmap from './components/CalendarHeatmap.jsx';
import TrendChart from './components/TrendChart.jsx';
import BudgetCarousel from './components/BudgetCarousel.jsx';
import UpcomingTransactions from './components/UpcomingTransactions.jsx';
import FloatingNav from './components/FloatingNav.jsx';
import LiveModals from './components/LiveModals.jsx';
import OnboardingWizard from './views/OnboardingWizard.jsx';

import AccountsView from './views/AccountsView.jsx';
import ReportsView from './views/ReportsView.jsx';
import BudgetsView from './views/BudgetsView.jsx';
import BudgetDetailView from './views/BudgetDetailView.jsx';
import HowBudgetsModal from './views/HowBudgetsModal.jsx';
import AssetsView from './views/AssetsView.jsx';
import AssetEditorView from './views/AssetEditorView.jsx';
import HowAssetsModal from './views/HowAssetsModal.jsx';
import BillSplitterView from './views/BillSplitterView.jsx';
import BillDetailsView from './views/BillDetailsView.jsx';
import BillEditorView from './views/BillEditorView.jsx';
import { HowBillSplitterModal, NetBalancesModal } from './views/BillModals.jsx';
import LoansView from './views/LoansView.jsx';
import LoanDetailsView from './views/LoanDetailsView.jsx';
import LoanEditorView from './views/LoanEditorView.jsx';
import HowLoansModal from './views/HowLoansModal.jsx';
import GoalsView from './views/GoalsView.jsx';
import GoalDetailsView from './views/GoalDetailsView.jsx';
import GoalEditorView from './views/GoalEditorView.jsx';
import HowGoalsWorkModal from './views/HowGoalsWorkModal.jsx';
import SearchView from './views/SearchView.jsx';

function Toast() {
  const toast = useStore((s) => s.toast);
  if (!toast) return null;
  return <div className="toast" role="status" key={toast.at}>{toast.message}</div>;
}

function HomeView() {
  const sections = useStore((s) => s.homeSections);
  const t = useT();
  return (
    <>
      <TopBar />
      <Greeting />
      <HeroCard />

      {sections.includes('overview') ? (
        <>
          <div className="section-head"><h2>{t('Overview')}</h2></div>
          <BentoGrid />
        </>
      ) : null}
      <div style={{ height: 8 }} />
      {sections.includes('templates') ? <Templates /> : null}
      {sections.includes('calendar') ? <CalendarHeatmap /> : null}
      {sections.includes('trend') ? <TrendChart /> : null}
      {sections.includes('budgets') ? <BudgetCarousel /> : null}
      {sections.includes('upcoming') ? <UpcomingTransactions /> : null}
    </>
  );
}

const VIEWS = {
  home: HomeView,
  accounts: AccountsView,
  reports: ReportsView,
  budgets: BudgetsView,
  budgetDetail: BudgetDetailView,
  assets: AssetsView,
  assetEditor: AssetEditorView,
  billSplitter: BillSplitterView,
  billDetails: BillDetailsView,
  billEditor: BillEditorView,
  loans: LoansView,
  loanDetails: LoanDetailsView,
  loanEditor: LoanEditorView,
  goals: GoalsView,
  goalDetails: GoalDetailsView,
  goalEditor: GoalEditorView,
  search: SearchView,
};

/** screens that always use the expressive dark palette */
const DARK_VIEWS = new Set([
  'billSplitter', 'billDetails', 'billEditor',
  'loans', 'loanDetails', 'loanEditor',
  'goals', 'goalDetails', 'goalEditor',
]);

const LIGHT_NAV_VIEWS = new Set(['home', 'accounts', 'reports', 'search', 'budgetDetail']);

export default function App() {
  const view = useStore((s) => s.route.view);
  const theme = useStore((s) => s.theme);
  const language = useStore((s) => s.language || 'en');
  const onboarding = useStore((s) => s.onboarding);
  const privacy = useStore((s) => s.privacy);
  const howBudgetsOpen = useStore((s) => s.howBudgetsOpen);
  const assetsHow = useStore((s) => s.assetsUi.howOpen);
  const billsHow = useStore((s) => s.billsUi.howOpen);
  const balancesOpen = useStore((s) => s.billsUi.balancesOpen);
  const loansHow = useStore((s) => s.loansUi.howOpen);
  const goalsHow = useStore((s) => s.goalsUi.howOpen);

  const Current = VIEWS[view] || HomeView;
  const effectiveTheme = onboarding?.completed === false ? 'dark' : (DARK_VIEWS.has(view) ? 'dark' : theme);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', effectiveTheme);
    document.documentElement.setAttribute('data-privacy', privacy ? 'on' : 'off');
    document.documentElement.lang = language;
    document.documentElement.dir = languageDirection(language);
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', effectiveTheme === 'dark' ? '#16100E' : '#FDF3EE');
  }, [effectiveTheme, privacy, language]);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'auto' });
    const shell = document.querySelector('.app-shell');
    if (shell) shell.scrollTop = 0;
  }, [view]);

  useEffect(() => {
    const onPop = () => { if (view !== 'home') demoStore.back(); };
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, [view]);

  if (!onboarding?.completed) {
    return (
      <>
        <OnboardingWizard />
        <Toast />
      </>
    );
  }

  return (
    <>
      <main className={`app-shell view-${view}`}>
        <Current />
      </main>

      {LIGHT_NAV_VIEWS.has(view) ? <FloatingNav /> : null}

      {howBudgetsOpen ? <HowBudgetsModal /> : null}
      {assetsHow ? <HowAssetsModal /> : null}
      {billsHow ? <HowBillSplitterModal /> : null}
      {balancesOpen ? <NetBalancesModal /> : null}
      {loansHow ? <HowLoansModal /> : null}
      {goalsHow ? <HowGoalsWorkModal /> : null}

      <LiveModals />
      <Toast />
    </>
  );
}
