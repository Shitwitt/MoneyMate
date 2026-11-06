import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/services/receipt_service.dart';
import '../../core/utils/constants.dart';
import '../../shared/actions.dart';
import '../../shared/forms.dart';
import '../../shared/reference_editor.dart';
import '../../shared/widgets.dart';
import 'categories_screen.dart';
import 'labels_screen.dart';
import 'context_screen.dart';
import 'category_detail_screen.dart';

export 'category_detail_screen.dart' show CategoryDetailScreen;

class CatalogScreen extends ConsumerWidget {
  final String kind;
  const CatalogScreen(this.kind, {super.key});
  String get title => switch (kind) {
    'category' => 'Categories',
    'person' => 'People',
    'place' => 'Places',
    _ => 'Labels',
  };
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kind == 'label') return const LabelsScreen();
    if (kind == 'category')
      return CategoriesScreen(
        onEdit: (initial, type) => _editCategory(context, ref, initial, type),
        onOpen: (c) => openPage(context, CategoryDetailScreen(c.id)),
      );
    return ContextScreen(kind);
  }

  Future<void> _editEntity(
    BuildContext context,
    WidgetRef ref, [
    NamedEntity? initial,
  ]) async {
    final name = TextEditingController(text: initial?.name ?? ''),
        notes = TextEditingController(text: initial?.notes ?? '');
    var icon = initial?.icon.isNotEmpty == true ? initial!.icon : kind;
    var color = initial?.color ?? palette[3],
        photo = initial?.photoBase64 ?? '';
    await showReferenceEditor(
      context,
      title: initial == null ? 'New $kind' : 'Edit $kind',
      saveLabel: initial == null ? 'Create $kind' : 'Update $kind',
      fields: (context, setLocal) => [
        formText(name, 'Name', required: true),
        formText(
          notes,
          kind == 'place' ? 'Address / notes' : 'Notes',
          lines: 3,
        ),
        ReferenceColorPicker(
          value: color,
          onChanged: (value) => setLocal(() => color = value),
        ),
        ExpansionTile(
          title: const Text('Choose an icon'),
          children: [formIcons(icon, (value) => setLocal(() => icon = value))],
        ),
        if (kind == 'person')
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => runSafe(context, () async {
                  final receipt = await ReceiptService.pick(
                    ImageSource.gallery,
                  );
                  if (receipt != null) setLocal(() => photo = receipt.data);
                }),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(photo.isEmpty ? 'Add photo' : 'Change photo'),
              ),
              if (photo.isNotEmpty)
                IconButton(
                  tooltip: 'Remove photo',
                  onPressed: () => setLocal(() => photo = ''),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
      ],
      onSave: () => ref
          .read(appProvider.notifier)
          .upsertEntity(
            NamedEntity(
              id: initial?.id ?? uuid.v4(),
              name: name.text.trim(),
              kind: kind,
              icon: icon,
              color: color,
              notes: notes.text.trim(),
              photoBase64: photo,
            ),
          ),
    );
    name.dispose();
    notes.dispose();
  }
}

Future<void> _editCategory(
  BuildContext context,
  WidgetRef ref, [
  Category? initial,
  String initialType = 'expense',
]) async {
  final name = TextEditingController(text: initial?.name ?? '');
  var type = initial?.type ?? initialType, icon = initial?.icon ?? 'category';
  var color = initial?.color ?? palette.first;
  var parentId = initial?.parentId ?? '';
  bool canParent(Category candidate) {
    var id = candidate.id;
    final visited = <String>{};
    final categories = ref.read(profileProvider)!.categories;
    while (id.isNotEmpty && visited.add(id)) {
      if (id == initial?.id) return false;
      id = categories.where((c) => c.id == id).firstOrNull?.parentId ?? '';
    }
    return true;
  }

  await showEditor(
    context,
    title: initial == null ? 'New category' : 'Edit category',
    fields: (context, setLocal) => [
      formText(name, 'Name', required: true),
      formSelect(
        'Type',
        type,
        ['expense', 'income', 'transfer'],
        (value) => setLocal(() {
          type = value;
          parentId = '';
        }),
      ),
      DropdownButtonFormField<String>(
        key: ValueKey('category-parent-$type'),
        isExpanded: true,
        initialValue: parentId,
        decoration: const InputDecoration(labelText: 'Parent category'),
        items: [
          const DropdownMenuItem(value: '', child: Text('None · top-level')),
          for (final category
              in ref
                  .read(profileProvider)!
                  .categories
                  .where((c) => c.type == type && canParent(c)))
            DropdownMenuItem(value: category.id, child: Text(category.name)),
        ],
        onChanged: (value) => setLocal(() => parentId = value ?? ''),
      ),
      const SizedBox(height: 16),
      ReferenceColorPicker(
        value: color,
        onChanged: (value) => setLocal(() => color = value),
      ),
      formIcons(icon, (value) => setLocal(() => icon = value)),
    ],
    onSave: () => ref
        .read(appProvider.notifier)
        .upsertCategory(
          Category(
            id: initial?.id ?? uuid.v4(),
            name: name.text.trim(),
            type: type,
            icon: icon,
            color: color,
            parentId: parentId,
            hidden: initial?.hidden ?? false,
            order:
                initial?.order ?? ref.read(profileProvider)!.categories.length,
          ),
        ),
  );
  name.dispose();
}

Future<void> editCatalogEntity(
  BuildContext context,
  WidgetRef ref,
  String kind, [
  NamedEntity? initial,
]) => CatalogScreen(kind)._editEntity(context, ref, initial);
Future<void> editCatalogCategory(
  BuildContext context,
  WidgetRef ref, [
  Category? initial,
  String type = 'expense',
]) => _editCategory(context, ref, initial, type);
