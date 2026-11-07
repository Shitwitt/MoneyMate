import 'package:flutter/material.dart';

import '../../core/constants/icons.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/category_model.dart';

/// A compact "create a category without leaving the entry form" sheet.
///
/// Step 4 ships the full category manager; this is the same data model with the
/// minimum fields needed to finish logging a transaction.
Future<CategoryModel?> showQuickAddCategorySheet(
  BuildContext context, {
  Set<int> existingColors = const <int>{},
}) {
  return showModalBottomSheet<CategoryModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _QuickAddCategorySheet(
      existingColors: existingColors,
    ),
  );
}

class _QuickAddCategorySheet extends StatefulWidget {
  const _QuickAddCategorySheet({required this.existingColors});

  final Set<int> existingColors;

  @override
  State<_QuickAddCategorySheet> createState() => _QuickAddCategorySheetState();
}

class _QuickAddCategorySheetState extends State<_QuickAddCategorySheet> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _iconKey = 'category';
  late int _color = _nextColor();
  bool _withBudget = false;
  double _budget = 0;

  /// Picks the first palette colour that is not already taken, so new
  /// categories stay visually distinct.
  int _nextColor() {
    const List<int> palette = <int>[
      0xFFF4511E,
      0xFFFB8C00,
      0xFF7CB342,
      0xFF43A047,
      0xFF00897B,
      0xFF00ACC1,
      0xFF1E88E5,
      0xFF3949AB,
      0xFF8E24AA,
      0xFFD81B60,
      0xFFE53935,
      0xFF6F7473,
    ];
    for (final int color in palette) {
      if (!widget.existingColors.contains(color)) return color;
    }
    return palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      CategoryModel(
        id: IdGenerator.newId(),
        name: _nameController.text.trim(),
        description: '',
        icon: ICONS.codePointForKey(_iconKey),
        color: _color,
        budget: _withBudget ? _budget : 0,
        isBudgetActive: _withBudget && _budget > 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'New category',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 28,
              decoration: const InputDecoration(
                labelText: 'Category name',
                hintText: 'e.g. Pet care',
                prefixIcon: Icon(Icons.label_outline_rounded),
                counterText: '',
              ),
              validator: (String? value) {
                final String text = (value ?? '').trim();
                if (text.isEmpty) return 'Please name the category';
                if (text.length > 28) return 'Name is too long';
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Icon',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ICONS.categoryIconKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final String key = ICONS.categoryIconKeys[index];
                  final bool selected = key == _iconKey;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _iconKey = key),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(_color).withOpacity(0.2)
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? Color(_color) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        ICONS.byKey(key),
                        size: 20,
                        color: selected ? Color(_color) : scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Colour',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (final int color in <int>[
                  0xFFF4511E,
                  0xFFFB8C00,
                  0xFF7CB342,
                  0xFF43A047,
                  0xFF00897B,
                  0xFF00ACC1,
                  0xFF1E88E5,
                  0xFF3949AB,
                  0xFF8E24AA,
                  0xFFD81B60,
                  0xFFE53935,
                  0xFF6F7473,
                ])
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color == _color
                              ? scheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: color == _color
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _withBudget,
              title: Text(
                'Set a monthly budget',
                style: theme.textTheme.bodyMedium,
              ),
              onChanged: (bool value) => setState(() => _withBudget = value),
            ),
            if (_withBudget)
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                initialValue: _budget == 0 ? '' : _budget.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'Monthly budget',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
                onChanged: (String value) =>
                    setState(() => _budget = double.tryParse(value) ?? 0),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Create category'),
            ),
          ],
        ),
      ),
    );
  }
}
