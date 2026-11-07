import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/currencies.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../domain/default_data.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/error_view.dart';
import 'onboarding_state.dart';
import 'pages/accounts_page.dart';
import 'pages/categories_page.dart';
import 'pages/currency_page.dart';
import 'pages/profile_page.dart';
import 'pages/welcome_page.dart';

/// The five-step first-launch intro flow.
///
/// The flow keeps a single [OnboardingState] draft in memory — nothing touches
/// Hive until "Open MoneyMate" on page 5, so backing out of onboarding (or
/// killing the app mid-flow) leaves a clean database.
///
/// Navigation is an [AnimatedSwitcher] driven by [_step] rather than a
/// `PageView`, so each page owns its own layout (page 1 is full-bleed with the
/// lava lamp, pages 3–5 share `OnboardingScaffold`) without fighting a parent's
/// scroll physics.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.onCompleted,
    this.initialLanguageCode = 'en',
  });

  /// Invoked once the profile, accounts, categories and currency are persisted.
  ///
  /// `main.dart` uses this to swap in the app shell; it is optional so the flow
  /// can be launched standalone (deep link, widget test).
  final VoidCallback? onCompleted;

  final String initialLanguageCode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _totalSteps = 5;

  int _step = 1;
  bool _saving = false;
  String? _saveError;

  late OnboardingState _draft = OnboardingState(
    languageCode: widget.initialLanguageCode,
    selectedCategoryIds: OnboardingCategories.defaultSelected,
  );

  PaisaProvider get _provider => context.read<PaisaProvider>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The draft starts on the device language when one of the five is active.
    if (_step == 1 && _draft.languageCode == widget.initialLanguageCode) {
      final Locale locale = Localizations.localeOf(context);
      final bool supported =
          AppLanguage.all.any((AppLanguage l) => l.code == locale.languageCode);
      if (supported && locale.languageCode != _draft.languageCode) {
        _draft = _draft.copyWith(languageCode: locale.languageCode);
      }
    }
  }

  void _goTo(int step) {
    final int clamped = step.clamp(1, _totalSteps);
    if (clamped == _step) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _step = clamped;
      _saveError = null;
    });
  }

  void _next() => _goTo(_step + 1);

  void _back() => _goTo(_step - 1);

  Future<void> _persist({
    required String name,
    required int avatarIndex,
    String? customImagePath,
    required List<AccountModel> accounts,
    required List<CategoryModel> categories,
    required bool incomeTracking,
  }) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await _provider.completeOnboarding(
        name: name,
        avatarIndex: avatarIndex,
        customImagePath: customImagePath,
        languageCode: _draft.languageCode,
        currencyCode: _draft.currencyCode,
        selectedAccounts: accounts,
        selectedCategories: categories,
        incomeTracking: incomeTracking,
      );
      if (!mounted) return;
      widget.onCompleted?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = error.toString();
      });
    }
  }

  /// "Skip" — seeds a clean, usable starting point instead of an empty app:
  /// the default Cash Wallet plus every seeded category.
  Future<void> _skipEverything() {
    return _persist(
      name: '',
      avatarIndex: 0,
      accounts: <AccountModel>[DefaultData.cashAccount.toModel()],
      categories: DefaultData.categories,
      incomeTracking: true,
    );
  }

  Future<void> _finish() {
    return _persist(
      name: _draft.trimmedName,
      avatarIndex: _draft.avatarIndex,
      customImagePath: _draft.customImagePath,
      accounts: <AccountModel>[_draft.buildAccount()],
      categories: _draft.buildCategories(),
      incomeTracking: _draft.selectedCategoryIds.contains('seed-category-salary'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TranslationScope(
      languageCode: _draft.languageCode,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final Animation<Offset> offset = Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    if (_saveError != null) {
      return ErrorView(
        key: const ValueKey<String>('onboarding-error'),
        title: 'Could not finish setup',
        message: _saveError!,
        onRetry: _finish,
        secondaryLabel: 'Start over',
        onSecondary: () {
          setState(() {
            _saveError = null;
            _step = 1;
          });
        },
      );
    }

    switch (_step) {
      case 1:
        return WelcomePage(
          key: const ValueKey<int>(1),
          languageCode: _draft.languageCode,
          onLanguageChanged: (String code) {
            setState(() => _draft = _draft.copyWith(languageCode: code));
          },
          onContinue: _next,
          onSkip: _skipEverything,
        );
      case 2:
        return ProfilePage(
          key: const ValueKey<int>(2),
          initialName: _draft.name,
          avatarIndex: _draft.avatarIndex,
          customImagePath: _draft.customImagePath,
          onChanged: ({String? name, int? avatarIndex}) {
            setState(() {
              _draft = _draft.copyWith(name: name, avatarIndex: avatarIndex);
            });
          },
          onPickImage: () async {
            final String? path = await pickAndPersistAvatar();
            if (path == null) return null;
            if (!mounted) return null;
            setState(() => _draft = _draft.copyWith(customImagePath: path));
            return path;
          },
          onRemoveImage: () {
            setState(
              () => _draft = _draft.copyWith(clearCustomImagePath: true),
            );
          },
          onContinue: _next,
          onBack: _back,
        );
      case 3:
        return AccountsPage(
          key: const ValueKey<int>(3),
          selectedPreset: _draft.selectedAccountType,
          currencyCode: _draft.currencyCode,
          balanceFor: _draft.balanceFor,
          onSelect: (AccountPreset preset) {
            setState(
              () => _draft = _draft.copyWith(selectedAccountType: preset),
            );
          },
          onEditBalance: (AccountPreset preset) async {
            final double? amount = await showOpeningBalanceDialog(
              context,
              title: preset.defaultTitle,
              currencySymbol: CurrencyTable.byCode(_draft.currencyCode).symbol,
              currencyCode: _draft.currencyCode,
              initialValue: _draft.balanceFor(preset),
            );
            if (amount == null || !mounted) return;
            setState(() => _draft = _draft.withBalance(preset, amount));
          },
          onContinue: _next,
          onBack: _back,
          onSkip: _finish,
        );
      case 4:
        return CategoriesPage(
          key: const ValueKey<int>(4),
          selectedIds: _draft.selectedCategoryIds,
          onToggle: (String id) {
            setState(() => _draft = _draft.toggleCategory(id));
          },
          onSelectAll: () {
            setState(() {
              _draft = _draft.copyWith(
                selectedCategoryIds: <String>{
                  for (final OnboardingCategory category
                      in OnboardingCategories.all)
                    category.id,
                },
              );
            });
          },
          onClearAll: () {
            setState(
              () => _draft = _draft.copyWith(selectedCategoryIds: <String>{}),
            );
          },
          onContinue: _next,
          onBack: _back,
          onSkip: _finish,
        );
      case 5:
      default:
        return CurrencyPage(
          key: const ValueKey<int>(5),
          selectedCode: _draft.currencyCode,
          finishing: _saving,
          onSelect: (String code) {
            setState(() => _draft = _draft.copyWith(currencyCode: code));
          },
          onFinish: _finish,
          onBack: _back,
          onSkip: _finish,
        );
    }
  }
}
