/// A user selectable Material 3 seed colour.
///
/// Paisa ships with a fixed, vibrant palette (the same twelve hues Google uses
/// for its Material palette) so the app never looks washed out and works
/// consistently on devices older than Android 12 that cannot supply a system
/// dynamic colour.
class SeedColor {
  const SeedColor({
    required this.name,
    required this.value,
  });

  /// Human readable label shown in the palette picker.
  final String name;

  /// Opaque ARGB seed value.
  final int value;

  @override
  String toString() => '$name (#${value.toRadixString(16)})';

  @override
  bool operator ==(Object other) =>
      other is SeedColor && other.name == name && other.value == value;

  @override
  int get hashCode => Object.hash(name, value);

  /// The default seed — Paisa's signature teal (first palette entry).
  static const SeedColor defaultSeed = SeedColor(name: 'Teal', value: 0xFF00897B);

  /// Twelve vibrant Material seeds in a fixed, stable order.
  static const List<SeedColor> palette = <SeedColor>[
    SeedColor(name: 'Teal', value: 0xFF00897B),
    SeedColor(name: 'Green', value: 0xFF43A047),
    SeedColor(name: 'Lime', value: 0xFF7CB342),
    SeedColor(name: 'Yellow', value: 0xFFFDD835),
    SeedColor(name: 'Orange', value: 0xFFFB8C00),
    SeedColor(name: 'Deep Orange', value: 0xFFF4511E),
    SeedColor(name: 'Red', value: 0xFFE53935),
    SeedColor(name: 'Pink', value: 0xFFD81B60),
    SeedColor(name: 'Purple', value: 0xFF8E24AA),
    SeedColor(name: 'Deep Purple', value: 0xFF5E35B1),
    SeedColor(name: 'Indigo', value: 0xFF3949AB),
    SeedColor(name: 'Blue', value: 0xFF1E88E5),
  ];

  /// Returns the palette entry matching [value], or [defaultSeed].
  static SeedColor fromValue(int? value) {
    if (value == null) return defaultSeed;
    for (final SeedColor seed in palette) {
      if (seed.value == value) return seed;
    }
    // A seed persisted by an older build that is no longer in the palette is
    // still honoured so the app keeps the user's look.
    return SeedColor(name: 'Custom', value: value);
  }
}
