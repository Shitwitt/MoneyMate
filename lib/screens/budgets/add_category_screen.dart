import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/icons.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/category_model.dart';
import '../../providers/paisa_provider.dart';

/// Creates or edits a category, its icon, its colour and its monthly budget.
///
/// The icon picker is a fixed 36-icon grid (see [CategoryIconGrid.keys]) rather
/// than the full registry, because a wall of 48 icons is harder to scan than a
/// tight grid of the ones people actually use. Every key resolves through the
/// `ICONS` registry so the release icon tree-shaker keeps them.
class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key, this.existing, this.initialName});

  /// The category being edited, or `null` when creating.
  final CategoryModel? existing;

  /// Pre-fills the name (used by "add a category" from the entry form).
  final String? initialName;

  bool get isEditing => existing != null;

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _budget = TextEditingController();

  late String _iconKey;
  late int _color;
  bool _budgetEnabled = false;
  bool _saving = false;

  PaisaProvider get _provider => context.read<PaisaProvider>();

  @override
  void initState() {
    super.initState();
    final CategoryModel? existing = widget.existing;
    final PaisaProvider provider = context.read<PaisaProvider>();

    _iconKey = ICONS.keyForCodePoint(existing?.icon) ?? CategoryIconGrid.keys.first;
    _color = existing?.color ?? _nextColor(provider);
    _budgetEnabled = existing?.isBudgetActive ?? false;

    if (existing != null) {
      _name.text = existing.name;
      _description.text = existing.description;
      if (existing.budget > 0) {
        _budget.text = provider.formatter.forInput(existing.budget);
      }
    } else if (widget.initialName != null) {
      _name.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _budget.dispose();
    super.dispose();
  }

  /// Picks the first palette colour no other category is using, so the list
  /// stays visually distinguishable without any extra decision from the user.
  static int _nextColor(PaisaProvider provider) {
    final Set<int> taken = <int>{
      for (final CategoryModel category in provider.categories) category.color,
    };
    for (final int color in CategoryIconGrid.palette) {
      if (!taken.contains(color)) return color;
    }
    return CategoryIconGrid.palette.first;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final PaisaProvider provider = _provider;
    final double budget =
        _budgetEnabled ? (provider.formatter.parse(_budget.text.trim()) ?? 0) : 0;

    final CategoryModel category = CategoryModel(
      id: widget.existing?.id ?? IdGenerator.newId(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      icon: ICONS.codePointForKey(_iconKey),
      color: _color,
      budget: budget,
      // Income categories never carry a budget.
      isBudgetActive: _budgetEnabled && budget > 0,
      isDefault: widget.existing?.isDefault ?? false,
    );

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        await provider.updateCategory(category);
      } else {
        await provider.addCategory(category);
      }
      if (!mounted) return;
      Navigator.of(context).pop(category);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the category: $error')),
      );
    }
  }

  Future<void> _delete() async {
    final CategoryModel? existing = widget.existing;
    if (existing == null) return;
    final PaisaProvider provider = _provider;
    final int inUse = provider.transactions
        .where((transaction) => transaction.categoryId == existing.id)
        .length;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Delete ${existing.name}?'),
        content: Text(
          inUse == 0
              ? 'No transactions use this category yet.'
              : '$inUse transaction${inUse == 1 ? '' : 's'} keep their history and '
                  'show as Uncategorised. The budget, if any, is removed.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    await provider.deleteCategory(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop(existing);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final CurrencyFormatter formatter = context.watch<PaisaProvider>().formatter;
    final bool isIncome = widget.existing?.isIncome ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit category' : 'New category'),
        actions: <Widget>[
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete category',
              onPressed: _saving ? null : _delete,
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: <Widget>[
            // ---------------- Live preview ----------------
            Row(
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(_color).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Color(_color).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    ICONS.byKey(_iconKey),
                    size: 30,
                    color: Color(_color),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _name.text.trim().isEmpty
                            ? 'Category name'
                            : _name.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _budgetEnabled && _budget.text.trim().isNotEmpty
                            ? '${formatter.formatWhole(formatter.parse(_budget.text) ?? 0)} monthly budget'
                            : 'No monthly budget',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ---------------- Name & description ----------------
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 32,
              onChanged: (_) => setState(() {}),
              validator: (String? value) => (value ?? '').trim().isEmpty
                  ? 'Give the category a name'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Category name',
                hintText: 'e.g. Groceries',
                prefixIcon: Icon(Icons.label_outline_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Weekly vegetables and staples',
                prefixIcon: Icon(Icons.notes_rounded),
                counterText: '',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- Icon picker ----------------
            const _SectionLabel(label: 'Icon'),
            const SizedBox(height: 10),
            CategoryIconGrid(
              selectedKey: _iconKey,
              color: Color(_color),
              onSelected: (String key) => setState(() => _iconKey = key),
            ),
            const SizedBox(height: 20),

            // ---------------- Colour picker ----------------
            const _SectionLabel(label: 'Colour'),
            const SizedBox(height: 10),
            ColorPalettePicker(
              selected: _color,
              onSelected: (int color) => setState(() => _color = color),
            ),
            const SizedBox(height: 20),

            // ---------------- Budget ----------------
            if (!isIncome) ...<Widget>[
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: <Widget>[
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      value: _budgetEnabled,
                      onChanged: (bool value) =>
                          setState(() => _budgetEnabled = value),
                      title: const Text('Set Monthly Budget'),
                      subtitle: const Text(
                        'Warn me and show a progress bar for this category',
                      ),
                      secondary: Icon(
                        Icons.track_changes_rounded,
                        color: _budgetEnabled ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: _budgetEnabled
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              child: TextFormField(
                                controller: _budget,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                validator: (String? value) {
                                  if (!_budgetEnabled) return null;
                                  final String raw = (value ?? '').trim();
                                  if (raw.isEmpty) return 'Enter the budget amount';
                                  final double? parsed = formatter.parse(raw);
                                  if (parsed == null || parsed <= 0) {
                                    return 'Enter a valid amount';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Monthly limit',
                                  prefixText: '${formatter.symbol} ',
                                  helperText:
                                      'Resets on the 1st of every month',
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 4),
                    ),
                  ],
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.savings_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Income categories never carry a budget — budgets track '
                        'spending.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    widget.isEditing ? 'Save changes' : 'Add category',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Opens the category editor (create when [existing] is null).
Future<CategoryModel?> openAddCategoryScreen(
  BuildContext context, {
  CategoryModel? existing,
  String? initialName,
}) {
  return Navigator.of(context).push<CategoryModel>(
    MaterialPageRoute<CategoryModel>(
      builder: (BuildContext context) => AddCategoryScreen(
        existing: existing,
        initialName: initialName,
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The 36-icon picker grid and its colour palette.
class CategoryIconGrid extends StatelessWidget {
  const CategoryIconGrid({
    super.key,
    required this.selectedKey,
    required this.onSelected,
    required this.color,
  });

  final String selectedKey;
  final Color color;
  final ValueChanged<String> onSelected;

  /// Exactly 36 icons: food, travel, rent, fuel, medical, shopping, EMI and the
  /// everyday extras people actually budget for.
  static const List<String> keys = <String>[
    'restaurant',
    'fastfood',
    'coffee',
    'grocery',
    'cart',
    'bag',
    'dress',
    'car',
    'bike',
    'bus',
    'train',
    'flight',
    'fuel',
    'taxi',
    'home',
    'apartment',
    'bolt',
    'water',
    'gas',
    'wifi',
    'receipt',
    'heart',
    'hospital',
    'medicine',
    'gym',
    'school',
    'book',
    'movie',
    'music',
    'game',
    'sports',
    'travel',
    'gift',
    'pets',
    'investment',
    'insurance',
  ];

  /// Twelve vibrant ARGB colours for the palette picker.
  static const List<int> palette = <int>[
    0xFFF4511E,
    0xFFFB8C00,
    0xFFFDD835,
    0xFF7CB342,
    0xFF43A047,
    0xFF00897B,
    0xFF00ACC1,
    0xFF1E88E5,
    0xFF3949AB,
    0xFF8E24AA,
    0xFFD81B60,
    0xFFE53935,
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (BuildContext context, int index) {
        final String key = keys[index];
        final bool selected = key == selectedKey;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelected(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.20)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.8,
              ),
            ),
            child: Icon(
              ICONS.byKey(key),
              size: 21,
              color: selected ? color : scheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

/// The colour swatch row used by the category editor.
class ColorPalettePicker extends StatelessWidget {
  const ColorPalettePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.colors = CategoryIconGrid.palette,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final List<int> colors;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (final int value in colors)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(value),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(value),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: value == selected ? scheme.onSurface : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: value == selected
                  ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}
