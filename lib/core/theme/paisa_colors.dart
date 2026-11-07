import 'package:flutter/material.dart';

/// Paisa's semantic colour tokens, layered on top of the Material 3
/// [ColorScheme].
///
/// Material 3 tells us *where* colour goes (containers, surfaces, outlines) but
/// not *what* money means. These tokens carry the money semantics — income is
/// green, expense is red, transfers are blue — while every container colour is
/// derived so it always harmonises with the active dynamic/seed scheme.
@immutable
class PaisaColors extends ThemeExtension<PaisaColors> {
  const PaisaColors({
    required this.income,
    required this.onIncome,
    required this.incomeContainer,
    required this.expense,
    required this.onExpense,
    required this.expenseContainer,
    required this.transfer,
    required this.onTransfer,
    required this.transferContainer,
    required this.debtGiven,
    required this.debtTaken,
    required this.warning,
    required this.warningContainer,
    required this.success,
    required this.successContainer,
    required this.neutral,
    required this.outlineMuted,
    required this.chartGrid,
    required this.chartPalette,
    required this.shadow,
  });

  /// Money received.
  final Color income;
  final Color onIncome;
  final Color incomeContainer;

  /// Money spent.
  final Color expense;
  final Color onExpense;
  final Color expenseContainer;

  /// Money moved between the user's own accounts.
  final Color transfer;
  final Color onTransfer;
  final Color transferContainer;

  /// Money lent to others (an asset).
  final Color debtGiven;

  /// Money borrowed / loans / EMIs (a liability).
  final Color debtTaken;

  /// Budget at risk / due soon.
  final Color warning;
  final Color warningContainer;

  /// Budget healthy / debt settled.
  final Color success;
  final Color successContainer;

  /// Non-semantic muted foreground for hints and de-emphasised numbers.
  final Color neutral;

  /// Hairline dividers inside cards.
  final Color outlineMuted;

  /// Chart grid lines.
  final Color chartGrid;

  /// Ordered palette used by the pie / donut charts so slices never repeat
  /// adjacent hues.
  final List<Color> chartPalette;

  /// Colour used for the (very soft) elevation shadow. In AMOLED mode this is
  /// fully transparent so nothing glows against pure black.
  final Color shadow;

  // ---------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------

  factory PaisaColors.light() => const PaisaColors(
        income: Color(0xFF1B7F4B),
        onIncome: Color(0xFFFFFFFF),
        incomeContainer: Color(0xFFD5F2E1),
        expense: Color(0xFFB3261E),
        onExpense: Color(0xFFFFFFFF),
        expenseContainer: Color(0xFFFBE2DF),
        transfer: Color(0xFF1B5FAF),
        onTransfer: Color(0xFFFFFFFF),
        transferContainer: Color(0xFFDDE8FA),
        debtGiven: Color(0xFF0F7B6C),
        debtTaken: Color(0xFFB2540A),
        warning: Color(0xFFA15C00),
        warningContainer: Color(0xFFFFEBC7),
        success: Color(0xFF1B7F4B),
        successContainer: Color(0xFFD5F2E1),
        neutral: Color(0xFF6F7473),
        outlineMuted: Color(0xFFE1E3E1),
        chartGrid: Color(0xFFE8EAE8),
        chartPalette: const <Color>[
          Color(0xFF00897B),
          Color(0xFF1E88E5),
          Color(0xFFFB8C00),
          Color(0xFF8E24AA),
          Color(0xFFE53935),
          Color(0xFF43A047),
          Color(0xFFD81B60),
          Color(0xFF5E35B1),
          Color(0xFFFDD835),
          Color(0xFF00ACC1),
          Color(0xFFF4511E),
          Color(0xFF3949AB),
        ],
        shadow: Color(0x14000000),
      );

