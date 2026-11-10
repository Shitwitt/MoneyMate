/// Small, pure helpers shared across core and domain layers.
extension DateTimeX on DateTime {
  /// Start of the calendar day (00:00:00.000) in local time.
  DateTime get startOfDay => DateTime(year, month, day);

  /// True when both values fall on the same calendar day.
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
