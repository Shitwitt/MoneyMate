/// Defensive readers shared by every model's `fromMap`.
///
/// Hive hands back `Map<dynamic, dynamic>` values, and a restored backup file
/// may contain `int` where we expect `double`, a `String` where we expect a
/// `bool`, or a missing key entirely (an older schema). These helpers make
/// deserialization total: they never throw, they always return a usable value.
library;

/// Reads a `String`, stringifying anything else so data is never lost.
String readString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Reads a nullable `String`; blank strings become `null`.
String? readNullableString(Object? value) {
  if (value == null) return null;
  final String text = value is String ? value : value.toString();
  return text.isEmpty ? null : text;
}

/// Reads a `double`, accepting `int`, `num` and numeric strings.
double readDouble(Object? value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value.isFinite ? value : fallback;
  if (value is num) {
    final double result = value.toDouble();
    return result.isFinite ? result : fallback;
  }
  final double? parsed = double.tryParse(value.toString());
  return (parsed != null && parsed.isFinite) ? parsed : fallback;
}

/// Reads a non-negative `double` (money can never be negative on disk).
double readAmount(Object? value, {double fallback = 0}) {
  final double result = readDouble(value, fallback: fallback);
  return result < 0 ? result.abs() : result;
}

/// Reads an `int`, accepting `num` and numeric strings.
int readInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

/// Reads a `bool`, accepting `0/1`, `'true'/'false'` and `'1'/'0'`.
bool readBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final String normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

/// Reads a `DateTime` from an ISO-8601 string or an epoch-millis number.
///
/// Falls back to [fallback] (defaults to now) when the value is missing or
/// unparseable, which keeps a corrupt record visible instead of crashing the
/// whole list.
DateTime readDateTime(Object? value, {DateTime? fallback}) {
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String && value.isNotEmpty) {
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
    final int? millis = int.tryParse(value);
    if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return fallback ?? DateTime.now();
}

/// Reads a nullable `DateTime`.
DateTime? readNullableDateTime(Object? value) {
  if (value == null) return null;
  if (value is String && value.isEmpty) return null;
  return readDateTime(value);
}

/// Serializes a `DateTime` as an ISO-8601 string (human readable in backups).
String writeDateTime(DateTime value) => value.toIso8601String();
