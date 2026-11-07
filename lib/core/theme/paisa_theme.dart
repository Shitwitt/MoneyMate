import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'paisa_colors.dart';
import 'paisa_typography.dart';
import 'seed_color.dart';
import 'theme_preference.dart';

/// The Paisa Material 3 (Material You) design system.
///
/// Two colour sources feed the same token pipeline:
///  * **Dynamic Color** — the wallpaper-derived scheme from Android 12+.
///  * **Seed Color** — one of twelve vibrant Material seeds, used everywhere
///    else (older Android, iOS, desktop, web) or when the user turns dynamic
///    colour off.
///
/// Four theme modes are supported: [ThemePreference.system],
/// [ThemePreference.light], [ThemePreference.dark] and
/// [ThemePreference.amoled] (pitch black `#000000` scaffold & surfaces).
///
/// Every card, sheet and dialog is a 24dp rounded, zero-elevation tonal
/// surface — no grey drop shadows, only Material 3 tonal containers.
class PaisaTheme {
  const PaisaTheme._();

  // ---------------------------------------------------------------------
  // Geometry tokens
  // ---------------------------------------------------------------------

  /// Corner radius for cards, dialogs and every rounded surface.
  static const double cardRadius = 24;

  /// Corner radius for modal bottom sheets (slightly larger, they are full
  /// width).
  static const double sheetRadius = 28;

  /// Corner radius for buttons and text fields.
  static const double controlRadius = 18;

  /// Corner radius for chips and small pills.
  static const double chipRadius = 12;

  /// Corner radius for snack bars.
  static const double snackBarRadius = 16;

  /// Standard page padding.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16);

  /// Zero elevation everywhere — Paisa never uses drop shadows.
  static const double elevation = 0;

  // ---------------------------------------------------------------------
  // Colour schemes
  // ---------------------------------------------------------------------

  /// Builds a Material 3 scheme from one of the twelve seed colours.
  static ColorScheme seedScheme({
    required SeedColor seed,
    required Brightness brightness,
  }) {
    return ColorScheme.fromSeed(
      seedColor: Color(seed.value),
      brightness: brightness,
    );
  }

  /// Pitch black transformation of a dark scheme.
  ///
  /// Chromatic roles (primary, secondary, tertiary and their containers) are
  /// preserved so accents still pop, while every surface role collapses to
  /// (near) `#000000`. Containers carry a 5–13% tint of the primary so cards
  /// remain distinguishable from the scaffold without ever glowing.
  static ColorScheme amoledScheme(ColorScheme base) {
    const Color black = Color(0xFF000000);
    Color tint(double amount) => Color.alphaBlend(
          base.primary.withAlpha((255 * amount).round()),
          black,
        );

    return base.copyWith(
      brightness: Brightness.dark,
      surface: black,
      surfaceTint: black,
      surfaceContainerLowest: black,
      surfaceContainerLow: tint(0.05),
      surfaceContainer: tint(0.07),
      surfaceContainerHigh: tint(0.095),
      surfaceContainerHighest: tint(0.12),
      onSurface: const Color(0xFFEDEDED),
      onSurfaceVariant: const Color(0xFFA9B4B1),
      outline: tint(0.30),
      outlineVariant: tint(0.14),
      shadow: black,
      scrim: black,
      inverseSurface: const Color(0xFFEDEDED),
      onInverseSurface: const Color(0xFF151515),
    );
  }

  /// True when a dynamic scheme has no usable chroma (wallpaper is greyscale
  /// and the user picked the monochrome variant). We then keep Paisa's seed
  /// palette so the app does not turn into a grey blob.
  static bool _isMonochrome(ColorScheme scheme) {
    final HSLColor hsl = HSLColor.fromColor(scheme.primary);
    return hsl.saturation < 0.05;
  }

  // ---------------------------------------------------------------------
  // Theme builders
  // ---------------------------------------------------------------------

  /// Light theme.
  ///
  /// Pass [scheme] to use a dynamic colour scheme, or [seedColor] to derive
  /// one. If neither is supplied the signature Teal seed is used.
  static ThemeData light({ColorScheme? scheme, SeedColor? seedColor}) {
    final ColorScheme resolved = scheme ??
        seedScheme(
          seed: seedColor ?? SeedColor.defaultSeed,
          brightness: Brightness.light,
        );
    return _build(
      scheme: resolved,
      brightness: Brightness.light,
      amoled: false,
    );
  }

