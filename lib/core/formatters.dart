import 'package:intl/intl.dart';

import 'extensions.dart';

/// Date and day-header formatting helpers (money formatting lives on
/// [Money.format] and is integer-only).
class Formatters {
  /// e.g. `12 Oct 2026`.
  static String formatDate(DateTime date, {String locale = 'en'}) {
    return DateFormat.yMMMd(locale).format(date);
  }

  /// e.g. `October 2026` (app-bar month title).
  static String formatMonthTitle(DateTime date, {String locale = 'en'}) {
    return DateFormat.yMMMM(locale).format(date);
  }

  /// List group header: `Today`, `Yesterday`, or a formatted date.
  static String dayHeader(DateTime date, DateTime now, {String locale = 'en'}) {
    if (date.isSameDay(now)) {
      return 'Today';
    }
    if (date.isSameDay(now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return formatDate(date, locale: locale);
  }
}
