import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/widgets.dart';
import 'tink_illustration.dart';

const introductionPages = [
  (
    'Your money.\nA clearer mind.',
    'A little clarity goes a long way. Make room for what matters with Tink.',
    'A fresh perspective',
  ),
  (
    'Every rupee,\nin the picture.',
    'From your morning chai to the monthly bills. Keep the little things, and the big picture, together.',
    'Know where it goes',
  ),
  (
    'Spend with\na little certainty.',
    'See what is available after your upcoming outgoings. A thoughtful estimate, not a promise.',
    'Your everyday, considered',
  ),
  (
    'One home for\nall your accounts.',
    'Cash, cards, savings. Track them in one calm place, in the currencies you use.',
    'Less switching. More clarity.',
  ),
  (
    'Small steps.\nBigger possibilities.',
    'Give your goals a little momentum. Build budgets and celebrate progress along the way.',
    'Make space for your future',
  ),
  (
    'Private,\nby design.',
    'No sign-up. No server. Your records stay on your device, with backups only when you choose.',
    'Your money. Your device.',
  ),
];

class IntroductionScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback? onRestore;
  const IntroductionScreen({super.key, required this.onFinish, this.onRestore});
  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final controller = PageController();
  int current = 0;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void next() {
    if (current == 5) {
      widget.onFinish();
      return;
    }
    controller.nextPage(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark(context) || current == 5;
    final foreground = dark ? Colors.white : AppColors.ink;
    final secondary = dark ? AppColors.darkSecondary : AppColors.secondary;
    final background = dark
        ? AppColors.darkSurface
        : current == 1
        ? const Color(0xffF0F6FD)
        : AppColors.background;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: background,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                      child: Row(
                        children: [
                          const TinkLogo(size: 38),
                          const SizedBox(width: 10),
                          Text(
                            'Tink',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: foreground,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: widget.onFinish,
                            style: TextButton.styleFrom(
                              foregroundColor: secondary,
                            ),
                            child: const Text('Skip'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        itemCount: 6,
                        onPageChanged: (page) => setState(() => current = page),
                        itemBuilder: (context, index) {
                          final content = introductionPages[index];
                          final pageDark =
                              AppColors.dark(context) || index == 5;
                          return Semantics(
                            label: 'Introduction, page ${index + 1} of 6',
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                12,
                                24,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height:
                                        (MediaQuery.sizeOf(context).height *
                                                .37)
                                            .clamp(190.0, 310.0),
                                    width: double.infinity,
                                    child: TinkIllustration(index),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    content.$3.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: pageDark
                                              ? AppColors.darkAccent
                                              : AppColors.primaryInk,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    content.$1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          color: pageDark
                                              ? Colors.white
                                              : AppColors.ink,
                                          fontSize: 34,
                                          height: 1.18,
                                          letterSpacing: -1.15,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    content.$2,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: pageDark
                                              ? AppColors.darkSecondary
                                              : AppColors.secondary,
                                          height: 1.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            label: 'Page ${current + 1} of 6',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < 6; i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      height: 6,
                                      width: current == i ? 24 : 6,
                                      decoration: BoxDecoration(
                                        color: current == i
                                            ? AppColors.primary
                                            : (dark
                                                  ? AppColors.darkDivider
                                                  : const Color(0xffDAD7E4)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: current == 5 ? 'Get started' : 'Continue',
                            onPressed: next,
                          ),
                          if (widget.onRestore != null)
                            TextButton(
                              onPressed: widget.onRestore,
                              style: TextButton.styleFrom(
                                foregroundColor: secondary,
                              ),
                              child: const Text(
                                'Already have a backup? Restore it',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
