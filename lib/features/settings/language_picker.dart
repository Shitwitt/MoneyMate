import 'package:flutter/material.dart';

import '../../core/utils/constants.dart';
import '../../shared/actions.dart';

Future<void> showLanguagePicker(
  BuildContext context,
  String selected,
  Future<void> Function(String) onSelected,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) =>
      _LanguagePicker(selected: selected, onSelected: onSelected),
);

class _LanguagePicker extends StatefulWidget {
  final String selected;
  final Future<void> Function(String) onSelected;
  const _LanguagePicker({required this.selected, required this.onSelected});
  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  final query = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = languageNames.entries
        .where(
          (e) => '${e.key} ${e.value}'.toLowerCase().contains(
            query.text.toLowerCase(),
          ),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .82,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose language',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close language picker',
                  onPressed: busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search language or code',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final entry = options[index];
                  return ListTile(
                    title: Text(entry.value),
                    subtitle: Text(entry.key.toUpperCase()),
                    trailing: entry.key == widget.selected
                        ? const Icon(Icons.check_circle_outline_rounded)
                        : null,
                    enabled: !busy,
                    onTap: () async {
                      setState(() => busy = true);
                      final route = ModalRoute.of(context),
                          navigator = Navigator.of(context);
                      try {
                        await widget.onSelected(entry.key);
                        if (route != null && route.isActive) {
                          if (route.isCurrent) {
                            navigator.pop();
                          } else {
                            navigator.removeRoute(route);
                          }
                        }
                      } catch (error) {
                        if (mounted)
                          toast(context, error.toString(), error: true);
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Core navigation and actions are translated. Detailed finance forms and explanations currently use English.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
