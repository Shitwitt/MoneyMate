import 'package:flutter/material.dart';

/// Brand colour tokens (blueprint section 4.1).
///
/// Hex values live ONLY here. Widgets must read colours from
/// `Theme.of(context).colorScheme` (or `context.colors`), never from
/// hard-coded values.
abstract final class AppColors {
  /// Default seed: deep teal. The scheme is derived with
  /// `ColorScheme.fromSeed`, so Material You dynamic colour can replace it
  /// on Android 12+ without changing call sites.
  static const Color seed = Color(0xFF00696D);

  /// AMOLED variant surface (pure black).
  static const Color amoledSurface = Color(0xFF000000);
}
