import React from 'react';
import { Shapes, TrendingUp, Wallet, Landmark } from 'lucide-react';
import { demoStore } from '../data/demoStore.js';
import { howAssetsWork } from '../data/step3Data.js';
import { SheetModal } from '../components/step3/ui3.jsx';

const ICONS = { shapes: Shapes, trend: TrendingUp, wallet: Wallet, bank: Landmark };

export default function HowAssetsModal() {
  return (
    <SheetModal
      title="How Assets Work"
      intro="Assets help you track the value of things you own, like investments, property, or vehicles."
      tone="light"
      onClose={() => demoStore.openAssetsHow(false)}
      items={howAssetsWork.map((i) => ({
        title: i.title,
        text: i.text,
        icon: (() => {
          const C = ICONS[i.icon] || Shapes;
          return <C />;
        })(),
      }))}
    />
  );
}
