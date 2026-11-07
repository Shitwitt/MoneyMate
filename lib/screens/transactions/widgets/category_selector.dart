import 'package:flutter/material.dart';

import '../../../core/constants/icons.dart';
import '../../../core/theme/paisa_colors.dart';
import '../../../data/models/category_model.dart';

/// The category grid: a wrap of icon + label chips plus a trailing
/// `+ Add category` chip.
class CategorySelectorGrid extends StatelessWidget {
  const CategorySelectorGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onAddCategory,
    this.errorText,
  });

  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddCategory;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.category_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Category',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final CategoryModel category in categories)
              _CategoryChip(
                category: category,
                selected: category.id == selectedId,
                onTap: () => onSelect(category.id),
              ),
            _AddCategoryChip(onTap: onAddCategory),
          ],
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color tint = Color(category.color);

    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(tint.withAlpha(40), scheme.surfaceContainerLow)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? tint : scheme.outlineVariant,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                ICONS.byCodePoint(category.icon),
                size: 16,
                color: tint,
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategoryChip extends StatelessWidget {
  const _AddCategoryChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PaisaColors colors = PaisaColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.transfer.withAlpha(120)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.add_rounded, size: 16, color: colors.transfer),
            const SizedBox(width: 6),
            Text(
              'Add category',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.transfer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
