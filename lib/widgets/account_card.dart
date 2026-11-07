import 'package:flutter/material.dart';

import '../core/enum/filter_enums.dart';

/// The visual identity of an account card.
///
/// Twelve gradient pairs ship with the app; [AccountStyle.forColor] resolves the
/// closest pair for a persisted ARGB value so an account created by an older
/// build (or restored from a backup) always renders with a sane gradient instead
/// of a flat fill.
@immutable
class AccountStyle {
  const AccountStyle({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    required this.accent,
  });

  /// Stable key, also persisted in backups (`card-emerald`, …).
  final String id;

  /// Human label used by the colour picker and the accessibility tooltip.
  final String label;

  /// Gradient start colour (the "face" of the card).
  final Color start;

  /// Gradient end colour.
  final Color end;

  /// A mid-tone of the same family, used for chips and rings on light surfaces.
  final Color accent;

  /// The value persisted in [AccountModel.color] for this theme.
  int get value => start.toARGB32();

  /// The twelve card themes, in picker order.
  static const List<AccountStyle> palette = <AccountStyle>[
    AccountStyle(
      id: 'card-emerald',
      label: 'Emerald',
      start: Color(0xFF0F9D58),
      end: Color(0xFF05643A),
      accent: Color(0xFF0F9D58),
    ),
    AccountStyle(
      id: 'card-ocean',
      label: 'Ocean',
      start: Color(0xFF1E88E5),
      end: Color(0xFF0D47A1),
      accent: Color(0xFF1565C0),
    ),
    AccountStyle(
      id: 'card-indigo',
      label: 'Indigo',
      start: Color(0xFF5C6BC0),
      end: Color(0xFF283593),
      accent: Color(0xFF3949AB),
    ),
    AccountStyle(
      id: 'card-violet',
      label: 'Violet',
      start: Color(0xFF8E24AA),
      end: Color(0xFF4A148C),
      accent: Color(0xFF7B1FA2),
    ),
    AccountStyle(
      id: 'card-magenta',
      label: 'Magenta',
      start: Color(0xFFD81B60),
      end: Color(0xFF880E4F),
      accent: Color(0xFFC2185B),
    ),
    AccountStyle(
      id: 'card-crimson',
      label: 'Crimson',
      start: Color(0xFFE53935),
      end: Color(0xFF8E0000),
      accent: Color(0xFFC62828),
    ),
    AccountStyle(
      id: 'card-ember',
      label: 'Ember',
      start: Color(0xFFF4511E),
      end: Color(0xFFA22700),
      accent: Color(0xFFD84315),
    ),
    AccountStyle(
      id: 'card-amber',
      label: 'Amber',
      start: Color(0xFFFB8C00),
      end: Color(0xFFB45309),
      accent: Color(0xFFE65100),
    ),
    AccountStyle(
      id: 'card-gold',
      label: 'Gold',
      start: Color(0xFFB08A2E),
      end: Color(0xFF6B5210),
      accent: Color(0xFF9A7B21),
    ),
    AccountStyle(
      id: 'card-teal',
      label: 'Teal',
      start: Color(0xFF00897B),
      end: Color(0xFF00453E),
      accent: Color(0xFF00796B),
    ),
    AccountStyle(
      id: 'card-slate',
      label: 'Slate',
      start: Color(0xFF546E7A),
      end: Color(0xFF263238),
      accent: Color(0xFF455A64),
    ),
    AccountStyle(
      id: 'card-charcoal',
      label: 'Charcoal',
      start: Color(0xFF424242),
      end: Color(0xFF121212),
      accent: Color(0xFF3A3A3A),
    ),
  ];

  static AccountStyle get fallback => palette.first;

  /// Resolves a persisted colour to its theme, or the closest palette entry.
  static AccountStyle forColor(int? value) {
    if (value == null) return fallback;
    for (final AccountStyle style in palette) {
      if (style.start.toARGB32() == value) return style;
    }
    // Closest match in RGB space — keeps custom colours recognisable.
    final Color target = Color(value);
    AccountStyle best = fallback;
    double bestDistance = double.infinity;
    for (final AccountStyle style in palette) {
      final double dr = (style.accent.r - target.r) * 100;
      final double dg = (style.accent.g - target.g) * 100;
      final double db = (style.accent.b - target.b) * 100;
      final double distance = dr * dr + dg * dg + db * db;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = style;
      }
    }
    return best;
  }

  static AccountStyle byId(String? id) {
    for (final AccountStyle style in palette) {
      if (style.id == id) return style;
    }
    return fallback;
  }

  /// A dark, high-contrast variant for AMOLED surfaces.
  List<Color> gradient({bool amoled = false}) {
    if (!amoled) return <Color>[start, end];
    return <Color>[end, Color.lerp(end, Colors.black, 0.45)!];
  }
}

