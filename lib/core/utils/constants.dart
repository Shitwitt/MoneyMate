const appName = 'PaisaClone';
const appVersion = '1.0.0';
const freeBudgetLimit = 3;
const freeGoalLimit = 3;
const freeEntityLimit = 10;
const freeBillLimit = 3;
const maxReceiptBytes = 2 * 1024 * 1024;
const maxBackupBytes = 50 * 1024 * 1024;
const homeCardNames = <String, String>{
  'balance': 'Net worth', 'cashflow': 'Income & spending',
  'accounts': 'Your accounts', 'trend': 'The bigger picture',
  'budgets': 'Budgets', 'goals': 'Dreams in progress',
  'recent': 'Recent activity', 'templates': 'Quick templates',
  'recurring': 'Subscriptions', 'assets': 'Assets', 'loans': 'Loans',
  'reports': 'Reports & insights', 'achievements': 'Little wins',
  'premium': 'PaisaClone Plus',
};
const accountTypes = ['cash', 'bank', 'credit card', 'debit card', 'wallet', 'savings', 'investment'];
const assetTypes = ['stocks', 'mutual funds', 'real estate', 'gold', 'crypto', 'vehicle', 'other'];
const periods = ['weekly', 'monthly', 'yearly', 'custom'];
const frequencies = ['daily', 'weekly', 'monthly', 'yearly', 'custom'];
const palette = [0xffa4ca6a, 0xffb6a5e8, 0xfff2b88f, 0xff88bacc, 0xffed9c9b, 0xffe4c569, 0xff88c7b5, 0xffa5addd, 0xffdbadd1, 0xffb9b7aa];