  factory PaisaColors.dark() => const PaisaColors(
        income: Color(0xFF6FDC9E),
        onIncome: Color(0xFF00391F),
        incomeContainer: Color(0xFF12352A),
        expense: Color(0xFFFFB4AB),
        onExpense: Color(0xFF690005),
        expenseContainer: Color(0xFF4A1F1D),
        transfer: Color(0xFFA8C8FF),
        onTransfer: Color(0xFF00325B),
        transferContainer: Color(0xFF1C2C4A),
        debtGiven: Color(0xFF4FD1BE),
        debtTaken: Color(0xFFFFB77C),
        warning: Color(0xFFFFC46B),
        warningContainer: Color(0xFF3E2E10),
        success: Color(0xFF6FDC9E),
        successContainer: Color(0xFF12352A),
        neutral: Color(0xFF9CA3A0),
        outlineMuted: Color(0xFF2A2E2C),
        chartGrid: Color(0xFF24292A),
        chartPalette: const <Color>[
          Color(0xFF4FD1BE),
          Color(0xFF8AB9FF),
          Color(0xFFFFB77C),
          Color(0xFFD9A8F5),
          Color(0xFFFF9B95),
          Color(0xFF8FDB9E),
          Color(0xFFFFA6C4),
          Color(0xFFB7A4F5),
          Color(0xFFF5DA6B),
          Color(0xFF6BD6E8),
          Color(0xFFFFA07A),
          Color(0xFF9FB0FF),
        ],
        shadow: Color(0x00000000),
      );

  // ---------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------

  /// Colour for a signed money value.
  Color forAmount(double value) {
    if (value > 0) return income;
    if (value < 0) return expense;
    return neutral;
  }

  /// Container tint for a chart slice at [index].
  Color chartAt(int index) => chartPalette[index % chartPalette.length];

  /// Looks the tokens up from the widget tree, always non-null.
  static PaisaColors of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.extension<PaisaColors>() ??
        (theme.brightness == Brightness.dark
            ? PaisaColors.dark()
            : PaisaColors.light());
  }

  @override
  PaisaColors copyWith({
    Color? income,
    Color? onIncome,
    Color? incomeContainer,
    Color? expense,
    Color? onExpense,
    Color? expenseContainer,
    Color? transfer,
    Color? onTransfer,
    Color? transferContainer,
    Color? debtGiven,
    Color? debtTaken,
    Color? warning,
    Color? warningContainer,
    Color? success,
    Color? successContainer,
    Color? neutral,
    Color? outlineMuted,
    Color? chartGrid,
    List<Color>? chartPalette,
    Color? shadow,
  }) {
    return PaisaColors(
      income: income ?? this.income,
      onIncome: onIncome ?? this.onIncome,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      expense: expense ?? this.expense,
      onExpense: onExpense ?? this.onExpense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      transfer: transfer ?? this.transfer,
      onTransfer: onTransfer ?? this.onTransfer,
      transferContainer: transferContainer ?? this.transferContainer,
      debtGiven: debtGiven ?? this.debtGiven,
      debtTaken: debtTaken ?? this.debtTaken,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      neutral: neutral ?? this.neutral,
      outlineMuted: outlineMuted ?? this.outlineMuted,
      chartGrid: chartGrid ?? this.chartGrid,
      chartPalette: chartPalette ?? this.chartPalette,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  PaisaColors lerp(ThemeExtension<PaisaColors>? other, double t) {
    if (other is! PaisaColors) return this;
    return PaisaColors(
      income: Color.lerp(income, other.income, t)!,
      onIncome: Color.lerp(onIncome, other.onIncome, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      onExpense: Color.lerp(onExpense, other.onExpense, t)!,
      expenseContainer: Color.lerp(expenseContainer, other.expenseContainer, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      onTransfer: Color.lerp(onTransfer, other.onTransfer, t)!,
      transferContainer: Color.lerp(transferContainer, other.transferContainer, t)!,
      debtGiven: Color.lerp(debtGiven, other.debtGiven, t)!,
      debtTaken: Color.lerp(debtTaken, other.debtTaken, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      outlineMuted: Color.lerp(outlineMuted, other.outlineMuted, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartPalette: List<Color>.generate(
        chartPalette.length,
        (int i) => Color.lerp(
          chartPalette[i],
          other.chartPalette[i % other.chartPalette.length],
          t,
        )!,
        growable: false,
      ),
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
