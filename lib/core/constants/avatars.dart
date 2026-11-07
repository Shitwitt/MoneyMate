import 'package:flutter/material.dart';

/// One of the twelve built-in profile avatars.
///
/// Avatars are pure Material icon + colour pairs (no bundled bitmaps) so the
/// app stays tiny, renders crisply at any size and the profile grid works
/// offline. `PaisaProvider` also supports a user-picked photo, which wins over
/// the selected index.
@immutable
class PaisaAvatar {
  const PaisaAvatar({
    required this.index,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final int index;
  final String label;
  final IconData icon;

  /// Tile background (a pastel taken from the Material tonal palette).
  final Color background;

  /// Icon colour drawn on [background].
  final Color foreground;

  /// Gradient used for the "hero" variant (profile header, onboarding preview).
  List<Color> get gradient => <Color>[
        background,
        Color.alphaBlend(foreground.withAlpha(46), background),
      ];
}

/// The avatar catalogue.
class Avatars {
  const Avatars._();

  static const List<PaisaAvatar> all = <PaisaAvatar>[
    PaisaAvatar(
      index: 0,
      label: 'Optimist',
      icon: Icons.sentiment_satisfied_alt_rounded,
      background: Color(0xFFFFE7C2),
      foreground: Color(0xFF8A5300),
    ),
    PaisaAvatar(
      index: 1,
      label: 'Explorer',
      icon: Icons.travel_explore_rounded,
      background: Color(0xFFD6E8FF),
      foreground: Color(0xFF0B4A8F),
    ),
    PaisaAvatar(
      index: 2,
      label: 'Saver',
      icon: Icons.savings_rounded,
      background: Color(0xFFD5F2E1),
      foreground: Color(0xFF106B41),
    ),
    PaisaAvatar(
      index: 3,
      label: 'Investor',
      icon: Icons.trending_up_rounded,
      background: Color(0xFFCDEFEA),
      foreground: Color(0xFF00544C),
    ),
    PaisaAvatar(
      index: 4,
      label: 'Foodie',
      icon: Icons.ramen_dining_rounded,
      background: Color(0xFFFFDAD6),
      foreground: Color(0xFF8C2F22),
    ),
    PaisaAvatar(
      index: 5,
      label: 'Athlete',
      icon: Icons.sports_cricket_rounded,
      background: Color(0xFFE4F3CC),
      foreground: Color(0xFF3A5E00),
    ),
    PaisaAvatar(
      index: 6,
      label: 'Creative',
      icon: Icons.palette_rounded,
      background: Color(0xFFEADDFF),
      foreground: Color(0xFF4A2D82),
    ),
    PaisaAvatar(
      index: 7,
      label: 'Music',
      icon: Icons.headphones_rounded,
      background: Color(0xFFFBD9EC),
      foreground: Color(0xFF7A1D53),
    ),
    PaisaAvatar(
      index: 8,
      label: 'Student',
      icon: Icons.school_rounded,
      background: Color(0xFFDEE2FF),
      foreground: Color(0xFF2A3A8F),
    ),
    PaisaAvatar(
      index: 9,
      label: 'Pet parent',
      icon: Icons.pets_rounded,
      background: Color(0xFFFFE2C8),
      foreground: Color(0xFF8A4210),
    ),
    PaisaAvatar(
      index: 10,
      label: 'Home',
      icon: Icons.cottage_rounded,
      background: Color(0xFFD8ECDF),
      foreground: Color(0xFF28553A),
    ),
    PaisaAvatar(
      index: 11,
      label: 'Professional',
      icon: Icons.work_rounded,
      background: Color(0xFFE3E0E9),
      foreground: Color(0xFF3C3546),
    ),
  ];

  /// Safe lookup — out-of-range indices (older settings records) fall back to
  /// the first avatar instead of throwing.
  static PaisaAvatar byIndex(int? index) {
    if (index == null || index < 0 || index >= all.length) return all.first;
    return all[index];
  }

  static int get count => all.length;

  /// Lightweight value object for persisting an inline images/*.png avatar
  /// path check. Kept here so UI code never hard-codes extensions.
  static bool isImagePath(String? path) {
    if (path == null) return false;
    final String lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }
}
