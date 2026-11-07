import 'package:flutter/material.dart';

import '../../../core/theme/seed_color.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../data/local/hive_storage.dart';
import '../../../data/models/settings_model.dart';

/// Owns the theme engine state for the whole app.
///
/// Reads once from Hive on construction (boxes are already open by then, so the
/// very first frame is already in the user's chosen colour) and writes back on
/// every change. Registered above `MaterialApp` so a theme change rebuilds the
/// tree instantly.
class AppearanceController extends ChangeNotifier {
  AppearanceController({HiveStorage? storage, SettingsModel? initialSettings})
      : _storage = storage ?? HiveStorage.instance {
    _settings = initialSettings ?? _storage.loadSettings();
  }

  final HiveStorage _storage;

  late SettingsModel _settings;

  /// The full settings record (theme values included).
  SettingsModel get settings => _settings;

  ThemeSettings get themeSettings => _settings.themeSettings;

  ThemePreference get preference => _settings.themePreference;

  SeedColor get seed => _settings.seed;

  bool get useDynamicColor => _settings.useDynamicColor;

  /// True when the seed-colour picker is the active source of colour, i.e. the
  /// user turned dynamic colour off. The picker is still *visible* when dynamic
  /// colour is on (it just has no effect until the switch is off), so this
  /// getter is only used for the "active" badge in Settings › Appearance.
  bool get showsSeedPalette => !_settings.useDynamicColor;

  Future<void> setPreference(ThemePreference preference) async {
    if (_settings.themePreference == preference) return;
    _settings = _settings.copyWith(themePreference: preference);
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> setSeed(SeedColor seed) async {
    if (_settings.seed == seed) return;
    _settings = _settings.copyWith(seed: seed);
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> setUseDynamicColor(bool enabled) async {
    if (_settings.useDynamicColor == enabled) return;
    _settings = _settings.copyWith(useDynamicColor: enabled);
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  /// Persists an arbitrary settings mutation made elsewhere (onboarding,
  /// privacy toggles, currency) and rebuilds the theme.
  Future<void> updateSettings(SettingsModel settings) async {
    _settings = settings;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  /// Re-reads settings from disk (used after a backup restore).
  void reload() {
    _settings = _storage.loadSettings();
    notifyListeners();
  }
}
