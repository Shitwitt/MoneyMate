import 'package:flutter/material.dart';
import '../models/models.dart';

ThemeData buildTheme(
  AppSettings settings,
  Brightness brightness, {
  ColorScheme? dynamicScheme,
}) {
  final dark = brightness == Brightness.dark;
  final black = dark && settings.theme == 'black';
  final scheme =
      (settings.dynamicColors && dynamicScheme != null
              ? dynamicScheme
              : ColorScheme.fromSeed(
                  seedColor: Color(settings.accent),
                  brightness: brightness,
                ))
          .copyWith(
            surface: black
                ? Colors.black
                : dark
                ? const Color(0xff121710)
                : const Color(0xfff7f8f2),
          );
  final base = ThemeData(
    fontFamily: 'NotoSans',
    fontFamilyFallback: const [
      'NotoSansDevanagari',
      'NotoSansArabic',
      'NotoSansBengali',
      'NotoSansGurmukhi',
      'NotoSansGujarati',
      'NotoSansTamil',
      'NotoSansTelugu',
    ],
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.8,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.7,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: black
          ? const Color(0xff131713)
          : dark
          ? const Color(0xff1c241a)
          : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: .45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 3,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      height: 78,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .45),
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
