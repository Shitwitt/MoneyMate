import 'dart:convert';

/// Compile-time sentinel used by `copyWith` defaults.
class _ModelCodecSentinel {
  const _ModelCodecSentinel();
}

/// Small, dependency-free codec helpers shared by every Paisa Hive model.
///
/// Hive boxes store only primitives: strings, ints, doubles, bools, null, and
/// maps whose values are also primitives. This keeps the app free of generated
/// `.g.dart` type adapters while still allowing safe schema evolution.
abstract final class ModelCodec {
  /// Sentinel used by `copyWith` methods to distinguish "not supplied" from an
  /// explicit `null`.
  static const Object unset = _ModelCodecSentinel();

  static bool isUnset(Object? value) => identical(value, unset);

  static Map<String, dynamic> normalize(Map<dynamic, dynamic>? map) {
    if (map == null) return <String, dynamic>{};
    return map.map<String, dynamic>(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>(key.toString(), value),
    );
  }

  static String string(Map<String, dynamic> map, String key, {String fallback = ''}) {
    final dynamic value = map[key];
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static String? nullableString(Map<String, dynamic> map, String key) {
    final dynamic value = map[key];
    if (value == null) return null;
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    final String text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int integer(
    Map<String, dynamic> map,
    String key, {
    int fallback = 0,
  }) {
    final dynamic value = map[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double decimal(
    Map<String, dynamic> map,
    String key, {
    double fallback = 0,
  }) {
    final dynamic value = map[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is bool) return value ? 1 : 0;
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool boolean(
    Map<String, dynamic> map,
    String key, {
    bool fallback = false,
  }) {
    final dynamic value = map[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final String normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  static int color(
    Map<String, dynamic> map,
    String key, {
    int fallback = 0xFFFBB69D,
  }) {
    return integer(map, key, fallback: fallback);
  }

  static DateTime dateTime(
    Map<String, dynamic> map,
    String key, {
    DateTime? fallback,
  }) {
    final dynamic value = map[key];
    final DateTime effectiveFallback = fallback ?? DateTime.now();
    if (value is DateTime) return value.toLocal();
    if (value is int) {
      return DateTime.fromMicrosecondsSinceEpoch(value).toLocal();
    }
    if (value is String && value.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return effectiveFallback;
  }

  static DateTime? nullableDateTime(Map<String, dynamic> map, String key) {
    final dynamic value = map[key];
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is int) return DateTime.fromMicrosecondsSinceEpoch(value).toLocal();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  static String encodeDateTime(DateTime? value) {
    return (value ?? DateTime.now()).toLocal().toIso8601String();
  }

  static String? encodeNullableDateTime(DateTime? value) {
    return value?.toLocal().toIso8601String();
  }

  static String encodeEnum(Enum value) => value.name;

  static T decodeEnum<T extends Enum>(
    Map<String, dynamic> map,
    String key,
    List<T> values,
    T fallback,
  ) {
    final dynamic raw = map[key];
    if (raw is T) return raw;
    if (raw == null) return fallback;
    final String name = raw.toString();
    for (final T value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static String? nullableEnumName(Map<String, dynamic> map, String key) {
    return nullableString(map, key);
  }

  /// Produces a deterministic JSON-friendly copy of a model map. This is used
  /// for backup/export and for equality-safe comparisons in tests.
  static Map<String, dynamic> stable(Map<String, dynamic> map) {
    return jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
  }
}
