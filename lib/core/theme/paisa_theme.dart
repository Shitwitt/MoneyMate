import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The four theme modes exposed by Paisa.
enum PaisaThemeMode {
  system,
  light,
  dark,
  amoled,
}

/// A named, user-selectable Material seed color.
@immutable
class PaisaSeedColor {
  const PaisaSeedColor({
    required this.name,
    required this.color,
  });

  final String name;
  final Color color;

  int get value => color.value;

  String get hexLabel => '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';

  @override
  bool operator ==(Object other) {
    return other is PaisaSeedColor && other.name == name && other.value == value;
  }

  @override
  int get hashCode => Object.hash(name, value);

  @override
  String toString() => 'PaisaSeedColor($name, $hexLabel)';
}

/// Twelve vibrant Material seed colors used when Dynamic Color is unavailable
/// or disabled by the user.
abstract final class PaisaSeedPalette {
  static const PaisaSeedColor defaultColor = PaisaSeedColor(
    name: 'Paisa Peach',
    color: Color(0xFFFBB69D),
  );

  static const List<PaisaSeedColor> colors = <PaisaSeedColor>[
    defaultColor,
    PaisaSeedColor(name: 'Coral', color: Color(0xFFFF6B6B)),
    PaisaSeedColor(name: 'Tangerine', color: Color(0xFFFF8A65)),
    PaisaSeedColor(name: 'Amber', color: Color(0xFFFFCA28)),
    PaisaSeedColor(name: 'Green', color: Color(0xFF66BB6A)),
    PaisaSeedColor(name: 'Teal', color: Color(0xFF26A69A)),
    PaisaSeedColor(name: 'Sky', color: Color(0xFF29B6F6)),
    PaisaSeedColor(name: 'Indigo', color: Color(0xFF5C6BC0)),
    PaisaSeedColor(name: 'Violet', color: Color(0xFF7E57C2)),
    PaisaSeedColor(name: 'Pink', color: Color(0xFFEC407A)),
    PaisaSeedColor(name: 'Brown', color: Color(0xFF8D6E63)),
    PaisaSeedColor(name: 'Blue Grey', color: Color(0xFF78909C)),
  ];

  static PaisaSeedColor fromValue(int? value) {
    if (value == null) return defaultColor;
    for (final PaisaSeedColor item in colors) {
      if (item.value == value) return item;
    }
    return PaisaSeedColor(name: 'Custom', color: Color(value));
  }

  static PaisaSeedColor fromColor(Color color) {
    for (final PaisaSeedColor item in colors) {
      if (item.value == color.value) return item;
    }
    return PaisaSeedColor(name: 'Custom', color: color);
  }
}

extension PaisaThemeModeX on PaisaThemeMode {
  String get label {
    switch (this) {
      case PaisaThemeMode.system:
        return 'System';
      case PaisaThemeMode.light:
        return 'Light';
      case PaisaThemeMode.dark:
        return 'Dark';
      case PaisaThemeMode.amoled:
        return 'AMOLED Pitch Black';
    }
  }

  ThemeMode get flutterThemeMode {
    switch (this) {
      case PaisaThemeMode.system:
        return ThemeMode.system;
      case PaisaThemeMode.light:
        return ThemeMode.light;
      case PaisaThemeMode.dark:
      case PaisaThemeMode.amoled:
        return ThemeMode.dark;
    }
  }

  bool get isAmoled => this == PaisaThemeMode.amoled;
}

/// Material 3 theme engine.
///
/// It supports Android 12+ Dynamic Color through [DynamicColorBuilder], falls
/// back to a user-selected seed palette, and persists all choices in
/// `SharedPreferences`. No code generation or platform channels are required.
class PaisaThemeEngine extends ChangeNotifier {
  /// Offline-safe font stack. Runtime font fetching is disabled so the app
  /// never needs the INTERNET permission; Outfit is used when the asset is
  /// bundled, and the platform sans-serif font is used otherwise.
  static const List<String> fontFallbacks = <String>[
    'Outfit',
    'Roboto',
    'Noto Sans',
    'sans-serif',
  ];

  static bool _fontsConfigured = false;

  static void ensureOfflineFonts() {
    if (_fontsConfigured) return;
    GoogleFonts.config.allowRuntimeFetching = false;
    _fontsConfigured = true;
  }

