import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/services/receipt_service.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/money.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transactions_screen.dart';

Future<void> editAccount(
  BuildContext context,
  WidgetRef ref, [
  Account? initial,
]) async {
  final profile = ref.read(profileProvider)!;
  final name = TextEditingController(text: initial?.name ?? '');
  final opening = TextEditingController(
    text: initial == null
        ? '0'
        : fromMinor(initial.openingMinor, initial.currency).toString(),
  );
  final notes = TextEditingController(text: initial?.notes ?? '');
  var currency = initial?.currency ?? profile.profile.currency,
      type = initial?.type ?? 'bank',
      icon = initial?.icon ?? 'bank';
  var color = initial?.color ?? palette.first;
  var excluded = initial?.excluded ?? false,
      archived = initial?.archived ?? false;
  var image = initial?.imageBase64 ?? '';
  var cardStyle = initial?.cardStyle ?? 'auto';
  await showEditor(
    context,
    title: initial == null ? 'A home for your money' : 'Edit account',
    description: 'Use a negative opening balance for credit card debt. Changing an opening balance adjusts the ledger without creating a transaction.',
    fields: (context, setLocal) => [
      AnimatedBuilder(
        animation: Listenable.merge([name, opening]),
        builder: (context, _) {
          final value = num.tryParse(opening.text.replaceAll(',', ''));
          final amount = value != null && value.isFinite && value.abs() < 1e12
              ? toMinor(value, currency)
              : 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: AccountArtwork(
              account: Account(
                id: initial?.id ?? 'preview',
                name: name.text,
                currency: currency,
                type: type,
                color: color,
                icon: icon,
                cardStyle: cardStyle,
                imageBase64: image,
              ),
              balance: amount,
              preview: true,
            ),
          );
        },
      ),
      formText(name, 'Account name', required: true),
      formSelect(
        'Account type',
        type,
        accountTypes,
        (value) => setLocal(() {
          type = value;
          icon = value;
        }),
      ),
      formSelect(
        'Currency',
        currency,
        currencySymbols.keys.toList(),
        (value) => setLocal(() => currency = value),
      ),
      formText(opening, 'Opening balance', numeric: true, required: true),
      formText(notes, 'Notes', lines: 2),
      const SectionHeader('The finishing touch'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final finish in accountFinishes.entries)
            ChoiceChip(
              label: Text(finish.value),
              selected: cardStyle == finish.key,
              onSelected: (_) => setLocal(() => cardStyle = finish.key),
            ),
        ],
      ),
      const SizedBox(height: 16),
      formColors(color, (value) => setLocal(() => color = value)),
      ExpansionTile(
        title: const Text('Choose an icon'),
        children: [formIcons(icon, (value) => setLocal(() => icon = value))],
      ),
      Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => runSafe(context, () async {
              final photo = await ReceiptService.pick(ImageSource.gallery);
              if (photo != null) setLocal(() => image = photo.data);
            }),
            icon: const Icon(Icons.photo_outlined),
            label: Text(
              image.isEmpty ? 'Custom account image' : 'Change image',
            ),
          ),
          if (image.isNotEmpty)
            IconButton(
              tooltip: 'Remove image',
              onPressed: () => setLocal(() => image = ''),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Exclude from net worth'),
        value: excluded,
        onChanged: (value) => setLocal(() => excluded = value),
      ),
      if (initial != null)
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Archive account'),
          subtitle: const Text('Keep its history; hide it from new entries'),
          value: archived,
          onChanged: (value) => setLocal(() => archived = value),
        ),
    ],
    onSave: () async {
      final number = num.tryParse(opening.text.replaceAll(',', ''));
      if (number == null || !number.isFinite) {
        throw const FormatException('Enter a valid opening balance');
      }
      await ref
          .read(appProvider.notifier)
          .upsertAccount(
            Account(
              id: initial?.id ?? uuid.v4(),
              name: name.text.trim(),
              currency: currency,
              type: type,
              openingMinor: toMinor(number, currency),
              color: color,
              icon: icon,
              notes: notes.text.trim(),
              excluded: excluded,
              archived: archived,
              imageBase64: image,
              cardStyle: cardStyle,
            ),
          );
    },
  );
  name.dispose();
  opening.dispose();
  notes.dispose();
}

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});
  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String? selectedId;
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider)!;
    final profile = ledger.data;
    final month = financialMonth(DateTime.now(), ledger.settings.monthStart);
    final wide = MediaQuery.sizeOf(context).width > 1000;
    Widget accountList() => ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your money, in one place',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                AmountText(
                  ledger.accountsTotal,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Included accounts · converted at your reference rates',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final type in accountTypes)
          if (profile.accounts.any((item) => item.type == type))
            ExpansionTile(
              key: PageStorageKey(type),
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                titleCase(type),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                for (final account in profile.accounts.where(
                  (item) => item.type == type,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AccountOverviewCard(
                      account: account,
                      ledger: ledger,
                      month: month,
                      onTap: () {
                        if (wide) {
                          setState(() => selectedId = account.id);
                        } else {
                          openPage(context, AccountDetailScreen(account.id));
                        }
                      },
                    ),
                  ),
              ],
            ),
      ],
    );
    return FeaturePage(
      title: AppLocalizations.of(context).accounts,
      actions: [
        IconButton(
          tooltip: 'Add account',
          onPressed: () => editAccount(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: wide
          ? Row(
              children: [
                SizedBox(width: 380, child: accountList()),
                const SizedBox(width: 20),
                Expanded(
                  child: selectedId == null
                      ? const EmptyState(
                          title: 'Pick an account',
                          message:
                              'Explore its balance and activity side by side.',
                          icon: Icons.account_balance_rounded,
                        )
                      : AccountDetailScreen(
                          selectedId!,
                          key: ValueKey(selectedId),
                        ),
                ),
              ],
            )
          : accountList(),
    );
  }
}

class AccountOverviewCard extends StatelessWidget {
  final Account account;
  final Ledger ledger;
  final DateWindow month;
  final VoidCallback onTap;
  const AccountOverviewCard({
    super.key,
    required this.account,
    required this.ledger,
    required this.month,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountArtwork(
          account: account,
          balance: ledger.accountBalance(account.id),
          hidden: ledger.settings.hideAmounts,
          indian: ledger.settings.numberFormat == 'indian',
          locale: ledger.settings.locale,
          onTap: onTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              for (final income in [true, false])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      income
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 17,
                      color: AppColors.semantic(
                        context,
                        income ? 'income' : 'expense',
                      ),
                    ),
                    const SizedBox(width: 7),
                    AmountText(
                      _accountFlow(ledger.data, account.id, month, income),
                      currency: account.currency,
                      compact: true,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      income ? 'in this month' : 'out this month',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

int _accountFlow(
  ProfileData data,
  String id,
  DateWindow dates,
  bool incoming,
) => data.transactions
    .where((entry) => dates.contains(entry.date))
    .fold(
      0,
      (sum, entry) =>
          sum +
          (incoming
              ? (entry.accountId == id && entry.type == 'income'
                    ? entry.amountMinor
                    : entry.type == 'transfer' && entry.toAccountId == id
                    ? entry.toAmountMinor
                    : 0)
              : entry.accountId == id && entry.type != 'income'
              ? entry.amountMinor
              : 0),
    );

class AccountDetailScreen extends ConsumerWidget {
  final String id;
  const AccountDetailScreen(this.id, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final account = ledger.data.accounts
        .where((item) => item.id == id)
        .firstOrNull;
    if (account == null) {
      return const Scaffold(
        body: EmptyState(
          title: 'Account removed',
          message: 'Go back to your accounts.',
        ),
      );
    }
    return FeaturePage(
      title: account.name,
      padded: false,
      actions: [
        IconButton(
          tooltip: 'Edit account',
          onPressed: () => editAccount(context, ref, account),
          icon: const Icon(Icons.edit_outlined),
        ),
        PopupMenuButton(
          onSelected: (_) async {
            if (await confirm(
                  context,
                  'Delete account?',
                  'Only unused accounts can be deleted. Archive an account to keep its history.',
                ) &&
                context.mounted) {
              final deleted = await runSafe(
                context,
                () => ref.read(appProvider.notifier).deleteAccount(id),
              );
              if (deleted && context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete account')),
          ],
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: Color(account.color).withValues(alpha: .18),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AmountText(
                      ledger.accountBalance(id),
                      currency: account.currency,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    if (account.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(account.notes),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              openPage(context, TransactionForm(accountId: id)),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add entry'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: ledger.data.accounts.length < 2
                              ? null
                              : () => openPage(
                                  context,
                                  TransactionForm(
                                    accountId: id,
                                    initialType: 'transfer',
                                  ),
                                ),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Transfer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TransactionsScreen(
              key: ValueKey(id),
              title: 'Account activity',
              initialFilter: TransactionFilter(accounts: {id}),
            ),
          ),
        ],
      ),
    );
  }
}
