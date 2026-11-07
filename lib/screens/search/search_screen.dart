import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/theme/paisa_colors.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_transaction_screen.dart';

/// Real-time global search over every transaction.
///
/// Matches the title, the notes **and** the amount (so typing `450` finds the
/// ₹450 dinner), and can be narrowed with type / account / category chips.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  TransactionType? _type;
  String? _accountId;
  String? _categoryId;

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _type != null || _accountId != null || _categoryId != null;

  void _clearFilters() {
    setState(() {
      _type = null;
      _accountId = null;
      _categoryId = null;
    });
  }

  /// Applies the query and filters to the provider's ledger.
  List<TransactionModel> _results(PaisaProvider provider) {
    final String needle = _query.trim().toLowerCase();
    final double? amountNeedle =
        needle.isEmpty ? null : double.tryParse(needle.replaceAll(',', ''));

    final List<TransactionModel> matches = <TransactionModel>[];
    for (final TransactionModel transaction in provider.transactions) {
      if (_type != null && transaction.type != _type) continue;
      if (_accountId != null &&
          transaction.accountId != _accountId &&
          transaction.toAccountId != _accountId) {
        continue;
      }
      if (_categoryId != null && transaction.categoryId != _categoryId) {
        continue;
      }
      if (needle.isEmpty) {
        matches.add(transaction);
        continue;
      }

      final String title = transaction.name.toLowerCase();
      final String notes = (transaction.description ?? '').toLowerCase();
      final String category =
          provider.categoryName(transaction.categoryId).toLowerCase();
      final String amountText =
          transaction.amount.toStringAsFixed(2).toLowerCase();
      final String amountWhole =
          transaction.amount.round().toString().toLowerCase();

      final bool textHit = title.contains(needle) ||
          notes.contains(needle) ||
          category.contains(needle);
      final bool amountHit = amountNeedle != null &&
          (transaction.amount == amountNeedle ||
              amountWhole.contains(needle.replaceAll(',', '')) ||
              amountText.contains(needle.replaceAll(',', '')));

      if (textHit || amountHit) matches.add(transaction);
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<TransactionModel> results = _results(provider);
    final String trimmed = _query.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: <Widget>[
          // ---------------- Query bar ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _queryController,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search title, notes or amount',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: trimmed.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _queryController.clear();
                          setState(() => _query = '');
                          _focusNode.requestFocus();
                        },
                      ),
              ),
            ),
          ),

          // ---------------- Filter chips ----------------
          _FilterBar(
            type: _type,
            accountId: _accountId,
            categoryId: _categoryId,
            onTypeChanged: (TransactionType? type) =>
                setState(() => _type = type),
            onAccountChanged: (String? id) => setState(() => _accountId = id),
            onCategoryChanged: (String? id) =>
                setState(() => _categoryId = id),
            onClear: _clearFilters,
            hasFilters: _hasFilters,
          ),
          Divider(height: 1, color: scheme.outlineVariant),

          // ---------------- Result count ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: <Widget>[
                Text(
                  trimmed.isEmpty && !_hasFilters
                      ? 'All transactions'
                      : '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (trimmed.isNotEmpty || _hasFilters)
                  Text(
                    'newest first',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // ---------------- Results ----------------
          Expanded(
            child: results.isEmpty
                ? LedgerEmptyState(
                    icon: Icons.search_off_rounded,
                    title: trimmed.isEmpty && !_hasFilters
                        ? 'Nothing to search yet'
                        : 'No matches',
                    message: trimmed.isEmpty && !_hasFilters
                        ? 'Record a transaction and it becomes searchable here.'
                        : 'Try a different word, a smaller amount, or clear the filters.',
                    action: _hasFilters
                        ? TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: results.length,
                    itemBuilder: (BuildContext context, int index) {
                      final TransactionModel transaction = results[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TransactionTile(
                          transaction: transaction,
                          formatter: provider.formatter,
                          category:
                              provider.categoryById(transaction.categoryId),
                          account:
                              provider.accountById(transaction.accountId),
                          toAccount: provider
                              .accountById(transaction.toAccountId),
                          hideAmounts: provider.hideAmounts,
                          showDate: true,
                          onTap: () => openAddTransactionScreen(
                            context,
                            existing: transaction,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// The horizontally scrolling filter chip bar: type, then account, then
/// category. Each opens a menu; an active filter shows a check and can be
/// toggled off by re-selecting it.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.onTypeChanged,
    required this.onAccountChanged,
    required this.onCategoryChanged,
    required this.onClear,
    required this.hasFilters,
  });

  final TransactionType? type;
  final String? accountId;
  final String? categoryId;
  final ValueChanged<TransactionType?> onTypeChanged;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onClear;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);

    final AccountModel? selectedAccount = provider.accountById(accountId);
    final CategoryModel? selectedCategory = provider.categoryById(categoryId);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        children: <Widget>[
          // Type -------------------------------------------------------
          _MenuChip<TransactionType?>(
            icon: type?.icon ?? Icons.swap_vert_rounded,
            label: type?.label ?? 'Type',
            active: type != null,
            accent: type == null
                ? null
                : switch (type!) {
                    TransactionType.expense => colors.expense,
                    TransactionType.income => colors.income,
                    TransactionType.transfer => colors.transfer,
                  },
            items: <PopupMenuEntry<TransactionType?>>[
              const PopupMenuItem<TransactionType?>(
                value: null,
                child: Text('All types'),
              ),
              for (final TransactionType value in TransactionType.values)
                PopupMenuItem<TransactionType?>(
                  value: value,
                  child: Row(
                    children: <Widget>[
                      Icon(value.icon, size: 18),
                      const SizedBox(width: 10),
                      Text(value.label),
                    ],
                  ),
                ),
            ],
            onSelected: onTypeChanged,
          ),
          const SizedBox(width: 8),

          // Account ----------------------------------------------------
          _MenuChip<String?>(
            icon: Icons.account_balance_wallet_outlined,
            label: selectedAccount?.title ?? 'Account',
            active: accountId != null,
            items: <PopupMenuEntry<String?>>[
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All accounts'),
              ),
              for (final AccountModel account in provider.accounts)
                PopupMenuItem<String?>(
                  value: account.id,
                  child: Row(
                    children: <Widget>[
                      Icon(account.cardType.icon, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          account.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onSelected: onAccountChanged,
          ),
          const SizedBox(width: 8),

          // Category ---------------------------------------------------
          _MenuChip<String?>(
            icon: Icons.category_outlined,
            label: selectedCategory?.name ?? 'Category',
            active: categoryId != null,
            items: <PopupMenuEntry<String?>>[
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All categories'),
              ),
              for (final CategoryModel category in provider.categories)
                PopupMenuItem<String?>(
                  value: category.id,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(category.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onSelected: onCategoryChanged,
          ),
          if (hasFilters) ...<Widget>[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.items,
    required this.onSelected,
    this.accent,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color? accent;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color effective = accent ?? scheme.primary;

    return PopupMenuButton<T?>(
      tooltip: label,
      itemBuilder: (BuildContext context) => items,
      onSelected: onSelected,
      offset: const Offset(0, 44),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? effective.withValues(alpha: 0.14)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? effective : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: active ? effective : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? effective : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: active ? effective : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
