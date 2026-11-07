import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../onboarding_state.dart';
import '../widgets/onboarding_scaffold.dart';

/// Page 3 — preset accounts.
///
/// Tapping a card selects it; the pencil/amount chip opens an opening-balance
/// dialog. Only one preset can be active at a time because onboarding creates a
/// single account — see [OnboardingState.buildAccount] for why.
class AccountsPage extends StatelessWidget {
  const AccountsPage({
    super.key,
    required this.selectedPreset,
    required this.currencyCode,
    required this.balanceFor,
    required this.onSelect,
    required this.onEditBalance,
    required this.onContinue,
    required this.onBack,
    required this.onSkip,
  });

  final AccountPreset selectedPreset;
  final String currencyCode;
  final double Function(AccountPreset preset) balanceFor;
  final ValueChanged<AccountPreset> onSelect;
  final ValueChanged<AccountPreset> onEditBalance;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final CurrencyFormatter formatter =
        CurrencyFormatter.fromCode(currencyCode);

    return OnboardingScaffold(
      step: 3,
      totalSteps: 5,
      title: context.tr('accountsTitle'),
      subtitle: context.tr('accountsSubtitle'),
      onBack: onBack,
      onSkip: onSkip,
      primaryLabel: context.tr('onboardingNext'),
      onPrimary: onContinue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final AccountPreset preset in AccountPreset.values) ...<Widget>[
            _PresetCard(
              preset: preset,
              selected: preset == selectedPreset,
              balanceLabel: formatter.formatWhole(balanceFor(preset)),
              onTap: () => onSelect(preset),
              onEditBalance: () => onEditBalance(preset),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Text(
            'You can add more accounts — bank, cash or card — any time from '
            'the Accounts tab.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.balanceLabel,
    required this.onTap,
    required this.onEditBalance,
  });

  final AccountPreset preset;
  final bool selected;
  final String balanceLabel;
  final VoidCallback onTap;
  final VoidCallback onEditBalance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color tint = Color(preset.color);

    return Semantics(
      button: true,
      selected: selected,
      label: preset.defaultTitle,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? scheme.secondaryContainer
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? scheme.secondary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withAlpha(38),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  preset.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _localizedPresetName(context, preset),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? scheme.onSecondaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onSecondaryContainer.withAlpha(200)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onEditBalance,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            balanceLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? scheme.primary : Colors.transparent,
                      border: Border.all(
                        color: selected ? scheme.primary : scheme.outline,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: scheme.onPrimary,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _localizedPresetName(BuildContext context, AccountPreset preset) {
    switch (preset) {
      case AccountPreset.cash:
        return context.tr('accountCash');
      case AccountPreset.bank:
        return context.tr('accountBank');
      case AccountPreset.card:
        return context.tr('accountCard');
    }
  }
}

/// The opening-balance dialog.
///
/// Returns the parsed amount, or `null` when cancelled. Kept public so the page
/// and any later "edit account" sheet share exactly one implementation.
Future<double?> showOpeningBalanceDialog(
  BuildContext context, {
  required String title,
  required String currencySymbol,
  required double initialValue,
  String currencyCode = 'INR',
}) {
  final CurrencyFormatter formatter = CurrencyFormatter.fromCode(currencyCode);
  final TextEditingController controller = TextEditingController(
    text: initialValue == 0 ? '' : initialValue.toString(),
  );
  String? errorText;

  return showDialog<double>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void submit() {
            final String raw = controller.text.trim();
            if (raw.isEmpty) {
              Navigator.of(dialogContext).pop(0);
              return;
            }
            final double? parsed = formatter.parse(raw);
            if (parsed == null) {
              setState(() => errorText = 'Enter a valid amount');
              return;
            }
            if (parsed < 0) {
              setState(() => errorText = 'Amount cannot be negative');
              return;
            }
            Navigator.of(dialogContext).pop(parsed);
          }

          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    prefixText: '$currencySymbol ',
                    hintText: '0',
                    labelText: context.tr('accountInitial'),
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The money you already have in this account today.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                onPressed: submit,
                child: Text(context.tr('done')),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}
