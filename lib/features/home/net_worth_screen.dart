import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/providers.dart';
import '../../core/utils/dates.dart';
import '../../shared/widgets.dart';
import '../settings/exchange_rates_screen.dart';

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final currencies = <String, int>{};
    for (final account in ledger.data.accounts.where(
      (account) => !account.excluded,
    )) {
      currencies[account.currency] =
          (currencies[account.currency] ?? 0) +
          ledger.accountBalance(account.id);
    }
    final window = financialMonth(DateTime.now(), ledger.settings.monthStart);
    final income = ledger.total('income', window),
        expense = ledger.total('expense', window);
    final past = previousMonth(DateTime.now(), ledger.settings.monthStart);
    return FeaturePage(
      title: 'The bigger balance',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          StatCard(
            title: 'Net worth',
            value: AmountText(ledger.netWorth),
            icon: Icons.spa_outlined,
            caption: 'Included accounts + assets + to receive − to pay',
          ),
          const SizedBox(height: 22),
          const SectionHeader('A world of currencies'),
          for (final entry in currencies.entries)
            Card(
              child: ListTile(
                title: Text(entry.key),
                subtitle: AmountText(
                  ledger.inBase(entry.value, entry.key),
                  currency: ledger.currency,
                ),
                trailing: AmountText(
                  entry.value,
                  currency: entry.key,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          const SizedBox(height: 18),
          for (final row in [
            ('Accounts', ledger.accountsTotal),
            ('Assets', ledger.assetsTotal),
            ('Loans · to receive', ledger.toReceive),
            ('Loans · to pay', -ledger.toPay),
          ])
            ListTile(title: Text(row.$1), trailing: AmountText(row.$2)),
          const SectionHeader('This financial month'),
          ListTile(
            title: const Text('Net cash flow'),
            trailing: AmountText(income - expense),
          ),
          ListTile(
            title: const Text('Savings rate'),
            trailing: Text(
              ledger.settings.hideAmounts
                  ? '••••'
                  : '${income > 0 ? ((income - expense) / income * 100).toStringAsFixed(1) : '0'}%',
            ),
          ),
          ListTile(
            title: const Text('Previous month’s cash flow'),
            trailing: AmountText(
              ledger.total('income', past) - ledger.total('expense', past),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Account totals include archived accounts unless excluded. Loans use outstanding principal plus flat interest; assets use your last entered value. Goals are allocations, so they are not added again. Reference rates are manual, not live market quotes.',
              style: TextStyle(fontSize: 12, height: 1.7),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => openPage(context, const ExchangeRatesScreen()),
            icon: const Icon(Icons.currency_exchange_rounded),
            label: const Text('Manage reference rates'),
          ),
        ],
      ),
    );
  }
}
