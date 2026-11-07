import React, { useEffect } from 'react';

import { useStore } from './hooks/useStore.js';
import { demoStore } from './data/demoStore.js';

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
import ExitDemoDialog from './views/ExitDemoDialog.jsx';

function Toast() {
  const toast = useStore((s) => s.toast);
  if (!toast) return null;
  return (
    <div className="toast" role="status" key={toast.at}>
      {toast.message}
    </div>
  );
}

function HomeView() {
  return (
    <>
      <TopBar />
      <Greeting />
      <HeroCard />

      <div className="section-head">
        <h2>Overview</h2>
      </div>
      <BentoGrid />

      <div style={{ height: 8 }} />
      <Templates />
      <CalendarHeatmap />
      <TrendChart />
      <BudgetCarousel />
      <UpcomingTransactions />
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
};

/** screens that always use the expressive dark palette */
const DARK_VIEWS = new Set([
  'billSplitter',
  'billDetails',
  'billEditor',
  'loans',
  'loanDetails',
  'loanEditor',
  'goals',
  'goalDetails',
  'goalEditor',
]);

export default function App() {
  const view = useStore((s) => s.route.view);
  const theme = useStore((s) => s.theme);
  const howBudgetsOpen = useStore((s) => s.howBudgetsOpen);
  const assetsHow = useStore((s) => s.assetsUi.howOpen);
  const billsHow = useStore((s) => s.billsUi.howOpen);
  const balancesOpen = useStore((s) => s.billsUi.balancesOpen);
  const loansHow = useStore((s) => s.loansUi.howOpen);
  const goalsHow = useStore((s) => s.goalsUi.howOpen);
  const exitOpen = useStore((s) => s.ui.exitDialog);

  const Current = VIEWS[view] || HomeView;
  const effectiveTheme = DARK_VIEWS.has(view) ? 'dark' : theme;

  // the theme lives on <html> so the shell backdrop switches too
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', effectiveTheme);
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', effectiveTheme === 'dark' ? '#1A110E' : '#FDF3EE');
  }, [effectiveTheme]);

  // each screen starts at the top
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'auto' });
    const shell = document.querySelector('.app-shell');
    if (shell) shell.scrollTop = 0;
  }, [view]);

  // browser / hardware back leaves the sub-screen first
  useEffect(() => {
    const onPop = () => {
      if (view !== 'home') demoStore.back();
    };
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, [view]);

  return (
    <>
      <main className={`app-shell view-${view}`}>
        <Current />
      </main>

      {view === 'home' ? <FloatingNav /> : null}

      {howBudgetsOpen ? <HowBudgetsModal /> : null}
      {assetsHow ? <HowAssetsModal /> : null}
      {billsHow ? <HowBillSplitterModal /> : null}
      {balancesOpen ? <NetBalancesModal /> : null}
      {loansHow ? <HowLoansModal /> : null}
      {goalsHow ? <HowGoalsWorkModal /> : null}
      {exitOpen ? <ExitDemoDialog /> : null}

      <Toast />
    </>
  );
}
