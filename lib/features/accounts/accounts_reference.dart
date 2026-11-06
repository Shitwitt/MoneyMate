import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../shared/widgets.dart';
import '../home/home_screen.dart';
import '../transactions/transaction_tile.dart';
import 'accounts_screen.dart';

class AccountsReferenceScreen extends ConsumerStatefulWidget {
  const AccountsReferenceScreen({super.key});
  @override
  ConsumerState<AccountsReferenceScreen> createState() =>
      _AccountsReferenceScreenState();
}

class _AccountsReferenceScreenState
    extends ConsumerState<AccountsReferenceScreen> {
  int page = 0;
  bool archived = false;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    if (MediaQuery.sizeOf(context).width >= 760 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3)
      return const AccountsListScreen();
    final accounts = ledger.data.accounts
        .where((a) => archived || !a.archived)
        .toList();
    final selected = accounts.isEmpty
        ? null
        : accounts[page.clamp(0, accounts.length - 1)];
    final entries =
        selected == null
              ? <MoneyTransaction>[]
              : ledger.data.transactions
                    .where(
                      (e) =>
                          e.accountId == selected.id ||
                          e.toAccountId == selected.id,
                    )
                    .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return FeaturePage(
      title: 'Accounts',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Manage accounts',
          icon: const Icon(Icons.view_carousel_outlined),
          onSelected: (value) {
            if (value == 'add') editAccount(context, ref);
            if (value == 'list') openPage(context, const AccountsListScreen());
            if (value == 'edit' && selected != null)
              editAccount(context, ref, selected);
            if (value == 'archived') setState(() => archived = !archived);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'add', child: Text('Add account')),
            if (selected != null)
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit selected account'),
              ),
            const PopupMenuItem(
              value: 'list',
              child: Text('Grouped account list'),
            ),
            PopupMenuItem(
              value: 'archived',
              child: Text(
                archived ? 'Hide archived accounts' : 'Show archived accounts',
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: IconButton.filledTonal(
            tooltip: 'Profiles & settings',
            onPressed: () => showProfileMenu(context, ref),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ),
      ],
      child: accounts.isEmpty
          ? EmptyState(
              title: 'A home for your money',
              message: 'Create a local bookkeeping account to start tracking.',
              icon: Icons.account_balance_outlined,
              action: 'Add account',
              onAction: () => editAccount(context, ref),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                SizedBox(
                  height:
                      220 *
                      MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.8),
                  child: PageView.builder(
                    itemCount: accounts.length,
                    onPageChanged: (p) => setState(() => page = p),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 3),
                      child: AccountReferenceCard(accounts[index], ledger),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < accounts.length; i++)
                      AnimatedContainer(
                        duration: referenceMotion(context, 160),
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: i == page ? 1 : .25),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                if (selected != null) AccountPeriodComparison(selected, ledger),
                const SizedBox(height: 24),
                SectionHeader(
                  'Transactions',
                  trailing: IconButton(
                    tooltip: 'Account details and full transaction filters',
                    onPressed: () =>
                        openPage(context, AccountDetailScreen(selected!.id)),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
                if (entries.isEmpty)
                  const TonalCard(
                    child: Text('No transactions in this account yet.'),
                  ),
                for (final entry in entries.take(100))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: TonalCard(
                      radius: 16,
                      padding: EdgeInsets.zero,
                      child: TransactionTile(entry),
                    ),
                  ),
                if (entries.length > 100)
                  OutlinedButton(
                    onPressed: () =>
                        openPage(context, AccountDetailScreen(selected!.id)),
                    child: Text('View all ${entries.length} transactions'),
                  ),
              ],
            ),
    );
  }
}

class AccountReferenceCard extends StatelessWidget {
  final Account account;
  final Ledger ledger;
  const AccountReferenceCard(this.account, this.ledger, {super.key});
  @override
  Widget build(BuildContext context) {
    if (account.imageBase64.isNotEmpty || account.cardStyle != 'auto')
      return AccountArtwork(
        account: account,
        balance: ledger.accountBalance(account.id),
        hidden: ledger.settings.hideAmounts,
        indian: ledger.settings.numberFormat == 'indian',
        locale: ledger.settings.locale,
        onTap: () => openPage(context, AccountDetailScreen(account.id)),
      );
    final background = Color.alphaBlend(
      Color(account.color)
          .withValues(alpha: AppColors.dark(context) ? .28 : .13),
      Theme.of(context).colorScheme.surface,
    );
    Color accent = Color(account.color);
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05));
    }

    if (contrast(accent, background) < 4.5)
      accent = AppColors.dark(context)
          ? const Color(0xffFFD5C2)
          : AppColors.ink;
    return TonalCard(
      radius: 28,
      color: background,
      onTap: () => openPage(context, AccountDetailScreen(account.id)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColorIcon(account.icon, account.color, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      account.holderName.isNotEmpty
                          ? account.holderName
                          : '${account.currency} ${account.parentId.isEmpty ? 'Main' : 'Linked'} Account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (account.lastDigits.isNotEmpty)
                SmallTag(
                  ledger.settings.hideAmounts
                      ? '••••'
                      : '•• ${account.lastDigits}',
                ),
              if (account.archived) const SmallTag('Archived'),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total balance',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: AmountText(
                      ledger.accountBalance(account.id),
                      currency: account.currency,
                      animate: true,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  SmallTag(
                    account.excluded ? 'Excluded' : titleCase(account.type),
                  ),
                  if (ledger.data.accounts.any((a) => a.parentId == account.id))
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 6),
                      child: SmallTag(
                        '${ledger.data.accounts.where((a) => a.parentId == account.id).length} linked',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AccountPeriodComparison extends StatelessWidget {
  final Account account;
  final Ledger ledger;
  const AccountPeriodComparison(this.account, this.ledger, {super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(),
        current = financialMonth(DateTime.now(), ledger.settings.monthStart),
        previous = previousMonth(DateTime.now(), ledger.settings.monthStart);
    final records = ledger.data.transactions.where(
      (e) =>
          e.accountId == account.id &&
          e.type != 'transfer' &&
          !e.date.isAfter(now),
    );
    Widget metric(String type) {
      final amount = ledger.total(type, current, entries: records),
          last = ledger.total(type, previous, entries: records);
      final change = last == 0 ? null : (amount - last) / last * 100;
      final positive = change != null && change >= 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleCase(type), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AmountText(
                amount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!ledger.settings.hideAmounts)
                Text(
                  change == null
                      ? '—'
                      : '${positive ? '↑' : '↓'}${change.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.semantic(context, type),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            ledger.settings.hideAmounts
                ? 'Compared to •••• last month'
                : 'Compared to ${money(last, ledger.currency, locale: ledger.settings.locale)} last month',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: metric('income')),
            const SizedBox(width: 18),
            Expanded(child: metric('expense')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Posted cash flow in ${ledger.currency} at your reference rates. The card is the recorded native-currency balance, including scheduled entries.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
