import 'package:uuid/uuid.dart';

/// Central id factory for every persisted record.
///
/// Ids are UUID v4 strings — collision-free across devices, which matters once
/// backups are exported on one phone and restored on another.
class IdGenerator {
  const IdGenerator._();

  static const Uuid _uuid = Uuid();

  /// A fresh UUID v4, e.g. `3f0c1f6e-...`.
  static String newId() => _uuid.v4();

  /// A prefixed id, handy in logs and when eyeballing a backup file.
  static String newPrefixedId(String prefix) => '$prefix-${_uuid.v4()}';

  /// True when [value] looks like a UUID (used to detect legacy ids).
  static bool isUuid(String value) =>
      RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(value);
}
