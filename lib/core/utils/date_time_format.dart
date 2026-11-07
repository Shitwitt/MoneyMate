import 'package:intl/intl.dart';

/// Date and time labels used across the dashboard, ledger and forms.
///
/// All formatting goes through `intl` with an explicit locale so Hindi/German/
/// Spanish/French users see their own month names and AM/PM markers, while the
/// grouped headers (`Today`, `Yesterday`) stay localized through `AppStrings`.
class DateTimeFormat {
  const DateTimeFormat._();

  static final Map<String, DateFormat> _cache = <String, DateFormat>{};

  /// A [DateFormat] for [pattern] in [locale], cached.
  ///
  /// `intl` only ships data for the locales loaded into it — `initializeDateFormatting()`
  /// is awaited in `main()`. If a caller formats a date before that (a unit test,
  /// a locale intl has no data for) the plain English pattern is used instead of
  /// throwing `LocaleDataException`: a missing month name must never take down a
  /// screen full of the user's money.
  static DateFormat _pattern(String pattern, String locale) =>
      _cache.putIfAbsent('$pattern|$locale', () {
        try {
          return DateFormat(pattern, locale);
        } on LocaleDataException {
          return DateFormat(pattern);
        }
      });

  /// `07 Nov 2026` — the canonical ledger date.
  static String date(DateTime value, {String locale = 'en_IN'}) =>
      _pattern('dd MMM yyyy', locale).format(value);

  /// `07 Nov` — compact variant for dense rows.
  static String shortDate(DateTime value, {String locale = 'en_IN'}) =>
      _pattern('dd MMM', locale).format(value);

  /// `Nov 2026` — month section headers.
  static String monthYear(DateTime value, {String locale = 'en_IN'}) =>
      _pattern('MMM yyyy', locale).format(value);

  /// `Nov` — chart axis labels and month chips.
  static String monthShort(DateTime value, {String locale = 'en_IN'}) =>
      _pattern('MMM', locale).format(value);

  /// `Mon` — the weekly line chart's x axis.
  static String weekdayShort(DateTime value, {String locale = 'en_IN'}) =>
      _pattern('E', locale).format(value);

  /// `Mon, 02 Nov` — chart tooltip date line.
  static String weekdayDate(DateTime value, {String locale = 'en_IN'}) =>
      '${_pattern('E', locale).format(value)}, '
      '${_pattern('dd MMM', locale).format(value)}';

  /// `07:30 PM` — the time shown in a transaction subtitle.
  static String time(DateTime value, {String locale = 'en_IN'}) =>
      _pattern('hh:mm a', locale).format(value);

  /// `Nov 7, 2026 · 07:30 PM` — used by confirmations and receipts.
  static String dateTime(DateTime value, {String locale = 'en_IN'}) =>
      '${_pattern('dd MMM yyyy', locale).format(value)} · '
      '${_pattern('hh:mm a', locale).format(value)}';

  /// `Monday` / `Mon` — weekday names for headers.
  static String weekday(DateTime value, {String locale = 'en_IN'}) =>
      _pattern('EEEE', locale).format(value);

  /// `2026-11-07` — stable, sortable, used in backup file names.
  static String isoDay(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  /// Midday of [value] with the clock stripped — the grouping key for the
  /// ledger list.
  static DateTime dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Whether two timestamps fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole days between [value]'s date and [reference]'s date (negative for
  /// the past is not used; it always compares calendars).
  static int daysBetween(DateTime value, DateTime reference) {
    final DateTime a = dayOnly(value);
    final DateTime b = dayOnly(reference);
    return b.difference(a).inDays;
  }

  /// `Today` / `Yesterday` / `07 Nov 2026`.
  ///
  /// [labels] lets the caller inject localized strings; passing `null` keeps
  /// the English defaults so the function is usable from pure-Dart tests.
  static String relativeDay(
    DateTime value, {
    String locale = 'en_IN',
    DateTime? now,
    String? todayLabel,
    String? yesterdayLabel,
  }) {
    final int delta = daysBetween(value, now ?? DateTime.now());
    if (delta == 0) return todayLabel ?? 'Today';
    if (delta == 1) return yesterdayLabel ?? 'Yesterday';
    return date(value, locale: locale);
  }

  /// `07 Nov 2026` for any day, never `Today` (used in the edit form).
  static String absoluteDay(DateTime value, {String locale = 'en_IN'}) =>
      date(value, locale: locale);

  /// Greeting for the app bar: morning / afternoon / evening / night.
  static String greetingKey(DateTime now) {
    final int hour = now.hour;
    if (hour < 5) return 'greetingNight';
    if (hour < 12) return 'greetingMorning';
    if (hour < 17) return 'greetingAfternoon';
    if (hour < 21) return 'greetingEvening';
    return 'greetingNight';
  }

  /// Combines the date part of [date] with the time part of [time].
  static DateTime merge(DateTime date, DateTime time) => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
        time.second,
      );

  /// Axis label for one day of a chart window.
  ///
  /// * a single-week window shows weekday initials (`M`, `T`, `W`),
  /// * a month window shows the day number (`1`, `15`, `30`),
  /// * anything longer shows the day with its month (`07 Nov`).
  ///
  /// [start] and [end] describe the whole window, so every label in one chart
  /// is formatted the same way.
  static String dayAxisLabel(
    DateTime day,
    DateTime start,
    DateTime end, {
    String locale = 'en_IN',
  }) {
    final int span = end.difference(start).inDays + 1;
    if (span <= 7) {
      return _pattern('EEEEE', locale).format(day).toUpperCase();
    }
    if (span <= 31) return day.day.toString();
    return _pattern('dd MMM', locale).format(day);
  }

  /// `12:05` axis labels for the charts (24h, no AM/PM clutter).
  static String axisTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
