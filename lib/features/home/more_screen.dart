import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets.dart';
import '../accounts/accounts_screen.dart';
import '../achievements/achievements_screen.dart';
import '../assets/assets_screen.dart';
import '../bills/bills_screen.dart';
import '../budgets/budgets_screen.dart';
import '../catalog/catalog_screen.dart';
import '../goals/goals_screen.dart';
import '../loans/loans_screen.dart';
import '../recurring/recurring_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/help_screen.dart';
import '../settings/premium_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/templates_screen.dart';
import '../transactions/transactions_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pro = ref.watch(appProvider).settings.isPro;
    final items = [
      (l.accounts, 'bank', 0xffa4ca6a, const AccountsScreen()),
      (l.activity, 'expense', 0xfff2b88f, const TransactionsScreen()),
      (l.reports, 'asset', 0xffb6a5e8, const ReportsScreen()),
      (l.budgets, 'category', 0xffe4c569, const BudgetsScreen()),
      (l.goals, 'goal', 0xff88bacc, const GoalsScreen()),
      (l.subscriptions, 'bills', 0xffb6a5e8, const RecurringScreen()),
      (l.loans, 'loan', 0xff88c7b5, const LoansScreen()),
      ('Bill splitter', 'person', 0xffed9c9b, const BillsScreen()),
      (l.assets, 'asset', 0xffe4c569, const AssetsScreen()),
      (l.categories, 'category', 0xffb6a5e8, const CatalogScreen('category')),
      (l.labels, 'label', 0xfff2b88f, const CatalogScreen('label')),
      (l.people, 'person', 0xff88c7b5, const CatalogScreen('person')),
      (l.places, 'place', 0xff88bacc, const CatalogScreen('place')),
      ('Quick templates', 'work', 0xffa4ca6a, const TemplatesScreen()),
      (l.achievements, 'gift', 0xffe4c569, const AchievementsScreen()),
      (l.settings, 'category', 0xffb9b7aa, const SettingsScreen()),
    ];
    return FeaturePage(
      title: 'A little more',
      actions: [
        IconButton(
          tooltip: 'Help & FAQ',
          onPressed: () => openPage(context, const HelpScreen()),
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: const Icon(Icons.auto_awesome_rounded, size: 30),
                  title: Text(
                    pro ? 'Your Plus space' : 'Make a little more room',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    pro
                        ? 'Unlimited possibilities. Same privacy.'
                        : 'Explore PaisaClone Plus · simulated & free',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => openPage(context, const PremiumScreen()),
                ),
              ),
            ),
          ),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.crossAxisExtent > 850
                  ? 4
                  : constraints.crossAxisExtent > 550
                  ? 3
                  : 2;
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => openPage(context, item.$4),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ColorIcon(item.$2, item.$3, size: 42),
                            Text(
                              item.$1,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
