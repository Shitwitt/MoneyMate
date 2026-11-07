import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/avatars.dart';
import '../../core/constants/currencies.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/paisa_theme.dart';
import '../../core/theme/seed_color.dart';
import '../../core/theme/theme_preference.dart';
import '../../providers/paisa_provider.dart';
import '../../widgets/avatar_view.dart';
import '../categories/categories_screen.dart';

/// Profile & settings. Step 6 adds biometric lock, encrypted backup/restore and
/// the remaining preferences; everything exposed here is fully wired.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          // ---------------- Identity ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: <Widget>[
                PaisaAvatarView(
                  avatarIndex: provider.userAvatarIndex,
                  imagePath: provider.customImagePath,
                  size: 64,
                  borderWidth: 2,
                  borderColor: scheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        provider.userName.isEmpty
                            ? 'Add your name'
                            : provider.userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${CurrencyTable.byCode(provider.currencyCode).name} · '
                        '${AppLanguage.byCode(provider.languageCode).nativeName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit name',
                  onPressed: () => _editName(context),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Avatar',
            child: SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: Avatars.count + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    // "Photo" slot — picks a stored image path if one exists.
                    final bool active = provider.hasCustomAvatar;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () => _showPhotoInfo(context),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surfaceContainerHighest,
                            border: Border.all(
                              color: active ? scheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            active
                                ? Icons.check_rounded
                                : Icons.photo_outlined,
                            color: active
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  final PaisaAvatar avatar = Avatars.byIndex(index - 1);
                  final bool active = !provider.hasCustomAvatar &&
                      provider.userAvatarIndex == avatar.index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () => provider.setAvatarIndex(avatar.index),
                      child: PaisaAvatarView(
                        avatarIndex: avatar.index,
                        size: 56,
                        borderWidth: active ? 2 : 0,
                        borderColor: scheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ---------------- Appearance ----------------
          _Section(
            title: 'Appearance',
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final ThemePreference value in ThemePreference.values)
                        ChoiceChip(
                          selected: provider.themeMode == value,
                          avatar: Icon(value.icon, size: 16),
                          label: Text(value.label),
                          onSelected: (bool selected) {
                            if (selected) provider.setThemeMode(value);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Use system colour'),
                  subtitle: const Text(
                    'Match Android 12+ dynamic colours where available',
                  ),
                  value: provider.useDynamicColor,
                  onChanged: provider.setUseDynamicColor,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Accent',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (final SeedColor seed in SeedColor.palette)
                        Tooltip(
                          message: seed.name,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => provider.setSeedColor(seed),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Color(seed.value),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: provider.seedColor == seed
                                      ? scheme.onSurface
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: provider.seedColor == seed
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---------------- Money ----------------
          _Section(
            title: 'Money',
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded),
                  title: const Text('Currency'),
                  subtitle: Text(
                    CurrencyTable.byCode(provider.currencyCode).pickerLabel,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickCurrency(context),
                ),
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: const Text('Language'),
                  subtitle: Text(
                    AppLanguage.byCode(provider.languageCode).nativeName,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickLanguage(context),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Hide amounts'),
                  subtitle: const Text('Mask every figure behind dots'),
                  value: provider.hideAmounts,
                  onChanged: provider.setHideAmounts,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.savings_outlined),
                  title: const Text('Track income'),
                  subtitle: const Text('Show income fields and totals'),
                  value: provider.incomeTrackingEnabled,
                  onChanged: provider.setIncomeTrackingEnabled,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.calendar_view_week_rounded),
                  title: const Text('Week starts Monday'),
                  value: provider.weeklyStartMonday,
                  onChanged: provider.setWeeklyStartMonday,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Budget alerts'),
                  subtitle: const Text(
                    'Warn me when a category crosses its limit',
                  ),
                  value: provider.budgetAlertsEnabled,
                  onChanged: provider.setBudgetAlertsEnabled,
                ),
              ],
            ),
          ),

          // ---------------- Manage ----------------
          _Section(
            title: 'Manage',
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categories'),
                  subtitle: Text('${provider.categories.length} categories'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext _) => const CategoriesScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Accounts'),
                  subtitle: Text('${provider.accounts.length} accounts'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext _) => const AccountsManagerScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('Clear all data'),
                  subtitle: const Text('Erase every account, entry and budget'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmClearAll(context),
                ),
              ],
            ),
          ),

          // ---------------- About ----------------
          _Section(
            title: 'About',
            child: Column(
              children: <Widget>[
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('MoneyMate'),
                  subtitle: Text('Version 1.0.0 · offline spending tracker'),
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy'),
                  subtitle: const Text(
                    'Everything is stored on this device. No account, no cloud, '
                    'no internet permission.',
                  ),
                  isThreeLine: true,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Your data stays here'),
                      content: const Text(
                        'MoneyMate writes every record to a local Hive database '
                        'inside the app sandbox. There is no analytics, no '
                        'tracking and no network access.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
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
    if (result != null && result.isNotEmpty) {
      await provider.setUserName(result);
    }
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController controller) {
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Currency',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: CurrencyTable.all.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CurrencyDefinition currency =
                          CurrencyTable.all[index];
                      final bool selected =
                          currency.code == provider.currencyCode;
                      return ListTile(
                        title: Text(currency.pickerLabel),
                        subtitle: Text(currency.sampleAmount),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () async {
                          await provider.setCurrency(currency.code);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Language',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final AppLanguage language in AppLanguage.all)
                RadioListTile<String>(
                  value: language.code,
                  groupValue: provider.languageCode,
                  title: Text(
                    '${language.icon}  ${language.englishName}',
                  ),
                  subtitle: Text(language.nativeName),
                  onChanged: (String? code) async {
                    if (code == null) return;
                    await provider.setLanguage(code);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPhotoInfo(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Profile photo'),
        content: const Text(
          'Preset avatars keep the app fully offline and tiny. A custom photo '
          'slot is reserved for the Step 6 build, which adds the image picker.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final PaisaProvider provider = context.read<PaisaProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This deletes every account, category, transaction, debt and budget on '
          'this device. It cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.resetEverything();
  }
}

/// Grouped settings card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(PaisaTheme.cardRadius),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Account manager reachable from settings (full CRUD lives here rather than on
/// the Accounts tab so the tab stays a read-only overview).
class AccountsManagerScreen extends StatelessWidget {
  const AccountsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaisaProvider provider = context.watch<PaisaProvider>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: <Widget>[
          for (final account in provider.accounts)
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
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(account.color).withOpacity(0.18),
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
                        value: 'default',
                        child: Text('Make default'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (String value) async {
                      if (value == 'default') {
                        await provider.setDefaultAccount(account.id);
                        return;
                      }
                      final bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) => AlertDialog(
                          title: Text('Delete ${account.title}?'),
                          content: const Text(
                            'The account and its opening balance are removed. '
                            'Transactions that used it are kept for history.',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await provider.deleteAccount(account.id);
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
}