  PaisaThemeEngine({
    PaisaThemeMode themeMode = PaisaThemeMode.system,
    Color? seedColor,
    bool useDynamicColor = true,
  })  : _themeMode = themeMode,
        _seedColor = seedColor ?? PaisaSeedPalette.defaultColor.color,
        _useDynamicColor = useDynamicColor;

  static const String _themeModeKey = 'paisa.theme.mode';
  static const String _seedColorKey = 'paisa.theme.seed';
  static const String _dynamicColorKey = 'paisa.theme.dynamic';

  PaisaThemeMode _themeMode;
  Color _seedColor;
  bool _useDynamicColor;
  bool _loaded = false;

  PaisaThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  PaisaSeedColor get seedPaletteEntry => PaisaSeedPalette.fromColor(_seedColor);
  bool get useDynamicColor => _useDynamicColor;
  bool get isLoaded => _loaded;
  ThemeMode get flutterThemeMode => _themeMode.flutterThemeMode;
  bool get isAmoled => _themeMode.isAmoled;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedMode = prefs.getString(_themeModeKey);
    final int? savedSeed = prefs.getInt(_seedColorKey);
    final bool? savedDynamic = prefs.getBool(_dynamicColorKey);

    _themeMode = PaisaThemeMode.values.firstWhere(
      (PaisaThemeMode mode) => mode.name == savedMode,
      orElse: () => PaisaThemeMode.system,
    );
    _seedColor = savedSeed == null
        ? PaisaSeedPalette.defaultColor.color
        : Color(savedSeed);
    _useDynamicColor = savedDynamic ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(PaisaThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setSeedColor(Color color) async {
    if (_seedColor.value == color.value) return;
    _seedColor = color;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.value);
  }

