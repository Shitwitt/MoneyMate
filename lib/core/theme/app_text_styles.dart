import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  ];
  static const tabular = [FontFeature.tabularFigures()];
  static TextStyle ui(double size, FontWeight weight, Color color) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.35,
        letterSpacing: size >= 24 ? -.8 : -.15,
      ).copyWith(fontFamilyFallback: fallback);
  static TextStyle data(double size, FontWeight weight, Color color) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.45,
        fontFeatures: tabular,
      ).copyWith(fontFamilyFallback: fallback);
  static TextTheme theme(Color ink, Color secondary) => TextTheme(
    displayLarge: ui(36, FontWeight.w700, ink),
    displayMedium: ui(32, FontWeight.w700, ink),
    displaySmall: ui(32, FontWeight.w700, ink),
    headlineLarge: ui(28, FontWeight.w700, ink),
    headlineMedium: ui(24, FontWeight.w600, ink),
    headlineSmall: ui(24, FontWeight.w600, ink),
    titleLarge: ui(20, FontWeight.w600, ink),
    titleMedium: ui(18, FontWeight.w600, ink),
    titleSmall: ui(16, FontWeight.w600, ink),
    bodyLarge: ui(16, FontWeight.w400, ink),
    bodyMedium: data(14, FontWeight.w400, ink),
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
