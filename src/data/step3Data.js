/* ============================================================
   Step 3 seed data — assets, bill splitters, loans.
   Amounts are plain numbers (dollars); the engine converts to cents.
   ============================================================ */

export const assetTypes = ['Real estate', 'Vehicle', 'Investment', 'Gold', 'Crypto', 'Other'];

export const paletteMain = [
  '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4',
  '#009688', '#4CAF50', '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800', '#FF5722',
  '#795548', '#607D8B', '#9E9E9E',
];

export const assets = [
  {
    id: 'as1',
    name: 'Primary Residence',
    type: 'Real estate',
    typeLabel: 'Real estate',
    value: 361087.0,
    units: 1.0,
    unit: '',
    note: 'Main home property',
    purchase: null,
    currency: 'Default (USD $)',
    primary: '#00796B',
    accent: '#009688',
  },
  {
    id: 'as2',
    name: 'Rental Property',
    type: 'Real estate',
    typeLabel: 'Real estate',
    value: 375027.85,
    units: 1.0,
    unit: '',
    note: 'Investment rental property',
    purchase: 296072.0,
    currency: 'Default (USD $)',
    primary: '#6A1B9A',
    accent: '#009688',
  },
];

export const howAssetsWork = [
  {
    icon: 'shapes',
    title: 'Asset Types',
    text: 'Organize by type: Real Estate, Vehicle, Investment, Gold, and more.',
  },
  {
    icon: 'trend',
    title: 'Valuation',
    text: 'Track purchase price and current value to see how your assets perform.',
  },
  {
    icon: 'wallet',
    title: 'Portfolio',
    text: 'View your total portfolio value with a grouped summary by asset type.',
  },
];

/* ---------- bill splitters ---------- */

export const billSplitters = [
  {
    id: 'bs1',
    title: 'Road Trip Expenses',
    total: 330.0,
    mode: 'percentage',
    iconBg: '#43A047',
    icon: 'wallet',
    spread: 0,
    payerId: 'p-alice',
    participants: [
      { id: 'p-alice', name: 'Alice', percent: 50, share: 165, paid: 0, color: '#00897B' },
      { id: 'p-bob', name: 'Bob', percent: 50, share: 165, paid: 0, color: '#1E88E5' },
    ],
  },
  {
    id: 'bs2',
    title: 'Dinner at Restaurant',
    total: 94.0,
    mode: 'equal',
    iconBg: '#00897B',
    icon: 'cash',
    payerId: 'p-alice',
    participants: [
      { id: 'p-bob', name: 'Bob', percent: 50, share: 47, paid: 47, color: '#1E88E5' },
      { id: 'p-alice', name: 'Alice', percent: 50, share: 47, paid: 47, color: '#00897B' },
    ],
  },
];

export const howBillSplitterWorks = [
  {
    icon: 'split',
    title: 'Split Types',
    lines: [
      'Equal: Split the bill evenly among all participants.',
      'Custom: Set a specific amount for each person.',
      'Percentage: Assign a percentage of the total to each person.',
    ],
  },
  {
    icon: 'users',
    title: 'Participants',
    text: 'Add people from your contacts and assign who paid for the bill.',
  },
  {
    icon: 'handshake',
    title: 'Settlement',
    text: 'Mark bills as settled when everyone has paid their share. Track active and settled bills separately.',
  },
  {
    icon: 'wallet',
    title: 'Balances',
    text: 'View net balances across all bills using the wallet icon in the app bar.',
  },
  {
    icon: 'trend',
    title: 'Tracking',
    text: 'Filter between active and settled bills. Sort by name, amount, or date to find what you need.',
  },
];

export const contacts = [
  { id: 'p-alice', name: 'Alice', color: '#00897B' },
  { id: 'p-bob', name: 'Bob', color: '#1E88E5' },
  { id: 'p-carol', name: 'Carol', color: '#8E24AA' },
  { id: 'p-dan', name: 'Dan', color: '#EF6C00' },
];

/* ---------- loans ---------- */

export const loans = [
  {
    id: 'ln1',
    title: 'Car Loan',
    subtitle: 'Car Loan record',
    kind: 'lending',
    person: 'Bob',
    total: 17757.0,
    paid: 421.0,
    due: '2027-11-19',
    account: 'Raj Card',
    accent: '#3949AB',
    tileFg: '#FFFFFF',
    surface: '#252542',
    textSoft: '#A5A7C4',
    track: '#343559',
    fill: '#5C6BC0',
    pillBg: '#2F3159',
    pillFg: '#5C6BC0',
  },
  {
    id: 'ln2',
    title: 'Home Renovation Loan',
    subtitle: 'Borrowed from Alice',
    kind: 'borrowing',
    person: 'Alice',
    total: 18000.0,
    paid: 894.0,
    due: '2027-06-01',
    account: 'HDFC Bank',
    accent: '#8E24AA',
    tileFg: '#FFFFFF',
    surface: '#2A1F2E',
    textSoft: '#BBA8C0',
    track: '#3E2C45',
    fill: '#AB47BC',
    pillBg: '#3A2B41',
    pillFg: '#BA68C8',
  },
  {
    id: 'ln3',
    title: 'Education Loan',
    subtitle: 'Borrowed from Carol',
    kind: 'borrowing',
    person: 'Carol',
    total: 8000.0,
    paid: 1000.0,
    due: '2027-01-15',
    account: 'Raj Card',
    accent: '#00897B',
    tileFg: '#FFFFFF',
    surface: '#1E2A28',
    textSoft: '#9FB8B3',
    track: '#2C3D3A',
    fill: '#26A69A',
    pillBg: '#2A3A37',
    pillFg: '#4DB6AC',
  },
];

export const howLoansWork = [
  {
    icon: 'swipe',
    title: 'Loan Types',
    lines: [
      'Lending: Money you gave to someone. They owe you.',
      'Borrowing: Money you received from someone. You owe them.',
    ],
  },
  {
    icon: 'cash',
    title: 'Payments',
    text: 'Record partial or full payments to track the remaining balance on each loan.',
  },
  {
    icon: 'wallet',
    title: 'Summary',
    text: 'View total lending, borrowing, and net balance at the top of the page.',
  },
  {
    icon: 'check',
    title: 'Status',
    text: 'Active loans show remaining balance. Completed loans are automatically tracked when fully paid.',
  },
  {
    icon: 'user',
    title: 'People',
    text: 'Link a loan to a person to track who you lent to or borrowed from. The linked person appears in loan details.',
  },
  {
    icon: 'due',
    title: 'Due Dates',
    text: 'Set a due date for each loan. Overdue loans are flagged automatically, and a countdown shows days remaining.',
  },
  {
    icon: 'trend',
    title: 'Progress',
    text: 'A visual progress bar shows how much has been repaid. Track paid amount, remaining balance, and completion percentage.',
  },
  {
    icon: 'sort',
    title: 'Sorting',
    text: 'Sort loans by name or amount to quickly find what you need. Tap the filter icon to change sort order.',
  },
];

/** "today" for the reference data, so the 377-day countdown matches the reference */
export const REFERENCE_TODAY = '2026-11-07';
