import 'package:flutter/foundation.dart';

import '../../core/theme/seed_color.dart';
import '../../core/theme/theme_preference.dart';
import 'map_utils.dart';

/// The single settings record persisted in `settings_box` under
/// [SettingsModel.storageKey].
///
/// Everything the app needs to restore itself on the next cold start lives
/// here: onboarding state, the theme engine configuration, currency, and the
/// privacy / security toggles.
@immutable
class SettingsModel {
  const SettingsModel({
    this.onboardingComplete = false,
    this.userName = '',
    this.userAvatarIndex = 0,
    this.customImagePath,
    this.languageCode = 'en',
    this.currencySymbol = '₹',
    this.currencyCode = 'INR',
    this.localeCode = 'en_IN',
    this.themePreference = ThemePreference.system,
    this.seed = SeedColor.defaultSeed,
    this.useDynamicColor = true,
    this.incomeTrackingEnabled = true,
    this.biometricLockEnabled = false,
    this.budgetAlertsEnabled = true,
    this.hideAmounts = false,
    this.weeklyStartMonday = true,
    this.lastBackupAt,
    this.installedAt,
    this.schemaVersion = currentSchemaVersion,
  });

  /// Key the record is stored under inside `settings_box`.
  static const String storageKey = 'app_settings';

  /// Bumped whenever the on-disk shape changes; used by migrations.
  static const int currentSchemaVersion = 2;

  // ---------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------

  /// True once the user has finished (or skipped) onboarding.
  final bool onboardingComplete;

  /// Display name used in greetings. Empty until onboarding sets it.
  final String userName;

  /// Index into `Avatars.all` — the built-in illustrated avatar grid.
  final int userAvatarIndex;

  /// Absolute path of a user-picked photo. When set it wins over
  /// [userAvatarIndex].
  final String? customImagePath;

  /// BCP-47 language tag chosen on the onboarding welcome page
  /// (`en`, `hi`, `de`, `es`, `fr`).
  final String languageCode;

  bool get hasCustomAvatar =>
      customImagePath != null && customImagePath!.trim().isNotEmpty;

  // ---------------------------------------------------------------------
  // Money formatting
  // ---------------------------------------------------------------------

  /// `₹` by default; kept as data so the app can be re-purposed for other
  /// currencies without code changes.
  final String currencySymbol;

  /// ISO-4217 code, `INR` by default.
  final String currencyCode;

  /// BCP-47 locale used for `intl` number / date formatting.
  final String localeCode;

  // ---------------------------------------------------------------------
  // Theme engine
  // ---------------------------------------------------------------------

  final ThemePreference themePreference;

  /// Seed used when [useDynamicColor] is off (or unsupported).
  final SeedColor seed;

  /// Android 12+ wallpaper-derived colour.
  final bool useDynamicColor;

  // ---------------------------------------------------------------------
  // Feature toggles
  // ---------------------------------------------------------------------

  /// Shows the income tab / income option in the entry sheet.
  final bool incomeTrackingEnabled;

  /// Requires biometric / device credential unlock at launch.
  final bool biometricLockEnabled;

  /// Shows budget warnings on the home screen.
  final bool budgetAlertsEnabled;

  /// Hides every amount behind `••••` until tapped (shoulder-surfing mode).
  final bool hideAmounts;

  /// Weeks start on Monday (Indian convention) instead of Sunday.
  final bool weeklyStartMonday;

  // ---------------------------------------------------------------------
  // Bookkeeping
  // ---------------------------------------------------------------------

  final DateTime? lastBackupAt;
  final DateTime? installedAt;
  final int schemaVersion;

  /// The theme engine configuration derived from these settings.
  ThemeSettings get themeSettings => ThemeSettings(
        preference: themePreference,
        seed: seed,
        useDynamicColor: useDynamicColor,
      );

  bool get hasName => userName.trim().isNotEmpty;

