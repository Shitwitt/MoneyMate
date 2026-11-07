import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/icons.dart';
import 'core/theme/paisa_colors.dart';
import 'core/theme/paisa_theme.dart';
import 'core/theme/seed_color.dart';
import 'core/theme/theme_preference.dart';
import 'core/utils/money_format.dart';
import 'data/local/hive_storage.dart';
import 'data/models/account_model.dart';
import 'data/models/category_model.dart';
import 'data/models/settings_model.dart';
import 'features/settings/appearance/appearance_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final HiveStorage storage = HiveStorage.instance;
  await storage.init();

  final SettingsModel settings = storage.loadSettings();

  runApp(MoneyMateApp(storage: storage, settings: settings));
}

/// Root widget.
///
/// Step 1 wires up the storage + theme engine. The router, onboarding flow and
/// feature screens arrive in steps 2–6; [StepOneHome] is the integration
/// harness that proves the design system, the model layer and the Hive CRUD are
/// all working end-to-end on a real device.
class MoneyMateApp extends StatelessWidget {
  const MoneyMateApp({
    super.key,
    required this.storage,
    required this.settings,
  });

  final HiveStorage storage;
  final SettingsModel settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HiveStorage>.value(value: storage),
        ChangeNotifierProvider<AppearanceController>(
          create: (_) => AppearanceController(
            storage: storage,
            initialSettings: settings,
          ),
        ),
      ],
      child: Consumer<AppearanceController>(
        builder: (BuildContext context, AppearanceController appearance, _) {
          return PaisaThemeBuilder(
            settings: appearance.themeSettings,
            builder: (BuildContext context, ThemeData light, ThemeData dark) {
              return MaterialApp(
                title: 'MoneyMate',
                debugShowCheckedModeBanner: false,
                theme: light,
                darkTheme: dark,
                themeMode: appearance.settings.themePreference.materialThemeMode,
                home: StepOneHome(appearance: appearance),
              );
            },
          );
        },
      ),
    );
  }
}

/// A minimal, package-dependency-free proving ground for step 1.
///
/// It exercises:
///  * all four theme modes (including AMOLED) and the twelve-seed palette,
///  * every default category with its persisted icon code point,
///  * Hive seeding, account balance derivation and setting persistence.
class StepOneHome extends StatefulWidget {
  const StepOneHome({super.key, required this.appearance});

  final AppearanceController appearance;

  @override
  State<StepOneHome> createState() => _StepOneHomeState();
}

class _StepOneHomeState extends State<StepOneHome> {
  HiveStorage get _storage => context.read<HiveStorage>();

  SeedResult? _seedResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedIfNeeded());
  }

  Future<void> _seedIfNeeded() async {
    final SeedResult result = await _storage.seedDefaults(
      includeIncomeCategories:
          context.read<AppearanceController>().settings.incomeTrackingEnabled,
    );
    if (!mounted) return;
    setState(() => _seedResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PaisaColors colors = PaisaColors.of(context);
    final List<AccountModel> accounts = _storage.getAccounts();
    final List<CategoryModel> categories = _storage.getCategories();
    final Map<String, double> balances = _storage.getAccountBalances();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyMate'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Theme mode',
            icon: Icon(widget.appearance.preference.icon),
            onPressed: _cycleTheme,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Text('Step 1 · Design system & storage', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            _seedResult == null
                ? 'Seeding…'
                : 'Seeded ${_seedResult!.accountsSeeded} accounts, '
                    '${_seedResult!.categoriesSeeded} categories, '
                    '${_seedResult!.incomeCategoriesSeeded} income categories',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // ---------------- Accounts ----------------
          Text('Accounts', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                for (final AccountModel account in accounts)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(account.color).withAlpha(38),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(account.color),
                      ),
                    ),
                    title: Text(account.title),
                    subtitle: Text(account.maskedNumber),
                    trailing: Text(
                      MoneyFormat.amount(
                        balances[account.id] ?? account.initialAmount,
                      ),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                if (accounts.isEmpty)
                  const ListTile(title: Text('No accounts yet')),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------------- Categories ----------------
          Text('Categories', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final CategoryModel category in categories)
                Chip(
                  avatar: Icon(
                    ICONS.byCodePoint(category.icon),
                    size: 18,
                    color: Color(category.color),
                  ),
                  label: Text(category.name),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------------- Theme engine ----------------
          Text('Theme engine', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: const Text('Mode'),
                  subtitle: Text(widget.appearance.preference.description),
                  trailing: Text(widget.appearance.preference.label),
                  onTap: _cycleTheme,
                ),
                SwitchListTile(
                  title: const Text('Dynamic colour'),
                  subtitle: const Text('Android 12+ wallpaper colours'),
                  value: widget.appearance.useDynamicColor,
                  onChanged: widget.appearance.setUseDynamicColor,
                ),
                ListTile(
                  title: const Text('Seed colour'),
                  subtitle: Text(widget.appearance.seed.name),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- Seed colour palette ----------------
          Text('Seed colour', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  for (final SeedColor seed in SeedColor.palette)
                    _SeedDot(
                      seed: seed,
                      selected: widget.appearance.seed == seed,
                      onTap: () => widget.appearance.setSeed(seed),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---------------- Tonal surface swatches ----------------
          Text('Tonal surfaces', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Swatch(color: theme.colorScheme.surfaceContainerLow, label: 'Low'),
              _Swatch(color: theme.colorScheme.surfaceContainer, label: 'Base'),
              _Swatch(
                color: theme.colorScheme.surfaceContainerHighest,
                label: 'Highest',
              ),
              _Swatch(
                color: theme.colorScheme.primaryContainer,
                label: 'Primary',
              ),
              _Swatch(
                color: theme.colorScheme.secondaryContainer,
                label: 'Secondary',
              ),
              _Swatch(
                color: theme.colorScheme.tertiaryContainer,
                label: 'Tertiary',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MoneyPill(label: 'Expense', color: colors.expense),
              _MoneyPill(label: 'Income', color: colors.income),
              _MoneyPill(label: 'Transfer', color: colors.transfer),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _seedIfNeeded,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Re-run seed (idempotent)'),
          ),
        ],
      ),
    );
  }

  void _cycleTheme() {
    const List<ThemePreference> order = <ThemePreference>[
      ThemePreference.system,
      ThemePreference.light,
      ThemePreference.dark,
      ThemePreference.amoled,
    ];
    final int index = order.indexOf(widget.appearance.preference);
    widget.appearance.setPreference(order[(index + 1) % order.length]);
  }
}

/// One tappable seed colour in the palette picker.
class _SeedDot extends StatelessWidget {
  const _SeedDot({
    required this.seed,
    required this.selected,
    required this.onTap,
  });

  final SeedColor seed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: seed.name,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(seed.value),
              borderRadius: BorderRadius.circular(12),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _MoneyPill extends StatelessWidget {
  const _MoneyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
