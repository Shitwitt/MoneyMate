import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enum/filter_enums.dart';
import '../../core/constants/avatars.dart';
import '../../core/constants/currencies.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/paisa_colors.dart';
import '../../core/theme/paisa_theme.dart';
import '../../core/theme/seed_color.dart';
import '../../core/theme/theme_preference.dart';
import '../../core/utils/app_lock.dart';
import '../../core/utils/backup_service.dart';
import '../../core/utils/date_time_format.dart';
import '../../data/models/account_model.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/avatar_view.dart';
import '../accounts/add_account_screen.dart';
import '../budgets/category_manager_screen.dart';
import '../onboarding/pages/profile_page.dart' show pickAndPersistAvatar;

/// Profile, appearance, data management and security.
///
/// Everything is wired to real behaviour: theme and currency changes repaint the
/// whole app immediately, the backup writes a real `.json` file into the app's
/// sandbox and hands it to the platform share sheet, restore reads a picked file
/// and rebuilds every box, and the CSV export produces a spreadsheet-ready
/// document. Nothing here is a mock.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Set while a file operation runs so the tiles show progress and cannot be
  /// tapped twice.
  String? _busyAction;

  bool get _busy => _busyAction != null;

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: <Widget>[
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        key: const PageStorageKey<String>('settings_scroll'),
        padding: EdgeInsets.only(
          bottom: 32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          const _SectionHeader('Profile'),
          _ProfileCard(
            provider: provider,
            onEditName: () => _run(() => _editName(context)),
            onPickPhoto: () => _run(() => _pickPhoto(context)),
            onChooseAvatar: () => _run(() => _chooseAvatar(context)),
            onRemovePhoto: () => _run(() => provider.setCustomAvatar(null)),
          ),

          const _SectionHeader('Appearance'),
          _AppearanceSection(
            provider: provider,
            onSeedPicker: () => _run(() => _pickSeed(context)),
          ),

          const _SectionHeader('Currency & language'),
          _Section(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const _TileIcon(
                    icon: Icons.currency_exchange_rounded,
                    color: Color(0xFF00695C),
                  ),
                  title: const Text('Currency'),
                  subtitle: Text(
                    provider.currency.pickerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    provider.currency.sampleAmount,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => _run(() => _pickCurrency(context)),
                ),
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: const _TileIcon(
                    icon: Icons.translate_rounded,
                    color: Color(0xFF3949AB),
                  ),
                  title: const Text('Language'),
                  subtitle: Text(
                    AppLanguage.byCode(provider.languageCode).nativeName,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _run(() => _pickLanguage(context)),
                ),
              ],
            ),
          ),

          const _SectionHeader('Preferences'),
          _Section(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  secondary: const _TileIcon(
                    icon: Icons.visibility_off_outlined,
                    color: Color(0xFF6A1B9A),
                  ),
                  title: const Text('Hide amounts'),
                  subtitle: const Text('Mask every figure behind dots'),
                  value: provider.hideAmounts,
                  onChanged: provider.setHideAmounts,
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const _TileIcon(
                    icon: Icons.savings_outlined,
                    color: Color(0xFF2E7D32),
                  ),
                  title: const Text('Track income'),
                  subtitle: const Text('Show income fields and totals'),
                  value: provider.incomeTrackingEnabled,
                  onChanged: provider.setIncomeTrackingEnabled,
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const _TileIcon(
                    icon: Icons.calendar_view_week_rounded,
                    color: Color(0xFFEF6C00),
                  ),
                  title: const Text('Week starts Monday'),
                  subtitle: const Text('Used by the weekly charts and budgets'),
                  value: provider.weeklyStartMonday,
                  onChanged: provider.setWeeklyStartMonday,
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const _TileIcon(
                    icon: Icons.notifications_none_rounded,
                    color: Color(0xFF00838F),
                  ),
                  title: const Text('Budget alerts'),
                  subtitle: const Text('Warn when a category crosses its limit'),
                  value: provider.budgetAlertsEnabled,
                  onChanged: provider.setBudgetAlertsEnabled,
                ),
              ],
            ),
          ),

          const _SectionHeader('Security'),
          _BiometricTile(
            enabled: provider.biometricEnabled,
            onChanged: (bool value) => _run(() => _toggleBiometric(context, value)),
          ),

          const _SectionHeader('Data & backup'),
          _Section(
            child: Column(
              children: <Widget>[
                _ActionTile(
                  icon: Icons.backup_outlined,
                  color: const Color(0xFF00695C),
                  title: 'Export full backup',
                  subtitle: provider.settings.lastBackupAt == null
                      ? 'accounts · categories · entries · loans · settings'
                      : 'Last backup '
                          '${DateTimeFormat.dateTime(provider.settings.lastBackupAt!)}',
                  busy: _busyAction == 'backup',
                  onTap: _busy ? null : () => _run(() => _exportBackup(context)),
                ),
                const Divider(height: 1, indent: 64),
                _ActionTile(
                  icon: Icons.restore_rounded,
                  color: const Color(0xFF1565C0),
                  title: 'Restore from backup',
                  subtitle: 'Pick a paisa_backup_*.json file',
                  busy: _busyAction == 'restore',
                  onTap: _busy ? null : () => _run(() => _restoreBackup(context)),
                ),
                const Divider(height: 1, indent: 64),
                _ActionTile(
                  icon: Icons.table_view_outlined,
                  color: const Color(0xFF2E7D32),
                  title: 'Export transactions as CSV',
                  subtitle:
                      'Date, Title, Type, Category, Account, Amount, Notes · '
                      '${provider.transactions.length} rows',
                  busy: _busyAction == 'csv',
                  onTap: _busy ? null : () => _run(() => _exportCsv(context)),
                ),
              ],
            ),
          ),

          const _SectionHeader('Manage'),
          _Section(
            child: Column(
              children: <Widget>[
                _ActionTile(
                  icon: Icons.category_outlined,
                  color: const Color(0xFF6A1B9A),
                  title: 'Categories',
                  subtitle: '${provider.categories.length} categories',
                  onTap: () => _run(() => openCategoryManager(context)),
                ),
                const Divider(height: 1, indent: 64),
                _ActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF00695C),
                  title: 'Accounts',
                  subtitle: '${provider.accounts.length} accounts',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext _) => const AccountsManagerScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const _SectionHeader('Danger zone'),
          _Section(
            child: _ActionTile(
              icon: Icons.delete_forever_rounded,
              color: scheme.error,
              title: 'Clear all data',
              subtitle:
                  'Erase ${provider.totalRecordCount} records — cannot be undone',
              destructive: true,
              onTap: _busy ? null : () => _run(() => _confirmClearAll(context)),
            ),
          ),

          const _SectionHeader('About'),
          _Section(
            child: Column(
              children: <Widget>[
                const ListTile(
                  leading: _TileIcon(
                    icon: Icons.info_outline_rounded,
                    color: Color(0xFF455A64),
                  ),
                  title: Text('MoneyMate'),
                  subtitle: Text('Version 1.0.0 · offline spending tracker'),
                ),
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: const _TileIcon(
                    icon: Icons.shield_outlined,
                    color: Color(0xFF2E7D32),
                  ),
                  title: const Text('Privacy'),
                  subtitle: const Text(
                    'Everything is stored on this device — no account, no cloud',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPrivacy(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Profile
  // -------------------------------------------------------------------------

  Future<void> _editName(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    final TextEditingController controller =
        TextEditingController(text: provider.userName);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Hemanth'),
          onSubmitted: (String value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    await provider.setUserName(result);
    if (!mounted) return;
    _toast('Name updated');
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    try {
      final String? path = await pickAndPersistAvatar();
      if (path == null) return;
      await provider.setCustomAvatar(path);
      if (!mounted) return;
      _toast('Profile photo updated');
    } catch (error) {
      if (!mounted) return;
      _toast('Could not read that image: $error', error: true);
    }
  }

  Future<void> _chooseAvatar(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Choose an avatar',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hand-drawn tiles keep the app fully offline.',
                style: Theme.of(sheetContext).textTheme.labelSmall?.copyWith(
                      color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: <Widget>[
                  for (final PaisaAvatar avatar in Avatars.all)
                    InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: () async {
                        await provider.setAvatarIndex(avatar.index);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: PaisaAvatarView(
                        avatarIndex: avatar.index,
                        size: 64,
                        borderWidth:
                            !provider.hasCustomAvatar &&
                                    provider.userAvatarIndex == avatar.index
                                ? 2.5
                                : 0,
                        borderColor:
                            Theme.of(sheetContext).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Appearance
  // -------------------------------------------------------------------------

  /// Seed palette modal. Opens from the "Accent colour" row and writes the
  /// choice straight into the theme engine.
  Future<void> _pickSeed(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final ThemeData sheetTheme = Theme.of(sheetContext);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Accent colour',
                    style: sheetTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used whenever Material You is off, or on devices older '
                    'than Android 12.',
                    style: sheetTheme.textTheme.labelSmall?.copyWith(
                      color: sheetTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: <Widget>[
                      for (final SeedColor seed in SeedColor.palette)
                        _SeedSwatch(
                          seed: seed,
                          selected: provider.seedColor == seed,
                          onTap: () async {
                            await provider.setSeedColor(seed);
                            setSheetState(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Selected: ${provider.seedColor.name}',
                          style: sheetTheme.textTheme.labelMedium?.copyWith(
                            color: sheetTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Currency & language
  // -------------------------------------------------------------------------

  Future<void> _pickCurrency(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    final TextEditingController search = TextEditingController();
    String? code;
    try {
      code = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (BuildContext sheetContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              // One shared, tested search implementation keeps the picker's
              // behaviour identical to the rest of the app.
              final List<CurrencyDefinition> matches =
                  CurrencyTable.search(search.text);
              return SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * 0.78,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Row(
                        children: <Widget>[
                          Text(
                            'Currency',
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            '${CurrencyTable.all.length} supported',
                            style: Theme.of(sheetContext)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(sheetContext)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: search,
                        onChanged: (_) => setSheetState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          hintText: 'Search a currency or code',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: matches.isEmpty
                          ? Center(
                              child: Text(
                                "No currency matches '${search.text}'.",
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(sheetContext)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: matches.length,
                              itemBuilder: (BuildContext context, int index) {
                                final CurrencyDefinition currency =
                                    matches[index];
                                final bool selected =
                                    currency.code == provider.currencyCode;
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: selected
                                        ? Theme.of(sheetContext)
                                            .colorScheme
                                            .primaryContainer
                                        : Theme.of(sheetContext)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    child: Text(
                                      currency.symbol,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(sheetContext)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                  title: Text(currency.name),
                                  subtitle: Text(
                                    '${currency.code} · sample '
                                    '${currency.sampleAmount}',
                                  ),
                                  trailing: selected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: Theme.of(sheetContext)
                                              .colorScheme
                                              .primary,
                                        )
                                      : null,
                                  onTap: () => Navigator.of(sheetContext)
                                      .pop(currency.code),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      search.dispose();
    }
    if (code == null || code == provider.currencyCode) return;
    await provider.setCurrency(code);
    if (!mounted) return;
    _toast('Currency switched to ${CurrencyTable.byCode(code).code}');
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Language',
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            // A plain ListTile + trailing check instead of RadioListTile: the
            // radio widget's `groupValue`/`onChanged` pair is deprecated on the
            // newest Flutter, and this also matches the currency sheet's shape.
            for (final AppLanguage language in AppLanguage.all)
              ListTile(
                title: Text('${language.icon}  ${language.englishName}'),
                subtitle: Text(language.nativeName),
                trailing: language.code == provider.languageCode
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  await provider.setLanguage(language.code);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Security
  // -------------------------------------------------------------------------

  /// Turns the lock on only after the device has actually authenticated once.
  ///
  /// A phone with no screen lock is refused rather than locked out: enabling a
  /// guard nothing can satisfy would be a promise the platform cannot keep.
  Future<void> _toggleBiometric(BuildContext context, bool enable) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    if (!enable) {
      await provider.setBiometricEnabled(false);
      if (!mounted) return;
      _toast('App lock turned off');
      return;
    }

    setState(() => _busyAction = 'biometric');
    try {
      final DeviceAuthResult result = await authenticateWithDevice(
        reason: 'Confirm it is you to turn on app lock',
      );
      if (!mounted) return;
      if (result.message != null) {
        // No screen lock on this device: refuse rather than pretend. Turning the
        // lock on here would promise protection the platform cannot deliver.
        _toast(
          '${result.message} App lock needs a device PIN, pattern, fingerprint '
          'or face unlock.',
          error: true,
        );
      } else if (result.authenticated) {
        await provider.setBiometricEnabled(true);
        if (!mounted) return;
        _toast('App lock is on — MoneyMate asks every launch');
      } else {
        _toast(
          'App lock was not enabled because the device check was cancelled.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  // -------------------------------------------------------------------------
  // Data & backup
  // -------------------------------------------------------------------------

  Future<void> _exportBackup(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    setState(() => _busyAction = 'backup');
    try {
      final String json = provider.exportBackupJson();
      final Rect? origin = _shareOrigin(context);
      final bool shared = await BackupService.shareBackup(
        json,
        sharePositionOrigin: origin,
      );
      if (shared) {
        await provider.updateSettings(
          provider.settings.copyWith(lastBackupAt: DateTime.now()),
        );
      }
      if (!mounted) return;
      final int records = provider.totalRecordCount;
      _toast(
        shared
            ? 'Backup ready · ${backupFileNameHint()} · $records records'
            : 'Backup cancelled',
      );
    } catch (error) {
      if (!mounted) return;
      _toast('Could not export the backup: $error', error: true);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Restore a backup?'),
        content: Text(
          'The file replaces everything currently on this device — '
          '${provider.totalRecordCount} records. Export a backup first if you '
          'might want this data back.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Choose file'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyAction = 'restore');
    try {
      final String? text = await BackupService.pickBackupJson();
      if (text == null || text.trim().isEmpty) {
        if (!mounted) return;
        _toast('No file selected');
        return;
      }
      final int restored = await provider.restoreBackupJson(text);
      if (!mounted) return;
      _toast('Restored $restored records from the backup');
    } on FormatException catch (error) {
      if (!mounted) return;
      _toast(error.message, error: true);
    } catch (error) {
      if (!mounted) return;
      _toast('Restore failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    if (provider.transactions.isEmpty) {
      _toast('There are no transactions to export yet', error: true);
      return;
    }
    setState(() => _busyAction = 'csv');
    try {
      final String csv = provider.exportTransactionsCsv();
      final bool shared = await BackupService.shareCsv(
        csv,
        sharePositionOrigin: _shareOrigin(context),
      );
      if (!mounted) return;
      _toast(
        shared
            ? 'CSV ready · ${provider.transactions.length} rows'
            : 'Export cancelled',
      );
    } catch (error) {
      if (!mounted) return;
      _toast('Could not export the CSV: $error', error: true);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Clear all data?'),
        content: Text(
          'This deletes ${provider.totalRecordCount} records — every account, '
          'category, transaction, loan and budget — and resets the app. Export '
          'a backup first if this data matters. It cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.resetEverything();
    if (!mounted) return;
    _toast('All data cleared');
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Share-sheet anchor rect (required for iPad popovers).
  Rect? _shareOrigin(BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Runs an async action from a button tap, catching the errors a plugin can
  /// throw and showing them instead of an unhandled exception.
  void _run(Future<void> Function() action) {
    action().catchError((Object error) {
      if (!mounted) return;
      _toast('$error', error: true);
    });
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? scheme.errorContainer : null,
          duration: Duration(milliseconds: error ? 4200 : 2600),
        ),
      );
  }
}

/// File-name hint shown in the export confirmation.
String backupFileNameHint() => BackupService.backupFileName();

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.provider,
    required this.onEditName,
    required this.onPickPhoto,
    required this.onChooseAvatar,
    required this.onRemovePhoto,
  });

  final PaisaProvider provider;
  final VoidCallback onEditName;
  final VoidCallback onPickPhoto;
  final VoidCallback onChooseAvatar;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final PaisaColors colors = PaisaColors.of(context);
    final int records = provider.totalRecordCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              scheme.primaryContainer,
              Color.alphaBlend(
                scheme.surfaceContainerHighest.withAlpha(150),
                scheme.primaryContainer,
              ),
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: onPickPhoto,
                      child: PaisaAvatarView(
                        avatarIndex: provider.userAvatarIndex,
                        imagePath: provider.customImagePath,
                        size: 68,
                        borderWidth: 2,
                        borderColor: scheme.onPrimaryContainer.withValues(alpha: 0.35),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.primaryContainer,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 12,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onEditName,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  provider.userName.isEmpty
                                      ? 'Add your name'
                                      : provider.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.edit_rounded,
                                size: 15,
                                color: scheme.onPrimaryContainer
                                    .withValues(alpha: 0.65),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${provider.currency.code} · '
                        '${AppLanguage.byCode(provider.languageCode).nativeName}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _MiniStat(
                  label: 'Records',
                  value: '$records',
                  accent: scheme.onPrimaryContainer,
                ),
                _MiniStat(
                  label: 'Accounts',
                  value: '${provider.accounts.length}',
                  accent: colors.income,
                ),
                _MiniStat(
                  label: 'Categories',
                  value: '${provider.categories.length}',
                  accent: colors.transfer,
                ),
                _MiniStat(
                  label: 'Loans',
                  value: '${provider.debts.length}',
                  accent: colors.debtTaken,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChooseAvatar,
                    icon: const Icon(Icons.face_retouching_natural, size: 18),
                    label: const Text('Avatars'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onPrimaryContainer,
                      side: BorderSide(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                ),
                if (provider.hasCustomAvatar) ...<Widget>[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRemovePhoto,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Remove photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onPrimaryContainer,
                        side: BorderSide(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance
// ---------------------------------------------------------------------------

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.provider, required this.onSeedPicker});

  final PaisaProvider provider;
  final VoidCallback onSeedPicker;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool amoled = provider.themeMode == ThemePreference.amoled;
    final bool canPickSeed = !provider.useDynamicColor;

    return _Section(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Theme',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    for (final ThemePreference value
                        in ThemePreference.values) ...<Widget>[
                      Expanded(
                        child: _ThemeChoice(
                          preference: value,
                          selected: provider.themeMode == value,
                          onTap: () => provider.setThemeMode(value),
                        ),
                      ),
                      if (value != ThemePreference.values.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const _TileIcon(
              icon: Icons.contrast_rounded,
              color: Color(0xFF212121),
            ),
            title: const Text('AMOLED pitch black'),
            subtitle: Text(
              amoled
                  ? 'Extra-dark surfaces, gentler on OLED panels'
                  : 'Turn on for pure #000000 backgrounds',
            ),
            value: amoled,
            onChanged: provider.setAmoled,
          ),
          const Divider(height: 1, indent: 64),
          SwitchListTile(
            secondary: const _TileIcon(
              icon: Icons.palette_outlined,
              color: Color(0xFF6A1B9A),
            ),
            title: const Text('Material You colours'),
            subtitle: Text(
              provider.useDynamicColor
                  ? 'Following the system wallpaper palette'
                  : 'Off — using the accent below',
            ),
            value: provider.useDynamicColor,
            onChanged: provider.setUseDynamicColor,
          ),
          ListTile(
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color(provider.seedColor.value),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.colorize_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
            title: const Text('Accent colour'),
            subtitle: Text(
              canPickSeed
                  ? provider.seedColor.name
                  : 'Available when Material You is off',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            enabled: canPickSeed,
            onTap: canPickSeed ? onSeedPicker : null,
          ),
          if (canPickSeed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: SeedColor.palette.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final SeedColor seed = SeedColor.palette[index];
                    final bool selected = provider.seedColor == seed;
                    return GestureDetector(
                      onTap: () => provider.setSeedColor(seed),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(seed.value),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? scheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One of the four theme cards.
class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.preference,
    required this.selected,
    required this.onTap,
  });

  final ThemePreference preference;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              preference.icon,
              size: 19,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 5),
            Text(
              preference.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round seed swatch inside the accent modal.
class _SeedSwatch extends StatelessWidget {
  const _SeedSwatch({
    required this.seed,
    required this.selected,
    required this.onTap,
  });

  final SeedColor seed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Color(seed.value),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.onSurface : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : null,
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 58,
            child: Text(
              seed.name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Security
// ---------------------------------------------------------------------------

class _BiometricTile extends StatelessWidget {
  const _BiometricTile({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        children: <Widget>[
          SwitchListTile(
            secondary: _TileIcon(
              icon: enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFF455A64),
            ),
            title: const Text('App lock'),
            subtitle: Text(
              enabled
                  ? 'Fingerprint, face or device PIN on every launch'
                  : 'Protect the ledger when the app opens or resumes',
            ),
            value: enabled,
            onChanged: onChanged,
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MoneyMate re-locks as soon as it leaves the foreground. '
                      'If the device has no screen lock, the app stays open.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared row widgets
// ---------------------------------------------------------------------------

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.busy = false,
    this.destructive = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool busy;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      leading: _TileIcon(icon: icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: destructive ? color : null,
        ),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              destructive
                  ? Icons.warning_amber_rounded
                  : Icons.chevron_right_rounded,
              color: destructive ? color : null,
            ),
      enabled: !busy,
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Read-only account list with the destructive actions (make default, delete).
///
/// Creating and editing accounts happens on the full [AddAccountScreen] so the
/// carousel, the statement and Settings all share one editor.
class AccountsManagerScreen extends StatelessWidget {
  const AccountsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add account',
            onPressed: () => openAddAccountScreen(context),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: <Widget>[
          for (final AccountModel account in provider.accounts)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onTap: () => openAddAccountScreen(
                    context,
                    existing: account,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(account.color).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      account.cardType.icon,
                      color: Color(account.color),
                      size: 20,
                    ),
                  ),
                  title: Text(account.title),
                  subtitle: Text(
                    '${account.cardType.label} · ${account.maskedNumber}'
                    '${account.isDefault ? ' · Default' : ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      if (!account.isDefault)
                        const PopupMenuItem<String>(
                          value: 'default',
                          child: Text('Make default'),
                        ),
                      if (provider.accounts.length > 1)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                    ],
                    onSelected: (String value) async {
                      switch (value) {
                        case 'edit':
                          await openAddAccountScreen(
                            context,
                            existing: account,
                          );
                        case 'default':
                          await provider.setDefaultAccount(account.id);
                        case 'delete':
                          await _confirmDelete(context, provider, account);
                      }
                    },
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Opening balances are set when the account is created; the current '
              'balance always comes from the ledger.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    PaisaProvider provider,
    AccountModel account,
  ) async {
    final int linked = provider.transactions
        .where((transaction) =>
            transaction.accountId == account.id ||
            transaction.toAccountId == account.id)
        .length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Delete ${account.title}?'),
        content: Text(
          'The account, its opening balance and the $linked transaction'
          '${linked == 1 ? '' : 's'} recorded on it are removed.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.deleteAccount(account.id);
  }
}

/// Placeholder-free privacy sheet, kept as a method so the About row stays a
/// single tappable line.
void _showPrivacy(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      icon: const Icon(Icons.shield_outlined),
      title: const Text('Your data stays here'),
      content: const Text(
        'MoneyMate writes every record to a local Hive database inside the app '
        'sandbox. There is no account, no analytics, no tracking and no network '
        'call — the only way data leaves the device is the backup or CSV you '
        'export yourself.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