  /// First name for greetings, falling back to `there`.
  String get greetingName {
    final String trimmed = userName.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  // ---------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'onboardingComplete': onboardingComplete,
      'userName': userName,
      'userAvatarIndex': userAvatarIndex,
      'customImagePath': customImagePath,
      'languageCode': languageCode,
      'currencySymbol': currencySymbol,
      'currencyCode': currencyCode,
      'localeCode': localeCode,
      'themePreference': themePreference.key,
      'seedColorValue': seed.value,
      'useDynamicColor': useDynamicColor,
      'incomeTrackingEnabled': incomeTrackingEnabled,
      'biometricLockEnabled': biometricLockEnabled,
      'budgetAlertsEnabled': budgetAlertsEnabled,
      'hideAmounts': hideAmounts,
      'weeklyStartMonday': weeklyStartMonday,
      'lastBackupAt':
          lastBackupAt == null ? null : writeDateTime(lastBackupAt!),
      'installedAt': installedAt == null ? null : writeDateTime(installedAt!),
      'schemaVersion': schemaVersion,
    };
  }

  factory SettingsModel.fromMap(Map<dynamic, dynamic> map) {
    const SettingsModel defaults = SettingsModel();
    return SettingsModel(
      onboardingComplete:
          readBool(map['onboardingComplete'], fallback: defaults.onboardingComplete),
      userName: readString(map['userName'], fallback: defaults.userName),
      userAvatarIndex: readInt(map['userAvatarIndex']),
      customImagePath: readNullableString(map['customImagePath']),
      languageCode:
          readString(map['languageCode'], fallback: defaults.languageCode),
      currencySymbol:
          readString(map['currencySymbol'], fallback: defaults.currencySymbol),
      currencyCode:
          readString(map['currencyCode'], fallback: defaults.currencyCode),
      localeCode: readString(map['localeCode'], fallback: defaults.localeCode),
      themePreference:
          ThemePreference.fromKey(map['themePreference'] as String?),
      seed: SeedColor.fromValue(_seedValueOrNull(map['seedColorValue'])),
      useDynamicColor:
          readBool(map['useDynamicColor'], fallback: defaults.useDynamicColor),
      incomeTrackingEnabled: readBool(
        map['incomeTrackingEnabled'],
        fallback: defaults.incomeTrackingEnabled,
      ),
      biometricLockEnabled: readBool(
        map['biometricLockEnabled'],
        fallback: defaults.biometricLockEnabled,
      ),
      budgetAlertsEnabled: readBool(
        map['budgetAlertsEnabled'],
        fallback: defaults.budgetAlertsEnabled,
      ),
      hideAmounts: readBool(map['hideAmounts'], fallback: defaults.hideAmounts),
      weeklyStartMonday: readBool(
        map['weeklyStartMonday'],
        fallback: defaults.weeklyStartMonday,
      ),
      lastBackupAt: readNullableDateTime(map['lastBackupAt']),
      installedAt: readNullableDateTime(map['installedAt']),
      schemaVersion:
          readInt(map['schemaVersion'], fallback: currentSchemaVersion),
    );
  }

  SettingsModel copyWith({
    bool? onboardingComplete,
    String? userName,
    int? userAvatarIndex,
    String? customImagePath,
    bool clearCustomImagePath = false,
    String? languageCode,
    String? currencySymbol,
    String? currencyCode,
    String? localeCode,
    ThemePreference? themePreference,
    SeedColor? seed,
    bool? useDynamicColor,
    bool? incomeTrackingEnabled,
    bool? biometricLockEnabled,
    bool? budgetAlertsEnabled,
    bool? hideAmounts,
    bool? weeklyStartMonday,
    DateTime? lastBackupAt,
    DateTime? installedAt,
    int? schemaVersion,
  }) {
    return SettingsModel(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      userName: userName ?? this.userName,
      userAvatarIndex: userAvatarIndex ?? this.userAvatarIndex,
      customImagePath: clearCustomImagePath
          ? null
          : (customImagePath ?? this.customImagePath),
      languageCode: languageCode ?? this.languageCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      localeCode: localeCode ?? this.localeCode,
      themePreference: themePreference ?? this.themePreference,
      seed: seed ?? this.seed,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      incomeTrackingEnabled:
          incomeTrackingEnabled ?? this.incomeTrackingEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      hideAmounts: hideAmounts ?? this.hideAmounts,
      weeklyStartMonday: weeklyStartMonday ?? this.weeklyStartMonday,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      installedAt: installedAt ?? this.installedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SettingsModel &&
      other.onboardingComplete == onboardingComplete &&
      other.userName == userName &&
      other.userAvatarIndex == userAvatarIndex &&
      other.customImagePath == customImagePath &&
      other.languageCode == languageCode &&
      other.currencySymbol == currencySymbol &&
      other.currencyCode == currencyCode &&
      other.localeCode == localeCode &&
      other.themePreference == themePreference &&
      other.seed == seed &&
      other.useDynamicColor == useDynamicColor &&
      other.incomeTrackingEnabled == incomeTrackingEnabled &&
      other.biometricLockEnabled == biometricLockEnabled &&
      other.budgetAlertsEnabled == budgetAlertsEnabled &&
      other.hideAmounts == hideAmounts &&
      other.weeklyStartMonday == weeklyStartMonday &&
      other.lastBackupAt == lastBackupAt &&
      other.installedAt == installedAt &&
      other.schemaVersion == schemaVersion;

  @override
  int get hashCode => Object.hash(
        onboardingComplete,
        userName,
        currencySymbol,
        currencyCode,
        localeCode,
        themePreference,
        seed,
        useDynamicColor,
        incomeTrackingEnabled,
        biometricLockEnabled,
        budgetAlertsEnabled,
        hideAmounts,
        weeklyStartMonday,
        lastBackupAt,
        installedAt,
        schemaVersion,
      );

  @override
  String toString() =>
      'SettingsModel(onboarded: $onboardingComplete, theme: $themePreference, seed: ${seed.name})';

  /// Treats a missing / zero seed as "use the default".
  static int? _seedValueOrNull(Object? raw) {
    final int value = readInt(raw);
    return value == 0 ? null : value;
  }
}
