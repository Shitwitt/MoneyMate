import 'package:flutter/material.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../widgets/onboarding_scaffold.dart';

/// Page 5 — searchable currency picker with INR pinned to the top.
class CurrencyPage extends StatefulWidget {
  const CurrencyPage({
    super.key,
    required this.selectedCode,
    required this.onSelect,
    required this.onFinish,
    required this.onBack,
    required this.onSkip,
    this.finishing = false,
  });

  final String selectedCode;
  final ValueChanged<String> onSelect;
  final VoidCallback onFinish;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  /// Disables the action while the first write happens.
  final bool finishing;

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  late final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<CurrencyDefinition> results = CurrencyTable.search(_query);

    return OnboardingScaffold(
      step: 5,
      totalSteps: 5,
      title: context.tr('currencyTitle'),
      subtitle: context.tr('currencyFooter'),
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      primaryLabel: context.tr('continueToApp'),
      onPrimary: widget.onFinish,
      primaryBusy: widget.finishing,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: (String value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.tr('currencySearch'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No currency matches "$_query"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 68,
                  color: scheme.outlineVariant.withAlpha(120),
                ),
                itemBuilder: (BuildContext context, int index) {
                  final CurrencyDefinition currency = results[index];
                  final bool selected = currency.code == widget.selectedCode;
                  final CurrencyFormatter formatter =
                      CurrencyFormatter(currency: currency);
                  return _CurrencyRow(
                    currency: currency,
                    selected: selected,
                    sample: formatter.format(125450),
                    isPinned: currency.code == CurrencyTable.inr.code,
                    onTap: () => widget.onSelect(currency.code),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    required this.selected,
    required this.sample,
    required this.isPinned,
    required this.onTap,
  });

  final CurrencyDefinition currency;
  final bool selected;
  final String sample;
  final bool isPinned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: currency.pickerLabel,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currency.symbol,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            currency.pickerLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isPinned) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Default',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onTertiaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sample,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary)
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: scheme.outlineVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
