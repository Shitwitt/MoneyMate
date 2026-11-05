import 'package:flutter/material.dart';

/// Warm coffee surfaces and peach controls shared by every feature screen.
abstract final class AppColors {
  static const primary = Color(0xFFFFB59A);
  static const primaryPressed = Color(0xFFE4A880);
  static const primaryLight = Color(0xFFFFE5D4);
  static const primaryInk = Color(0xFF633D29);
  static const ink = Color(0xFF2D211A);
  static const secondary = Color(0xFF705C4F);
  static const tertiary = Color(0xFF8B776A);
  static const outline = Color(0xFFE8D9CF);
  static const background = Color(0xFFFFF8F2);
  static const card = Color(0xFFFFFDF9);
  static const darkSurface = Color(0xFF1A100E);
  static const darkCard = Color(0xFF231A15);
  static const darkDivider = Color(0xFF514238);
  static const darkSecondary = Color(0xFFD9C4BA);
  static const darkAccent = primary;
  static const income = Color(0xFFA7C994);
  static const expense = Color(0xFFEEB5B8);
  static const transfer = Color(0xFFB7C9E5);
  static const warning = Color(0xFFE8CA87);
  static const incomeInk = Color(0xFF36582B);
  static const expenseInk = Color(0xFF8D343F);
  static const transferInk = Color(0xFF344F79);
  static const warningInk = Color(0xFF76530D);
  static const successBackground = Color(0xFFE2EDD9);
  static const errorBackground = Color(0xFFF5DDDF);
  static const warningBackground = Color(0xFFF5E9C9);
  static const infoBackground = Color(0xFFE2E9F4);
  static const chart = [
    primary,
    income,
    transfer,
    Color(0xFFD1BEE7),
    expense,
    warning,
    Color(0xFFB4D8CD),
  ];

  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color semantic(BuildContext context, String type) => switch (type) {
    'income' => dark(context) ? income : incomeInk,
    'expense' => dark(context) ? expense : expenseInk,
    'transfer' => dark(context) ? transfer : transferInk,
    _ => dark(context) ? darkAccent : primaryInk,
  };
}
