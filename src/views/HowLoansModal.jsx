import React from 'react';
import {
  ArrowUpDown,
  Wallet,
  CheckCircle2,
  User,
  CalendarClock,
  TrendingUp,
  ListFilter,
  Banknote,
} from 'lucide-react';
import { demoStore } from '../data/demoStore.js';
import { howLoansWork } from '../data/step3Data.js';
import { SheetModal } from '../components/step3/ui3.jsx';

const ICONS = {
  swipe: ArrowUpDown,
  cash: Banknote,
  wallet: Wallet,
  check: CheckCircle2,
  user: User,
  due: CalendarClock,
  trend: TrendingUp,
  sort: ListFilter,
};

export default function HowLoansModal() {
  return (
    <SheetModal
      title="How Loans Work"
      intro="Loans help you track money you've lent to others or borrowed, with payment progress."
      tone="dark"
      onClose={() => demoStore.openLoansHow(false)}
      items={howLoansWork.map((i) => {
        const C = ICONS[i.icon] || Wallet;
        return { title: i.title, lines: i.lines, text: i.text, icon: <C /> };
      })}
    />
  );
}
