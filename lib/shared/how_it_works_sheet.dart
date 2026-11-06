import 'package:flutter/material.dart';

import 'widgets.dart';

typedef HelpSection = (IconData, String, String);

/// Shared reference sheet: fixed title/close and CTA, independently scrolling
/// explanation, square tinted icons, and a finite bottom fade. No fake OS UI.
Future<void> showHowItWorks(
  BuildContext context, {
  required String title,
  required String introduction,
  required List<HelpSection> sections,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: false,
  useSafeArea: true,
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  builder: (sheet) => SizedBox(
    height: MediaQuery.sizeOf(sheet).height * .91,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(sheet).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close $title',
                onPressed: () => Navigator.pop(sheet),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 42),
                children: [
                  Text(
                    introduction,
                    style: Theme.of(
                      sheet,
                    ).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 28),
                  for (final section in sections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 26),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.dark(sheet)
                                  ? const Color(0xff72361e)
                                  : const Color(0xffffe1d1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              section.$1,
                              size: 24,
                              color: AppColors.dark(sheet)
                                  ? const Color(0xffffddca)
                                  : AppColors.primaryInk,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.$2,
                                  style: Theme.of(sheet).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  section.$3,
                                  style: Theme.of(
                                    sheet,
                                  ).textTheme.bodyLarge?.copyWith(height: 1.55),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 32,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(
                            sheet,
                          ).scaffoldBackgroundColor.withValues(alpha: 0),
                          Theme.of(sheet).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(sheet),
              child: const Text('Got it'),
            ),
          ),
        ),
      ],
    ),
  ),
);
