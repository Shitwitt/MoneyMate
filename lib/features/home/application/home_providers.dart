import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App title shown in the app bar. Phase 0 placeholder; later phases
/// replace this with settings-backed providers.
final Provider<String> appTitleProvider = Provider<String>((ref) {
  return 'MoneyMate';
});
