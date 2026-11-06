import React from 'react';

import { useStore } from './hooks/useStore.js';
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

function Toast() {
  const toast = useStore((s) => s.toast);
  if (!toast) return null;
  return (
    <div className="toast" role="status" key={toast.at}>
      {toast.message}
    </div>
  );
}

export default function App() {
  return (
    <>
      <main className="app-shell">
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
      </main>

      <FloatingNav />
      <Toast />
    </>
  );
}
