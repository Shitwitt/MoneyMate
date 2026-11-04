import 'package:flutter/material.dart';

/// Tink's public brand palette. Semantic ink variants meet AA on light cards.
abstract final class AppColors {
  static const primary = Color(0xFF916CFF);
  static const primaryPressed = Color(0xFF7A55F0);
  static const primaryLight = Color(0xFFEDE7FF);
  static const primaryInk = Color(0xFF5530B0);
  static const ink = Color(0xFF0B0B0F);
  static const secondary = Color(0xFF5A5A66);
  static const tertiary = Color(0xFF8A8A96);
  static const outline = Color(0xFFECECF2);
  static const background = Color(0xFFF7F7FB);
  static const card = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF121218);
  static const darkCard = Color(0xFF1B1B23);
  static const darkDivider = Color(0xFF2A2A33);
  static const darkSecondary = Color(0xFFA5A5B2);
  static const darkAccent = Color(0xFFA78BFF);
  static const income = Color(0xFF12B76A);
  static const expense = Color(0xFFF04438);
  static const transfer = Color(0xFF2E90FA);
  static const warning = Color(0xFFF79009);
  static const incomeInk = Color(0xFF067647);
  static const expenseInk = Color(0xFFB42318);
  static const transferInk = Color(0xFF175CD3);
  static const warningInk = Color(0xFF93370D);
  static const successBackground = Color(0xFFE8F8F0);
  static const errorBackground = Color(0xFFFEECEB);
  static const warningBackground = Color(0xFFFFF6E6);
  static const infoBackground = Color(0xFFEAF3FF);
  static const chart = [primary, Color(0xFFB5A0EC), Color(0xFFCDC3E3), Color(0xFFA8B8D0), Color(0xFFC9C4CE), Color(0xFF8E91A9), Color(0xFFD8D3E0)];

  static bool dark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color semantic(BuildContext context, String type) => switch(type) {
    'income' => dark(context) ? const Color(0xFF34D399) : incomeInk,
    'expense' => dark(context) ? const Color(0xFFF87171) : expenseInk,
    'transfer' => dark(context) ? const Color(0xFF60A5FA) : transferInk,
    _ => dark(context) ? darkAccent : primaryInk,
  };
}
