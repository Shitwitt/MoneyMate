import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/deep_link_service.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';

class PageShortcutsScreen extends StatelessWidget {
  const PageShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context) => FeaturePage(
    title: 'Page shortcuts',
    child: ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const SectionHeader('One link. Your place in Tink.'),
        const Text(
          'Copy a link for a device shortcut or automation. These links only open a local page; they never create a transaction. An existing profile and app unlock are still required. They do not claim Paisa’s website or its universal links.',
        ),
        const SizedBox(height: 16),
        for (final entry in DeepLinkService.pages.entries)
          Card(
            child: ListTile(
              title: Text(entry.value),
              subtitle: Text(DeepLinkService.pageUri(entry.key).toString()),
              trailing: IconButton(
                tooltip: 'Copy ${entry.value} shortcut',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => runSafe(context, () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: DeepLinkService.pageUri(entry.key).toString(),
                    ),
                  );
                }, success: '${entry.value} link copied'),
              ),
            ),
          ),
      ],
    ),
  );
}
