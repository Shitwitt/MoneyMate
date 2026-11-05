import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const fallback = [
    'NotoSans',
    'NotoSansDevanagari',
    'NotoSansArabic',
    'NotoSansBengali',
    'NotoSansGurmukhi',
    'NotoSansGujarati',
    'NotoSansTamil',
    'NotoSansTelugu',
    'NotoSansThai',
    'NotoSansCJK',
  ];
  static const tabular = [FontFeature.tabularFigures()];
  static TextStyle ui(double size, FontWeight weight, Color color) => TextStyle(
    fontFamily: 'Quicksand',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.35,
    letterSpacing: size >= 24 ? -.5 : 0,
  ).copyWith(fontFamilyFallback: fallback);
  static TextStyle data(double size, FontWeight weight, Color color) =>
      TextStyle(
        fontFamily: 'Quicksand',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.45,
        fontFeatures: tabular,
      ).copyWith(fontFamilyFallback: fallback);
  static TextStyle display(double size, Color color) => TextStyle(
    fontFamily: 'Quicksand',
    fontFamilyFallback: fallback,
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.18,
    letterSpacing: -.6,
  );
  static TextTheme theme(Color ink, Color secondary) => TextTheme(
    displayLarge: display(48, ink),
    displayMedium: display(40, ink),
    displaySmall: display(34, ink),
    headlineLarge: display(36, ink),
    headlineMedium: display(30, ink),
    headlineSmall: display(26, ink),
    titleLarge: ui(22, FontWeight.w600, ink),
    titleMedium: ui(18, FontWeight.w600, ink),
    titleSmall: ui(16, FontWeight.w600, ink),
    bodyLarge: ui(16, FontWeight.w400, ink),
    bodyMedium: data(15, FontWeight.w400, ink),
    bodySmall: data(12, FontWeight.w400, secondary),
    labelLarge: data(13, FontWeight.w500, ink),
    labelMedium: data(12, FontWeight.w500, secondary),
    labelSmall: data(
      11,
      FontWeight.w600,
      secondary,
    ).copyWith(letterSpacing: .5),
  );
}