/// A realistic Material 3 bank / credit / cash card.
///
/// * 220dp tall, 28dp radius, gradient face in the account's theme.
/// * Contactless chip, type badge (`CASH` / `BANK` / `CARD`), masked number
///   (`•••• •••• •••• 4821`), holder name, bank name and the live balance.
/// * Nothing is drawn with a hardcoded currency symbol: the caller passes the
///   already formatted balance so the card follows the selected currency.
class AccountCardView extends StatelessWidget {
  const AccountCardView({
    super.key,
    required this.title,
    required this.holderName,
    required this.maskedNumber,
    required this.type,
    required this.style,
    required this.balanceLabel,
    required this.balanceCaption,
    this.balanceNegative = false,
    this.isDefault = false,
    this.hideBalance = false,
    this.onTap,
    this.footer,
  });

  /// Bank / account title, e.g. `HDFC Savings`.
  final String title;

  /// Account holder, e.g. `Hemanth S`.
  final String holderName;

  /// `•••• •••• •••• 4821`, or the bank title for cash accounts.
  final String maskedNumber;

  final AccountType type;
  final AccountStyle style;

  /// Already formatted balance, e.g. `₹1,25,450.00`.
  final String balanceLabel;

  /// `Available balance` / `Cash in hand` / `Outstanding`.
  final String balanceCaption;

  final bool balanceNegative;
  final bool isDefault;
  final bool hideBalance;
  final VoidCallback? onTap;

  /// Optional row pinned above the balance (the accounts screen uses it for
  /// "default account" and quick actions).
  final Widget? footer;

  static const double height = 220;
  static const double radius = 28;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool amoled = theme.brightness == Brightness.dark &&
        theme.colorScheme.surface == const Color(0xFF000000);
    final List<Color> colors = style.gradient(amoled: amoled);
    final Color onCard = Colors.white;
    final Color muted = Colors.white.withValues(alpha: 0.74);

    final Widget content = Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: style.start.withValues(alpha: amoled ? 0.16 : 0.32),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ---------------- Header ----------------
          Row(
            children: <Widget>[
              _ContactlessChip(color: onCard),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  type.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onCard,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onCard,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ---------------- Bank / account title ----------------
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),

          // ---------------- Masked number ----------------
          Text(
            maskedNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),

          const Spacer(),

          // ---------------- Balance ----------------
          Text(
            balanceCaption,
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hideBalance ? '••••••' : balanceLabel,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: balanceNegative ? const Color(0xFFFFC9C4) : onCard,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),

          if (footer != null) ...<Widget>[
            const SizedBox(height: 10),
            footer!,
          ],

          const SizedBox(height: 10),

          // ---------------- Holder ----------------
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CARD HOLDER',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      holderName.isEmpty ? '—' : holderName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: onCard,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              type.iconRow(onCard),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: content,
    );
  }
}

/// The EMV contactless glyph: three concentric arcs plus the chip plate.
class _ContactlessChip extends StatelessWidget {
  const _ContactlessChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 24,
      child: CustomPaint(painter: _ContactlessPainter(color: color)),
    );
  }
}

class _ContactlessPainter extends CustomPainter {
  const _ContactlessPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint plate = Paint()..color = color.withValues(alpha: 0.85);
    final RRect chip = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 2, 12, 20),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(chip, plate);

    // Chip contact lines, drawn in the gradient colour for contrast.
    final Paint lines = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 8), const Offset(12, 8), lines);
    canvas.drawLine(const Offset(0, 16), const Offset(12, 16), lines);

    // Contactless waves.
    final Paint wave = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final Rect arc = Rect.fromCircle(
        center: Offset(16, size.height / 2),
        radius: 5.0 + i * 5.0,
      );
      canvas.drawArc(arc, -0.9, 1.8, false, wave);
    }
  }

  @override
  bool shouldRepaint(_ContactlessPainter oldDelegate) => oldDelegate.color != color;
}

/// Builds the card-network style glyph shown in the bottom-right corner.
extension AccountTypeGlyph on AccountType {
  Widget iconRow(Color color) {
    switch (this) {
      case AccountType.cash:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.payments_rounded, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              'RuPay',
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ],
        );
      case AccountType.bank:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.account_balance_rounded, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              'BANK',
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      case AccountType.card:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'VISA',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.0,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.credit_card_rounded, size: 17, color: color),
          ],
        );
    }
  }
}

/// Page indicator dots under the accounts carousel.
class CarouselDots extends StatelessWidget {
  const CarouselDots({
    super.key,
    required this.count,
    required this.index,
    this.activeColor,
    this.onTap,
  });

  final int count;
  final int index;
  final Color? activeColor;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (count <= 1) return const SizedBox(height: 8);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index
                    ? (activeColor ?? scheme.primary)
                    : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}