  Future<void> setUseDynamicColor(bool value) async {
    if (_useDynamicColor == value) return;
    _useDynamicColor = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicColorKey, value);
  }

  Future<void> reset() async {
    _themeMode = PaisaThemeMode.system;
    _seedColor = PaisaSeedPalette.defaultColor.color;
    _useDynamicColor = true;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey);
    await prefs.remove(_seedColorKey);
    await prefs.remove(_dynamicColorKey);
  }

  ThemeData buildLightTheme(ColorScheme? dynamicLight) {
    final ColorScheme scheme = _useDynamicColor && dynamicLight != null
        ? dynamicLight
        : ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.light,
          );
    return _themeFromScheme(scheme);
  }

  ThemeData buildDarkTheme(ColorScheme? dynamicDark) {
    final ColorScheme base = _useDynamicColor && dynamicDark != null
        ? dynamicDark
        : ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.dark,
          );
    final ColorScheme scheme = isAmoled ? _pitchBlackScheme(base) : base;
    return _themeFromScheme(scheme);
  }

  ColorScheme _pitchBlackScheme(ColorScheme base) {
    const Color black = Color(0xFF000000);
    const Color lowest = Color(0xFF050505);
    const Color low = Color(0xFF0A0A0A);
    const Color container = Color(0xFF101010);
    const Color high = Color(0xFF161616);
    const Color highest = Color(0xFF1D1D1D);

    return ColorScheme(
      brightness: Brightness.dark,
      primary: base.primary,
      onPrimary: base.onPrimary,
      primaryContainer: base.primaryContainer,
      onPrimaryContainer: base.onPrimaryContainer,
      secondary: base.secondary,
      onSecondary: base.onSecondary,
      secondaryContainer: base.secondaryContainer,
      onSecondaryContainer: base.onSecondaryContainer,
      tertiary: base.tertiary,
      onTertiary: base.onTertiary,
      tertiaryContainer: base.tertiaryContainer,
      onTertiaryContainer: base.onTertiaryContainer,
      error: base.error,
      onError: base.onError,
      errorContainer: base.errorContainer,
      onErrorContainer: base.onErrorContainer,
      background: black,
      onBackground: base.onSurface,
      surface: black,
      onSurface: base.onSurface,
      surfaceVariant: base.surfaceVariant,
      onSurfaceVariant: base.onSurfaceVariant,
      outline: base.outline,
      outlineVariant: base.outlineVariant,
      shadow: Colors.transparent,
      scrim: black,
      inverseSurface: base.inverseSurface,
      onInverseSurface: base.onInverseSurface,
      inversePrimary: base.inversePrimary,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: lowest,
      surfaceContainerLow: low,
      surfaceContainer: container,
      surfaceContainerHigh: high,
      surfaceContainerHighest: highest,
    );
  }

  ThemeData _themeFromScheme(ColorScheme scheme) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      cardColor: scheme.surfaceContainerLow,
      dialogBackgroundColor: scheme.surfaceContainerHighest,
      disabledColor: scheme.onSurface.withOpacity(0.38),
      hintColor: scheme.onSurfaceVariant,
      dividerColor: scheme.outlineVariant,
      focusColor: scheme.primary.withOpacity(0.12),
      hoverColor: scheme.primary.withOpacity(0.08),
      highlightColor: scheme.primary.withOpacity(0.10),
      splashColor: scheme.primary.withOpacity(0.12),
      shadowColor: Colors.transparent,
      primaryColor: scheme.primary,
      indicatorColor: scheme.primary,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    ensureOfflineFonts();
    final TextTheme outfitTextTheme = GoogleFonts.outfitTextTheme(base.textTheme);
    final TextTheme textTheme = outfitTextTheme.apply(
      fontFamilyFallback: fontFallbacks,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    const RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    final RoundedRectangleBorder sheetShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    );
    final RoundedRectangleBorder fieldShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );

    final ButtonStyle primaryButtonStyle = ButtonStyle(
      elevation: MaterialStateProperty.all<double>(0),
      shadowColor: MaterialStateProperty.all<Color>(Colors.transparent),
      surfaceTintColor: MaterialStateProperty.all<Color>(Colors.transparent),
      backgroundColor: MaterialStateProperty.all<Color>(scheme.primary),
      foregroundColor: MaterialStateProperty.all<Color>(scheme.onPrimary),
      shape: MaterialStateProperty.all<OutlinedBorder>(const StadiumBorder()),
      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      textStyle: MaterialStateProperty.all<TextStyle>(
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    final ButtonStyle tonalButtonStyle = ButtonStyle(
      elevation: MaterialStateProperty.all<double>(0),
      shadowColor: MaterialStateProperty.all<Color>(Colors.transparent),
      surfaceTintColor: MaterialStateProperty.all<Color>(Colors.transparent),
      backgroundColor: MaterialStateProperty.all<Color>(scheme.secondaryContainer),
      foregroundColor: MaterialStateProperty.all<Color>(scheme.onSecondaryContainer),
      shape: MaterialStateProperty.all<OutlinedBorder>(const StadiumBorder()),
      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      textStyle: MaterialStateProperty.all<TextStyle>(
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    final ButtonStyle outlinedButtonStyle = ButtonStyle(
      elevation: MaterialStateProperty.all<double>(0),
      shadowColor: MaterialStateProperty.all<Color>(Colors.transparent),
      surfaceTintColor: MaterialStateProperty.all<Color>(Colors.transparent),
      foregroundColor: MaterialStateProperty.all<Color>(scheme.primary),
      side: MaterialStateProperty.all<BorderSide>(
        BorderSide(color: scheme.outline, width: 1),
      ),
      shape: MaterialStateProperty.all<OutlinedBorder>(const StadiumBorder()),
      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      textStyle: MaterialStateProperty.all<TextStyle>(
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primaryContainer,
        selectionHandleColor: scheme.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardTheme(
        color: scheme.surfaceContainerLow,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: scheme.surfaceContainerHighest,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: dialogShape,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        contentTextStyle: textTheme.bodyMedium,
        barrierColor: Colors.black.withOpacity(0.54),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: sheetShape,
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withOpacity(0.4),
        dragHandleSize: const Size(36, 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.primaryContainer,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: scheme.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        insetPadding: const EdgeInsets.all(16),
        showCloseIcon: true,
        closeIconColor: scheme.onPrimaryContainer,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: scheme.surfaceContainerLow,
        selectedTileColor: scheme.secondaryContainer,
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: cardShape,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 12,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        disabledColor: scheme.surfaceContainerLow,
        deleteIconColor: scheme.error,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
        brightness: scheme.brightness,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        elevation: 0,
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hoverColor: scheme.surfaceContainerHigh,
        focusColor: scheme.primaryContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: fieldShape.borderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldShape.borderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldShape.borderRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldShape.borderRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldShape.borderRadius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(scheme.primary),
          shape: MaterialStateProperty.all<OutlinedBorder>(const StadiumBorder()),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          textStyle: MaterialStateProperty.all<TextStyle>(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(scheme.onSurfaceVariant),
          backgroundColor: MaterialStateProperty.all<Color>(scheme.surfaceContainerHighest),
          shape: MaterialStateProperty.all<OutlinedBorder>(const StadiumBorder()),
          elevation: MaterialStateProperty.all<double>(0),
          shadowColor: MaterialStateProperty.all<Color>(Colors.transparent),
          surfaceTintColor: MaterialStateProperty.all<Color>(Colors.transparent),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return scheme.secondaryContainer;
            }
            return scheme.surfaceContainerLow;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return scheme.onSecondaryContainer;
            }
            return scheme.onSurface;
          }),
          side: MaterialStateProperty.all<BorderSide>(BorderSide.none),
          shape: MaterialStateProperty.all<OutlinedBorder>(const StadiumBorder()),
          elevation: MaterialStateProperty.all<double>(0),
          shadowColor: MaterialStateProperty.all<Color>(Colors.transparent),
          surfaceTintColor: MaterialStateProperty.all<Color>(Colors.transparent),
          textStyle: MaterialStateProperty.all<TextStyle>(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: scheme.onSecondaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        elevation: 0,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        groupAlignment: -0.5,
        labelType: NavigationRailLabelType.all,
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        refreshBackgroundColor: scheme.surfaceContainerLow,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: MaterialStateProperty.all<Color>(Colors.transparent),
        overlayColor: MaterialStateProperty.all<Color>(scheme.primary.withOpacity(0.12)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all<Color>(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) return scheme.primary;
          return scheme.outline;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(0.12),
        valueIndicatorColor: scheme.primaryContainer,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: cardShape,
        textStyle: textTheme.bodyMedium,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        width: 320,
      ),
      tooltipTheme: TooltipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
        textStyle: textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(seconds: 2),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Supplies fully built light and dark [ThemeData] objects to a subtree.
///
/// [DynamicColorBuilder] returns null on platforms without Material You, in
/// which case the selected seed palette is used automatically.
class PaisaThemeBuilder extends StatelessWidget {
  const PaisaThemeBuilder({
    super.key,
    required this.engine,
    required this.builder,
  });

  final PaisaThemeEngine engine;
  final Widget Function(
    BuildContext context,
    ThemeData lightTheme,
    ThemeData darkTheme,
    ThemeMode themeMode,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaisaThemeEngine>.value(
      value: engine,
      child: Consumer<PaisaThemeEngine>(
        builder: (BuildContext context, PaisaThemeEngine theme, Widget? _) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              final ThemeData light = theme.buildLightTheme(lightDynamic);
              final ThemeData dark = theme.buildDarkTheme(darkDynamic);
              return builder(context, light, dark, theme.flutterThemeMode);
            },
          );
        },
      ),
    );
  }
}

/// A ready-to-use [MaterialApp] wrapper for Step 1.
///
/// Later steps can replace [home] with the real navigation shell without
/// changing the theme engine.
class PaisaThemeApp extends StatelessWidget {
  const PaisaThemeApp({
    super.key,
    required this.engine,
    required this.home,
    this.title = 'Paisa',
    this.navigatorKey,
    this.initialRoute,
    this.routes = const <String, WidgetBuilder>{},
    this.onGenerateRoute,
    this.builder,
    this.supportedLocales = const <Locale>[Locale('en')],
    this.localizationsDelegates,
    this.debugShowCheckedModeBanner = false,
  });

  final PaisaThemeEngine engine;
  final Widget home;
  final String title;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? initialRoute;
  final Map<String, WidgetBuilder> routes;
  final RouteFactory? onGenerateRoute;
  final TransitionBuilder? builder;
  final Iterable<Locale> supportedLocales;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) {
    return PaisaThemeBuilder(
      engine: engine,
      builder: (
        BuildContext context,
        ThemeData lightTheme,
        ThemeData darkTheme,
        ThemeMode themeMode,
      ) {
        return MaterialApp(
          title: title,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          home: home,
          navigatorKey: navigatorKey,
          initialRoute: initialRoute,
          routes: routes,
          onGenerateRoute: onGenerateRoute,
          builder: builder,
          supportedLocales: supportedLocales,
          localizationsDelegates: localizationsDelegates ??
              const <LocalizationsDelegate<dynamic>>[
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
          debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        );
      },
    );
  }
}