  /// Dark theme.
  ///
  /// Set [amoled] for the pitch black variant.
  static ThemeData dark({
    ColorScheme? scheme,
    SeedColor? seedColor,
    bool amoled = false,
  }) {
    ColorScheme resolved = scheme ??
        seedScheme(
          seed: seedColor ?? SeedColor.defaultSeed,
          brightness: Brightness.dark,
        );
    if (resolved.brightness != Brightness.dark) {
      resolved = seedScheme(
        seed: seedColor ?? SeedColor.defaultSeed,
        brightness: Brightness.dark,
      );
    }
    if (amoled) {
      resolved = amoledScheme(resolved);
    }
    return _build(
      scheme: resolved,
      brightness: Brightness.dark,
      amoled: amoled,
    );
  }

  /// Builds both themes for the current [settings], optionally seeding from the
  /// platform's dynamic colour schemes.
  ///
  /// Returns a record `(light, dark)` so a single call can feed
  /// `MaterialApp.theme` and `MaterialApp.darkTheme` consistently.
  static (ThemeData, ThemeData) resolve({
    required ThemeSettings settings,
    ColorScheme? dynamicLight,
    ColorScheme? dynamicDark,
  }) {
    ColorScheme? lightScheme;
    ColorScheme? darkScheme;

    if (settings.useDynamicColor) {
      if (dynamicLight != null && !_isMonochrome(dynamicLight)) {
        lightScheme = dynamicLight;
      }
      if (dynamicDark != null && !_isMonochrome(dynamicDark)) {
        darkScheme = dynamicDark;
      }
    }

    return (
      light(scheme: lightScheme, seedColor: settings.seed),
      dark(
        scheme: darkScheme,
        seedColor: settings.seed,
        amoled: settings.preference.isAmoled,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Component theming
  // ---------------------------------------------------------------------

  static ThemeData _build({
    required ColorScheme scheme,
    required Brightness brightness,
    required bool amoled,
  }) {
    final bool isDark = brightness == Brightness.dark;

    // Tonal surface used by cards — Material 3's "low" container, which is
    // already pure black in AMOLED mode.
    final Color cardColor = scheme.surfaceContainerLow;
    final Color dialogColor = scheme.surfaceContainerHigh;
    final Color sheetColor = isDark ? scheme.surfaceContainer : scheme.surfaceContainerLow;
    final Color fieldFill =
        isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow;

    final PaisaColors paisaColors = (isDark ? PaisaColors.dark() : PaisaColors.light())
        .copyWith(
      shadow: amoled ? const Color(0x00000000) : null,
      outlineMuted: amoled
          ? Color.alphaBlend(
              scheme.primary.withAlpha(26),
              const Color(0xFF000000),
            )
          : null,
      chartGrid: amoled
          ? Color.alphaBlend(
              scheme.primary.withAlpha(31),
              const Color(0xFF000000),
            )
          : null,
    );

    final Typography typography = Typography.material2021(
      platform: defaultTargetPlatform,
    );
    final TextTheme textTheme = PaisaTypography.build(
      isDark ? typography.white : typography.black,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
    );
    final RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
    );
    final RoundedRectangleBorder sheetShape = RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(sheetRadius),
      ),
    );

    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: scheme.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      primaryColor: scheme.primary,
      canvasColor: scheme.surface,
      cardColor: cardColor,
      dividerColor: scheme.outlineVariant,
      scaffoldBackgroundColor: scheme.surface,
      // Flutter only enables the Android 12 sparkle splash on Android, so we
      // mirror that gate instead of forcing it on platforms where it looks
      // out of place (and is slower).
      splashFactory: (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? InkSparkle.splashFactory
          : InkRipple.splashFactory,
      splashColor: scheme.primary.withAlpha(20),
      highlightColor: scheme.primary.withAlpha(12),
      hoverColor: scheme.primary.withAlpha(12),
      focusColor: scheme.primary.withAlpha(20),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
      primaryIconTheme: IconThemeData(color: scheme.onPrimary),
      extensions: <ThemeExtension<dynamic>>[paisaColors],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ---------------------------------------------------------------
      // App bar / shell
      // ---------------------------------------------------------------
      appBarTheme: AppBarTheme(
        elevation: elevation,
        scrolledUnderElevation: elevation,
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        shadowColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        selectedItemColor: scheme.onSecondaryContainer,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
        type: BottomNavigationBarType.fixed,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: scheme.onSecondaryContainer, size: 24);
            }
            return IconThemeData(color: scheme.onSurfaceVariant, size: 24);
          },
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) {
            final bool selected = states.contains(WidgetState.selected);
            return (textTheme.labelMedium ?? const TextStyle()).copyWith(
              color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            );
          },
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        indicatorColor: scheme.secondaryContainer,
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // ---------------------------------------------------------------
      // Cards, dialogs, sheets — 24dp rounded tonal surfaces, no shadows
      // ---------------------------------------------------------------
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: elevation,
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: cardShape,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: dialogColor,
        surfaceTintColor: Colors.transparent,
        elevation: elevation,
        shadowColor: Colors.transparent,
        shape: dialogShape,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetColor,
        modalBackgroundColor: sheetColor,
        surfaceTintColor: Colors.transparent,
        elevation: elevation,
        modalElevation: elevation,
        shadowColor: Colors.transparent,
        shape: sheetShape,
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        // Width/height deliberately left to the Material default (one third of
        // the sheet width, 4dp tall): a hard-coded size overflows on short
        // screens and on tablets.
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: elevation,
        backgroundColor: scheme.inverseSurface,
        actionTextColor: scheme.inversePrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(snackBarRadius),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: paisaColors.shadow,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll<Color>(scheme.surfaceContainerHigh),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          elevation: const WidgetStatePropertyAll<double>(3),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(chipRadius),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 500),
      ),

      // ---------------------------------------------------------------
      // Buttons
      // ---------------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: elevation,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation,
          shadowColor: Colors.transparent,
          backgroundColor: scheme.surfaceContainerHighest,
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Foreground colour is intentionally not forced here: AppBar actions and
      // list tiles each supply their own IconTheme, and pinning a colour in the
      // theme would override them everywhere.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          highlightColor: scheme.primary.withAlpha(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: elevation,
        focusElevation: elevation,
        hoverElevation: 1,
        highlightElevation: elevation,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        splashColor: scheme.primary.withAlpha(33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // `SegmentedButton` owns a private `_SegmentedButtonDefaultsM3` and
      // throws if a `SegmentedButtonThemeData` is supplied without a style, so
      // it is styled at the call site through `SegmentedButton.styleFrom`
      // (see `PaisaTheme.segmentedButtonStyle`).

      // ---------------------------------------------------------------
      // Inputs
      // ---------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withAlpha(180),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fieldFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll<Color>(scheme.surfaceContainerHigh),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          elevation: const WidgetStatePropertyAll<double>(3),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        disabledColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
          side: BorderSide.none,
        ),
        side: BorderSide.none,
        showCheckmark: false,
        pressElevation: 0,
        elevation: 0,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        minVerticalPadding: 10,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ---------------------------------------------------------------
      // Controls
      // ---------------------------------------------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return scheme.outline;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return scheme.surfaceContainerHighest;
          },
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.transparent;
            }
            return scheme.outlineVariant;
          },
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: BorderSide(color: scheme.outline),
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return Colors.transparent;
          },
        ),
        checkColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return scheme.outline;
          },
        ),
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withAlpha(24),
        activeTickMarkColor: scheme.onPrimary,
        inactiveTickMarkColor: scheme.onSurfaceVariant,
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimary,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll<double>(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll<Color>(
          scheme.primary.withAlpha(60),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withAlpha(60),
        selectionHandleColor: scheme.primary,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: dialogColor,
        surfaceTintColor: Colors.transparent,
        elevation: elevation,
        shadowColor: Colors.transparent,
        shape: dialogShape,
        headerBackgroundColor: scheme.primaryContainer,
        headerForegroundColor: scheme.onPrimaryContainer,
        rangePickerBackgroundColor: scheme.surfaceContainerHigh,
        dayShape: const WidgetStatePropertyAll<OutlinedBorder>(
          CircleBorder(),
        ),
        todayForegroundColor: WidgetStatePropertyAll<Color>(scheme.primary),
        todayBorder: BorderSide(color: scheme.primary),
        dividerColor: scheme.outlineVariant,
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: dialogColor,
        elevation: elevation,
        shape: dialogShape,
        hourMinuteColor: scheme.surfaceContainerHighest,
        hourMinuteTextColor: scheme.onSurface,
        dayPeriodColor: scheme.surfaceContainerHighest,
        dayPeriodTextColor: scheme.onSurfaceVariant,
        dialBackgroundColor: scheme.surfaceContainerHighest,
        dialHandColor: scheme.primary,
        dialTextColor: scheme.onSurface,
        entryModeIconColor: scheme.onSurfaceVariant,
        helpTextStyle: textTheme.labelLarge,
        hourMinuteTextStyle: textTheme.displayMedium,
        dayPeriodTextStyle: textTheme.labelLarge,
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.tertiary,
        textColor: scheme.onTertiary,
        textStyle: textTheme.labelSmall?.copyWith(
          color: scheme.onTertiary,
          fontWeight: FontWeight.w600,
        ),
      ),

      // `TabBar` also asserts on a `TabBarThemeData` whose `data` is null, so the
      // theme is intentionally left to the Material defaults; Paisa's tabs are
      // styled with `PaisaTheme.tabBarData` at the call site.

      bannerTheme: MaterialBannerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        elevation: elevation,
        shadowColor: Colors.transparent,
      ),
    );
  }

  /// Convenience helper for the (rare) places that need the theme's
  /// [PaisaColors] tokens outside of a [BuildContext].
  static PaisaColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? PaisaColors.dark() : PaisaColors.light();

  /// The pill style used by Paisa's `SegmentedButton`s (expense / income /
  /// transfer switchers and filter bars).
  ///
  /// Applied at the call site because [ThemeData.segmentedButtonTheme] cannot
  /// hold a null style:
  /// ```dart
  /// SegmentedButton<TransactionType>(
  ///   style: PaisaTheme.segmentedButtonStyle(context),
  ///   ...
  /// )
  /// ```
  static ButtonStyle segmentedButtonStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return ButtonStyle(
      elevation: const WidgetStatePropertyAll<double>(elevation),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? scheme.secondaryContainer
            : Colors.transparent,
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? scheme.onSecondaryContainer
            : scheme.onSurfaceVariant,
      ),
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        theme.textTheme.labelLarge?.copyWith(fontSize: 13),
      ),
      side: WidgetStatePropertyAll<BorderSide>(
        BorderSide(color: scheme.outlineVariant),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// The tab bar look used across the app (charts, debts, settings).
  ///
  /// Paisa uses Material 3's primary default indicator, so this only swaps the
  /// fonts and removes the divider — no explicit `TabBarThemeData` is installed
  /// because [ThemeData.tabBarTheme] cannot hold a null `data`.
  static Widget tabBar({
    required BuildContext context,
    required List<Widget> tabs,
    TabController? controller,
    bool isScrollable = false,
    ValueChanged<int>? onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    return TabBar(
      controller: controller,
      isScrollable: isScrollable,
      onTap: onTap,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: theme.colorScheme.primary,
      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
      labelStyle: theme.textTheme.labelLarge,
      unselectedLabelStyle:
          theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      overlayColor:
          WidgetStatePropertyAll<Color>(theme.colorScheme.primary.withAlpha(16)),
      tabs: tabs,
    );
  }
}

/// Resolves the active [ThemeSettings] into a light/dark [ThemeData] pair,
/// layering the platform's dynamic colour scheme underneath when it is
/// available and enabled.
///
/// ```dart
/// PaisaThemeBuilder(
///   settings: settings,
///   builder: (context, light, dark) => MaterialApp(
///     theme: light,
///     darkTheme: dark,
///     themeMode: settings.preference.materialThemeMode,
///     builder: (context, child) => DynamicColorBuilder(...),
///   ),
/// )
/// ```
class PaisaThemeBuilder extends StatelessWidget {
  const PaisaThemeBuilder({
    super.key,
    required this.settings,
    required this.builder,
  });

  /// The user's persisted theme configuration.
  final ThemeSettings settings;

  /// Receives the resolved (light, dark) pair.
  final Widget Function(BuildContext context, ThemeData light, ThemeData dark)
      builder;

  @override
  Widget build(BuildContext context) {
    if (!settings.useDynamicColor || !_supportsDynamicColor) {
      final (ThemeData light, ThemeData dark) = PaisaTheme.resolve(
        settings: settings,
      );
      return builder(context, light, dark);
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final (ThemeData light, ThemeData dark) = PaisaTheme.resolve(
          settings: settings,
          dynamicLight: lightDynamic,
          dynamicDark: darkDynamic,
        );
        return builder(context, light, dark);
      },
    );
  }

  /// Dynamic colour is an Android 12+ (API 31) feature; the plugin returns
  /// `null` core palettes on every other platform, in which case
  /// [PaisaTheme.resolve] falls back to the seed palette automatically. We only
  /// avoid subscribing to the platform channel where it can never answer.
  static bool get _supportsDynamicColor =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
