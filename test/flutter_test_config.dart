import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Match main()'s fully offline locale bootstrap in tests that mount individual
/// feature screens without invoking the application entry point.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
