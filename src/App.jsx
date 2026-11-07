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
};

export default function App() {
  const view = useStore((s) => s.route.view);
  const howOpen = useStore((s) => s.howBudgetsOpen);
  const Current = VIEWS[view] || HomeView;

  // each screen starts at the top (browser / WebView scroll is global)
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'auto' });
    const shell = document.querySelector('.app-shell');
    if (shell) shell.scrollTop = 0;
  }, [view]);

  // android hardware back / browser back leaves the sub-screen first
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
      {howOpen ? <HowBudgetsModal /> : null}
      <Toast />
    </>
  );
}
