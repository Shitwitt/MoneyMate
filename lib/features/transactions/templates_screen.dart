import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import 'transaction_form.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider)!;
    return FeaturePage(
      title: 'Quick templates',
      subtitle: 'Tap to post instantly · hold to edit',
      fab: FloatingActionButton(
        onPressed: () =>
            openPage(context, const TransactionForm(templateOnly: true)),
        tooltip: 'Create template',
        child: const Icon(Icons.add_rounded),
      ),
      child: profile.templates.isEmpty
          ? EmptyState(
              title: 'One tap, one less thing',
              message:
                  'Save your everyday coffee, commute or salary as a template.',
              action: 'Create a template',
              onAction: () =>
                  openPage(context, const TransactionForm(templateOnly: true)),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: profile.templates.length,
              itemBuilder: (context, index) {
                final template = profile.templates[index];
                final category = profile.categories.firstWhere(
                  (item) => item.id == template.categoryId,
                );
                final account = profile.accounts.firstWhere(
                  (item) => item.id == template.accountId,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: ColorIcon(category.icon, category.color),
                      title: Text(template.name),
                      subtitle: AmountText(
                        template.amountMinor,
                        currency: account.currency,
                      ),
                      onTap: () => runSafe(
                        context,
                        () => ref
                            .read(appProvider.notifier)
                            .applyTemplate(template),
                        success: '${template.name} added',
                      ),
                      onLongPress: () => openPage(
                        context,
                        TransactionForm(templateOnly: true, template: template),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            openPage(
                              context,
                              TransactionForm(
                                templateOnly: true,
                                template: template,
                              ),
                            );
                          } else if (await confirm(
                                context,
                                'Delete template?',
                                'Your existing transactions are not changed.',
                              ) &&
                              context.mounted) {
                            await runSafe(
                              context,
                              () => ref
                                  .read(appProvider.notifier)
                                  .deleteTemplate(template.id),
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
}
