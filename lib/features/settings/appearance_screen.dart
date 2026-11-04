import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/providers.dart';
import '../../core/utils/constants.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import 'premium_screen.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appProvider).settings;
    final controller = ref.read(appProvider.notifier);
    return FeaturePage(
      title: 'Make it feel like you',
      child: ListView(
        children: [
          const SectionHeader('Your kind of light'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final mode in ['system', 'light', 'dark', 'black'])
                SizedBox(
                  width: 145,
                  child: Card(
                    color: settings.theme == mode
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (mode == 'black' && !settings.isPro) {
                          openPage(context, const PremiumScreen());
                          return;
                        }
                        runSafe(
                          context,
                          () => controller.settings(
                            (s) => s.copyWith(theme: mode),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(switch (mode) {
                              'system' => Icons.brightness_auto_rounded,
                              'light' => Icons.light_mode_outlined,
                              'dark' => Icons.dark_mode_outlined,
                              _ => Icons.circle,
                            }, size: 30),
                            const SizedBox(height: 14),
                            Text(
                              mode == 'black'
                                  ? 'Just Black · Plus'
                                  : '${mode[0].toUpperCase()}${mode.substring(1)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Material You'),
              subtitle: const Text(
                'Use wallpaper colors on Android 12+; your accent is the fallback.',
              ),
              value: settings.dynamicColors,
              onChanged: (value) => runSafe(
                context,
                () => controller.settings(
                  (s) => s.copyWith(dynamicColors: value),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('A little color'),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (var i = 0; i < palette.length; i++)
                Semantics(
                  label: 'Accent ${i + 1}${i > 4 ? ', Plus' : ''}',
                  button: true,
                  selected: settings.accent == palette[i],
                  child: InkResponse(
                    onTap: () {
                      if (i > 4 && !settings.isPro) {
                        openPage(context, const PremiumScreen());
                      } else {
                        runSafe(
                          context,
                          () => controller.settings(
                            (s) => s.copyWith(
                              accent: palette[i],
                              dynamicColors: false,
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 27,
                      backgroundColor: Color(palette[i]),
                      child: settings.accent == palette[i]
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xff26351c),
                            )
                          : i > 4 && !settings.isPro
                          ? const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xff26351c),
                              size: 17,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),
          const SectionHeader('Easy on the eyes'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Text size · ${(settings.fontScale * 100).round()}%'),
                  Slider(
                    value: settings.fontScale,
                    min: .8,
                    max: 1.6,
                    divisions: 8,
                    onChanged: (value) => runSafe(
                      context,
                      () => controller.settings(
                        (s) => s.copyWith(fontScale: value),
                      ),
                    ),
                  ),
                  const Text(
                    'A little intention goes a long way.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
