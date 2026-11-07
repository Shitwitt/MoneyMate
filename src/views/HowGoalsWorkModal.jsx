import React from 'react';
import { TrendingUp, Building2, ChartPie, CheckCircle2 } from 'lucide-react';

import { demoStore } from '../data/demoStore.js';
import { howGoalsWork } from '../data/step4Data.js';
import { SheetModal } from '../components/step3/ui3.jsx';
import { Glyph } from '../components/step4/ui4.jsx';

const ICONS = {
  flag: TrendingUp,
  bank: Building2,
  pie: ChartPie,
  check: CheckCircle2,
  trend: TrendingUp,
};

export default function HowGoalsWorkModal() {
  return (
    <SheetModal
      title="How Goals Work"
      intro="Goals help you save toward specific targets by tracking your progress."
      tone="dark"
      onClose={() => demoStore.openGoalsHow(false)}
      items={howGoalsWork.map((i) => {
        const C = ICONS[i.icon] || Glyph;
        return { title: i.title, text: i.text, icon: <C /> };
      })}
    />
  );
}
