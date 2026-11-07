import 'package:flutter/material.dart';

import '../../../core/constants/icons.dart';
import '../../../core/l10n/app_strings.dart';
import '../onboarding_state.dart';
import '../widgets/onboarding_scaffold.dart';

/// Page 4 — multi-select grid of the twelve default categories.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({
    super.key,
    required this.selectedIds,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onContinue,
    required this.onBack,
    required this.onSkip,
  });

  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int count = selectedIds.length;

    return OnboardingScaffold(
      step: 4,
      totalSteps: 5,
      title: context.tr('categoriesTitle'),
      subtitle: context.tr('categoriesSubtitle'),
      onBack: onBack,
      onSkip: onSkip,
      primaryLabel: context.tr('onboardingNext'),
      onPrimary: onContinue,
      primaryEnabled: count > 0,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count selected',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: count == OnboardingCategories.all.length
                    ? onClearAll
                    : onSelectAll,
                child: Text(
                  count == OnboardingCategories.all.length ? 'Clear all' : 'Select all',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Two columns on phones, three on tablets.
              final int columns = constraints.maxWidth > 520 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: OnboardingCategories.all.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 78,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final OnboardingCategory category =
                      OnboardingCategories.all[index];
                  return _CategoryTile(
                    category: category,
                    selected: selectedIds.contains(category.id),
                    onTap: () => onToggle(category.id),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          if (count == 0)
            Text(
              context.tr('categoryRequired'),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final OnboardingCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color tint = Color(category.model.color);

    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(tint.withAlpha(34), scheme.surfaceContainerLow)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? tint : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tint.withAlpha(46),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      ICONS.byCodePoint(category.model.icon),
                      size: 18,
                      color: tint,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: selected ? 1 : 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: tint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
