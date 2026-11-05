import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/ledger.dart';
import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/services/receipt_service.dart';
import '../../core/utils/constants.dart';
import '../../shared/actions.dart';
import '../../shared/charts.dart';
import '../../shared/forms.dart';
import '../../shared/widgets.dart';
import '../transactions/transactions_screen.dart';
import 'categories_screen.dart';

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
    final profile = ref.watch(profileProvider)!;
    if (kind == 'category') {
      return CategoriesScreen(
        onEdit: (initial, type) => _editCategory(context, ref, initial, type),
        onOpen: (category) => openPage(context, _CategoryDetail(category.id)),
      );
    }
    final entities = profile.entities
        .where((item) => item.kind == kind)
        .toList();
    return FeaturePage(
      title: title,
      actions: [
        IconButton(
          tooltip: 'Add $kind',
          onPressed: () => _editEntity(context, ref),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: entities.isEmpty
          ? EmptyState(
              title: 'A little more context',
              message:
                  'Organize your money with $title. Filter any report or activity by them.',
              icon: iconFor(kind),
              action: 'Add $kind',
              onAction: () => _editEntity(context, ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 110),
              itemCount: entities.length,
              itemBuilder: (context, index) {
                final entity = entities[index];
                final entries = _filterFor(entity)
                    .apply(ref.read(ledgerProvider)!);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: entity.photoBase64.isEmpty
                          ? ColorIcon(kind, entity.color)
                          : CircleAvatar(
                              backgroundImage: MemoryImage(
                                base64Decode(entity.photoBase64),
                              ),
                            ),
                      title: Text(entity.name),
                      subtitle: Text(
                        '${entries.length} transactions${entity.notes.isEmpty ? '' : ' · ${entity.notes}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => openPage(
                        context,
                        TransactionsScreen(
                          title: entity.name,
                          initialFilter: _filterFor(entity),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            _editEntity(context, ref, entity);
                          } else if (await confirm(
                                context,
                                'Delete ${entity.name}?',
                                'This removes its tags from transactions, not the transactions themselves.',
                              ) &&
                              context.mounted) {
                            await runSafe(
                              context,
                              () => ref
                                  .read(appProvider.notifier)
                                  .deleteEntity(entity.id),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  TransactionFilter _filterFor(NamedEntity entity) => TransactionFilter(
    labels: kind == 'label' ? {entity.id} : {},
    people: kind == 'person' ? {entity.id} : {},
    places: kind == 'place' ? {entity.id} : {},
  );
  Future<void> _editEntity(
    BuildContext context,
    WidgetRef ref, [
    NamedEntity? initial,
  ]) async {
    final name = TextEditingController(text: initial?.name ?? ''),
        notes = TextEditingController(text: initial?.notes ?? '');
    var color = initial?.color ?? palette[3],
        photo = initial?.photoBase64 ?? '';
    await showEditor(
      context,
      title: initial == null ? 'New $kind' : 'Edit $kind',
      fields: (context, setLocal) => [
        formText(name, 'Name', required: true),
        formText(
          notes,
          kind == 'place' ? 'Address / notes' : 'Notes',
          lines: 3,
        ),
        formColors(color, (value) => setLocal(() => color = value)),
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
  await showEditor(
    context,
    title: initial == null ? 'New category' : 'Edit category',
    fields: (context, setLocal) => [
      formText(name, 'Name', required: true),
      formSelect('Type', type, [
        'expense',
        'income',
        'transfer',
      ], (value) => setLocal(() => type = value)),
      formColors(color, (value) => setLocal(() => color = value)),
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
            hidden: initial?.hidden ?? false,
            order:
                initial?.order ?? ref.read(profileProvider)!.categories.length,
          ),
        ),
  );
  name.dispose();
}

class _CategoryDetail extends ConsumerWidget {
  final String id;
  const _CategoryDetail(this.id);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final category = ledger.category(id);
    if (category == null) return const SizedBox.shrink();
    final entries = ledger.data.transactions
        .where((entry) => entry.categoryId == id)
        .toList();
    return FeaturePage(
      title: category.name,
      actions: [
        IconButton(
          tooltip: 'Edit category',
          onPressed: () => _editCategory(context, ref, category),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      padded: false,
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TrendChart(
                    Ledger(
                      ledger.data.copyWith(transactions: entries),
                      ledger.settings,
                    ),
                    line: true,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TransactionsScreen(
              title: 'Category activity',
              initialFilter: TransactionFilter(categories: {id}),
            ),
          ),
        ],
      ),
    );
  }
}
