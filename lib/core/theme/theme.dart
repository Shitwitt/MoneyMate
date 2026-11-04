import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

ThemeData tinkTheme(AppSettings settings, Brightness brightness, {ColorScheme? dynamicScheme}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  final dark = brightness == Brightness.dark;
  final accent = settings.accent == 0xff557c36 ? AppColors.primary : Color(settings.accent);
  final background = dark ? AppColors.darkSurface : AppColors.background;
  final card = dark ? AppColors.darkCard : AppColors.card;
  final ink = dark ? Colors.white : AppColors.ink;
  final secondary = dark ? AppColors.darkSecondary : AppColors.secondary;
  final outline = dark ? AppColors.darkDivider : AppColors.outline;
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness).copyWith(
    primary: accent, onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xff302544) : AppColors.primaryLight,
    onPrimaryContainer: dark ? const Color(0xffE4D8FF) : AppColors.primaryInk,
    secondary: dark ? AppColors.darkAccent : AppColors.primaryInk,
    surface: card, onSurface: ink, onSurfaceVariant: secondary,
    surfaceContainerLowest: background, surfaceContainerLow: card,
    surfaceContainer: dark ? const Color(0xff24242e) : const Color(0xffF0F0F6),
    surfaceContainerHigh: dark ? const Color(0xff262630) : const Color(0xffF1F1F7),
    surfaceContainerHighest: dark ? const Color(0xff2B2B36) : const Color(0xffECECF4),
    outline: dark ? AppColors.darkSecondary : const Color(0xff777783), outlineVariant: outline,
    error: dark ? const Color(0xffF87171) : AppColors.expenseInk,
    errorContainer: dark ? const Color(0xff42202a) : AppColors.errorBackground,
  );
  final text = AppTextStyles.theme(ink, secondary);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness,
    fontFamily: 'Poppins', fontFamilyFallback: AppTextStyles.fallback, textTheme: text);
  return base.copyWith(
    scaffoldBackgroundColor: background,
    splashFactory: InkRipple.splashFactory,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: TinkPageTransitionsBuilder(), TargetPlatform.iOS: TinkPageTransitionsBuilder(),
      TargetPlatform.macOS: TinkPageTransitionsBuilder(), TargetPlatform.windows: TinkPageTransitionsBuilder(),
      TargetPlatform.linux: TinkPageTransitionsBuilder(),
    }),
    cardTheme: CardThemeData(color: card, surfaceTintColor: Colors.transparent, elevation: 0,
      margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder,
        side: BorderSide(color: outline.withValues(alpha: dark ? .8 : .65)))),
    appBarTheme: AppBarTheme(backgroundColor: background, foregroundColor: ink, surfaceTintColor: Colors.transparent,
      centerTitle: false, titleSpacing: AppSpacing.screen, elevation: 0, scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge, toolbarHeight: 72,
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: dark ? const Color(0xff23232d) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: text.bodyMedium?.copyWith(color: secondary), hintStyle: text.bodyMedium?.copyWith(color: secondary),
      border: const OutlineInputBorder(borderRadius: AppRadius.buttonBorder),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.buttonBorder, borderSide: BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.buttonBorder, borderSide: BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: AppRadius.buttonBorder, borderSide: BorderSide(color: scheme.error))),
    filledButtonTheme: FilledButtonThemeData(style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, AppSpacing.button)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder)),
      // 20sp bold is large text: white/violet exceeds WCAG AA's 3:1 threshold.
      textStyle: WidgetStatePropertyAll(AppTextStyles.ui(20, FontWeight.w700, Colors.white)),
      backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? scheme.surfaceContainerHighest : states.contains(WidgetState.pressed) ? AppColors.primaryPressed : accent),
      foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? secondary : Colors.white),
      overlayColor: const WidgetStatePropertyAll(Color(0x15000000)), elevation: const WidgetStatePropertyAll(0),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 54), foregroundColor: ink, backgroundColor: card,
      side: BorderSide(color: outline), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: text.titleSmall, shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
      minimumSize: const Size(48,48), foregroundColor: dark ? AppColors.darkAccent : AppColors.primaryInk, textStyle: text.labelLarge)),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(48,48), foregroundColor: secondary)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: accent, foregroundColor: Colors.white,
      elevation: 2, shape: const CircleBorder(), sizeConstraints: const BoxConstraints.tightFor(width: 60,height: 60)),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: card, surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer, height: AppSpacing.nav, elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(size: 23, color: states.contains(WidgetState.selected) ? accent : secondary)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => text.labelSmall!.copyWith(
        fontSize: 11, letterSpacing: 0, color: states.contains(WidgetState.selected) ? (dark ? AppColors.darkAccent : AppColors.primaryInk) : secondary))),
    navigationRailTheme: NavigationRailThemeData(backgroundColor: card, indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: accent), unselectedIconTheme: IconThemeData(color: secondary),
      selectedLabelTextStyle: text.labelMedium?.copyWith(color: dark ? AppColors.darkAccent : AppColors.primaryInk)),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: card, surfaceTintColor: Colors.transparent,
      dragHandleColor: outline, showDragHandle: true, shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder)),
    dialogTheme: DialogThemeData(backgroundColor: card, surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder), titleTextStyle: text.titleLarge),
    dividerTheme: DividerThemeData(color: outline, space: 1, thickness: 1),
    listTileTheme: ListTileThemeData(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      titleTextStyle: text.titleSmall, subtitleTextStyle: text.bodySmall,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder), iconColor: secondary),
    chipTheme: base.chipTheme.copyWith(backgroundColor: card, selectedColor: scheme.primaryContainer,
      labelStyle: text.labelLarge?.copyWith(color: ink), side: BorderSide(color: outline),
      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(
      minimumSize: const Size(48,48), selectedBackgroundColor: scheme.primaryContainer,
      selectedForegroundColor: scheme.onPrimaryContainer, textStyle: text.labelLarge,
      side: BorderSide(color: outline), shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder))),
    switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : secondary),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : scheme.surfaceContainerHighest)),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accent, linearTrackColor: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
    snackBarTheme: SnackBarThemeData(backgroundColor: dark ? const Color(0xff333340) : AppColors.ink,
      contentTextStyle: AppTextStyles.data(14, FontWeight.w500, Colors.white), behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder)),
    tooltipTheme: TooltipThemeData(textStyle: AppTextStyles.data(12, FontWeight.w500, Colors.white), decoration: BoxDecoration(
      color: AppColors.darkCard, borderRadius: BorderRadius.circular(10))),
  );
}

class TinkPageTransitionsBuilder extends PageTransitionsBuilder {
  const TinkPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInOut);
    return FadeTransition(opacity: curved, child: SlideTransition(
      position: Tween(begin: const Offset(0,.025),end: Offset.zero).animate(curved), child: child));
  }
}
