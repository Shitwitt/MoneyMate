const appName = 'Tink';
const appVersion = '1.1.0';
const freeBudgetLimit = 3;
const freeGoalLimit = 3;
const freeEntityLimit = 10;
const freeBillLimit = 3;
const maxReceiptBytes = 2 * 1024 * 1024;
const maxBackupBytes = 50 * 1024 * 1024;
const homeCardNames = <String, String>{
  'balance': 'At a glance',
  'cashflow': 'This month',
  'accounts': 'Your accounts',
  'trend': 'Cash flow',
  'budgets': 'Budgets',
  'goals': 'Dreams in progress',
  'recent': 'Transactions',
  'templates': 'Quick templates',
  'recurring': 'Subscriptions',
  'assets': 'Assets',
  'loans': 'Loans',
  'reports': 'Reports & insights',
  'achievements': 'Little wins',
  'premium': 'PaisaClone Plus',
};
const accountTypes = [
  'cash',
  'bank',
  'credit card',
  'debit card',
  'wallet',
  'savings',
  'investment',
];
const assetTypes = [
  'stocks',
  'mutual funds',
  'real estate',
  'gold',
  'crypto',
  'vehicle',
  'other',
];
const periods = ['weekly', 'monthly', 'yearly', 'custom'];
const frequencies = ['daily', 'weekly', 'monthly', 'yearly', 'custom'];
const palette = [
  0xff916cff, 0xff2E90FA, 0xffF79009, 0xff12B76A, 0xffEE46BC,
  0xff7F56D9, 0xff6172F3, 0xff15B79E, 0xffA78BFF, 0xff8A8A96,
];

const languageNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'pa': 'ਪੰਜਾਬੀ',
  'mr': 'मराठी',
  'gu': 'ગુજરાતી',
  'bn': 'বাংলা',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'ar': 'العربية',
  'pt': 'Português',
};
