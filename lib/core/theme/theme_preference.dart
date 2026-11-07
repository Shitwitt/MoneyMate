import 'package:flutter/material.dart';

import 'seed_color.dart';

/// The four theme modes Paisa supports.
///
/// [system] follows the OS, [light] and [dark] force a mode, and [amoled]
/// forces the pitch black variant of the dark theme (used by OLED devices).
enum ThemePreference {
  system,
  light,
  dark,
  amoled;

  /// Persisted value — never rename these strings, prefs depend on them.
  String get key => name;

  static ThemePreference fromKey(String? key) {
    return ThemePreference.values.firstWhere(
      (ThemePreference value) => value.name == key,
      orElse: () => ThemePreference.system,
    );
  }

  String get label {
    switch (this) {
      case ThemePreference.system:
        return 'System';
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
      case ThemePreference.amoled:
        return 'AMOLED';
    }
  }

  String get description {
    switch (this) {
      case ThemePreference.system:
        return 'Follow device appearance';
      case ThemePreference.light:
        return 'Always bright';
      case ThemePreference.dark:
        return 'Easier on the eyes';
      case ThemePreference.amoled:
        return 'Pitch black, saves battery';
    }
  }

  IconData get icon {
    switch (this) {
      case ThemePreference.system:
        return Icons.brightness_auto_rounded;
      case ThemePreference.light:
        return Icons.light_mode_rounded;
      case ThemePreference.dark:
        return Icons.dark_mode_rounded;
      case ThemePreference.amoled:
        return Icons.contrast_rounded;
    }
  }

  /// True for both dark variants.
  bool get isDark => this == ThemePreference.dark || this == ThemePreference.amoled;

  /// True only for the pitch black variant.
  bool get isAmoled => this == ThemePreference.amoled;

  /// The [ThemeMode] handed to `MaterialApp`.
  ///
  /// The AMOLED variant is delivered as a *dark* theme, so it maps to
  /// [ThemeMode.dark] here; [isAmoled] tells the theme builder to use black.
  ThemeMode get materialThemeMode {
    switch (this) {
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
      case ThemePreference.amoled:
        return ThemeMode.dark;
    }
  }

  /// Resolves the currently effective preference for a platform brightness.
  ThemePreference resolve(Brightness platformBrightness) {
    if (this != ThemePreference.system) return this;
    return platformBrightness == Brightness.dark
        ? ThemePreference.dark
        : ThemePreference.light;
  }
}

/// Everything the theme engine needs to build a [ThemeData].
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.preference = ThemePreference.system,
    this.seed = SeedColor.defaultSeed,
    this.useDynamicColor = true,
  });

  /// Monochrome fallback used when the system dynamic colour scheme disables
  /// all chromatic accents (`ColorScheme.dynamicSchemeVariant == monochrome`).
  const ThemeSettings.fallback()
      : preference = ThemePreference.system,
        seed = SeedColor.defaultSeed,
        useDynamicColor = false;

  final ThemePreference preference;

  /// Used whenever [useDynamicColor] is false, or when the platform cannot
  /// supply a dynamic colour scheme.
  final SeedColor seed;

  /// Whether Android 12+ dynamic colour is enabled (user toggled).
  final bool useDynamicColor;

  ThemeSettings copyWith({
    ThemePreference? preference,
    SeedColor? seed,
    bool? useDynamicColor,
  }) {
    return ThemeSettings(
      preference: preference ?? this.preference,
      seed: seed ?? this.seed,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings &&
      other.preference == preference &&
      other.seed == seed &&
      other.useDynamicColor == useDynamicColor;

  @override
  int get hashCode => Object.hash(preference, seed, useDynamicColor);

  @override
  String toString() =>
      'ThemeSettings(preference: $preference, seed: $seed, dynamic: $useDynamicColor)';
}
