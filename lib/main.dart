import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/moneymate_app.dart';

/// Application entry point.
///
/// Phase 0 bootstrap only: no database, no async init. Later phases add
/// Drift database open, settings load, and recurring catch-up here.
void main() {
  runApp(const ProviderScope(child: MoneyMateApp()));
}
