import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/ledger.dart';
import '../../core/data/local_store.dart';
import '../../core/data/providers.dart';
import '../../core/data/seed.dart';
import '../../core/models/models.dart';
import '../../core/theme/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets.dart';
import '../budgets/budgets_screen.dart';
import '../catalog/catalog_screen.dart';
import '../goals/goals_screen.dart';
import '../home/app_shell.dart';
import '../loans/loans_screen.dart';
import '../recurring/recurring_screen.dart';
import '../settings/appearance_screen.dart';

/// Live Flutter screens share the same components/data path as the actual app.
/// No screenshot assets, OS clocks, status icons, or private chat-head overlays.
class FeaturePhonePreview extends StatefulWidget {
  final String feature;
  const FeaturePhonePreview({super.key, required this.feature});
  @override
  State<FeaturePhonePreview> createState() => _FeaturePhonePreviewState();
}

class _FeaturePhonePreviewState extends State<FeaturePhonePreview> {
  late final _PreviewRepository repository;
  @override
  void initState() {
    super.initState();
    final profile = seedProfile(
      name: 'Demo User',
      currency: 'USD',
      accountName: 'Everyday',
      demo: true,
    );
    repository = _PreviewRepository(
      AppData(
        profiles: [profile],
        activeProfileId: profile.profile.id,
        settings: const AppSettings(theme: 'light', isPro: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(340.0, constraints.maxWidth - 12);
          return ClipRect(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0, .76, 1],
              ).createShader(rect),
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Container(
                    width: width,
                    height: width * 2.05,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffD3BEB7),
                      borderRadius: BorderRadius.circular(42),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(
                          width: 360,
                          height: 740,
                          child: ProviderScope(
                            overrides: [
                              repositoryProvider.overrideWithValue(repository),
                              appProvider.overrideWith(
                                (_) => AppController(repository),
                              ),
                              profileProvider.overrideWith(
                                (ref) => ref.watch(appProvider).profiles.first,
                              ),
                              ledgerProvider.overrideWith(
                                (ref) => Ledger(
                                  ref.watch(profileProvider)!,
                                  ref.watch(appProvider).settings,
                                ),
                              ),
                            ],
                            child: Theme(
                              data: tinkTheme(
                                const AppSettings(theme: 'light'),
                                Brightness.light,
                              ),
                              child: Localizations(
                                locale: const Locale('en'),
                                delegates:
                                    AppLocalizations.localizationsDelegates,
                                child: MediaQuery(
                                  data: const MediaQueryData(
                                    size: Size(360, 740),
                                    textScaler: TextScaler.noScaling,
                                    disableAnimations: true,
                                  ),
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: switch (widget.feature) {
                                      'home' => const AppShell(),
                                      'budgets' => const BudgetsScreen(),
                                      'loans' => const LoansScreen(),
                                      'goals' => const GoalsScreen(),
                                      'recurring' => const RecurringScreen(),
                                      'categories' => const CatalogScreen(
                                        'category',
                                      ),
                                      'appearance' => const AppearanceScreen(),
                                      _ => const _NotificationPreview(),
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _PreviewRepository implements AppRepository {
  @override
  final AppData initial;
  _PreviewRepository(this.initial);
  @override
  Future<void> save(AppData _) async {}
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview();
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xffF6D7AC),
          Color(0xffF7B7B1),
          Color(0xff729DAD),
          Color(0xff234F60),
        ],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 54, 18, 0),
      child: Column(
        children: [
          TonalCard(
            color: const Color(0xddFFF8EE),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TinkLogo(size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example reminder',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Recurring payment',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A scheduled payment is due. Open Tink to review it.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 52),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: 18),
              child: TinkLogo(size: 54),
            ),
          ),
        ],
      ),
    ),
  );
}
