import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/data/ledger.dart';
import '../core/utils/dates.dart';
import 'widgets.dart';

/// Linked cumulative cashflow line and monthly expense bars. The panels use
/// independent, labelled scales; no invented balances or forecast data.
class CashflowComposition extends StatefulWidget {
  final Ledger ledger;
  final int months;
  final DateTime? anchor;
  const CashflowComposition(
    this.ledger, {
    super.key,
    this.months = 6,
    this.anchor,
  });
  @override
  State<CashflowComposition> createState() => _CashflowCompositionState();
}

class _CashflowCompositionState extends State<CashflowComposition> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    if (widget.ledger.settings.hideAmounts)
      return const SizedBox(
        height: 180,
        child: Center(child: Icon(Icons.visibility_off_outlined)),
      );
    final windows = monthlyWindows(
      widget.anchor ?? DateTime.now(),
      widget.ledger.settings.monthStart,
      widget.months,
    );
    final income = [for (final w in windows) widget.ledger.total('income', w)];
    final expense = [
      for (final w in windows) widget.ledger.total('expense', w),
    ];
    var running = 0;
    final net = [
      for (var i = 0; i < windows.length; i++)
        (running += income[i] - expense[i]).toDouble(),
    ];
    final index = (selected ?? windows.length - 1).clamp(0, windows.length - 1);
    final months = [
      for (final w in windows)
        DateFormat.MMM(widget.ledger.settings.locale).format(w.start),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The rhythm of your money',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Cumulative net flow above · Monthly expenses below',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) => Semantics(
            label: 'Linked cashflow comparison. Select a month below for exact figures.',
            child: ExcludeSemantics(
              child: GestureDetector(
                onTapUp: (details) => setState(
                  () => selected =
                      ((details.localPosition.dx - 18) /
                              math.max(1, box.maxWidth - 36) *
                              math.max(1, windows.length - 1))
                          .round()
                          .clamp(0, windows.length - 1),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, p, _) => SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _CompositionPainter(
                        net,
                        expense.map((v) => v.toDouble()).toList(),
                        index,
                        p,
                        scheme.primary,
                        AppColors.semantic(context, 'expense'),
                        scheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 5,
          runSpacing: 3,
          children: [
            for (var i = 0; i < windows.length; i++)
              ChoiceChip(
                label: Text(months[i]),
                selected: i == index,
                onSelected: (_) => setState(() => selected = i),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                '${months[index]} · Cumulative net',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            AmountText(
              net[index].round(),
              compact: true,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Monthly expenses',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            AmountText(
              expense[index],
              compact: true,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _CompositionPainter extends CustomPainter {
  final List<double> net, expense;
  final int selected;
  final double progress;
  final Color primary, expenseColor, grid;
  _CompositionPainter(
    this.net,
    this.expense,
    this.selected,
    this.progress,
    this.primary,
    this.expenseColor,
    this.grid,
  );
  @override
  void paint(Canvas canvas, Size size) {
    final left = 18.0, width = math.max(1.0, size.width - 36);
    final min = math.min(0.0, net.fold<double>(0, math.min));
    final max = math.max(1.0, net.fold<double>(0, math.max));
    double x(int i) =>
        left + (net.length == 1 ? width / 2 : width * i / (net.length - 1));
    double y(double v) =>
        20 + 110 * (1 - (v * progress - min) / math.max(1, max - min));
    final p = Paint()
      ..color = grid.withValues(alpha: .5)
      ..strokeWidth = .8;
    for (final y in [20.0, 57.0, 94.0, 132.0, 165.0, 225.0]) {
      for (var x = left; x < size.width - left; x += 7) {
        canvas.drawLine(Offset(x, y), Offset(x + 2, y), p);
      }
    }
    final path = Path()..moveTo(x(0), y(net[0]));
    for (var i = 1; i < net.length; i++) {
      final mid = (x(i) + x(i - 1)) / 2;
      path.cubicTo(mid, y(net[i - 1]), mid, y(net[i]), x(i), y(net[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = primary.withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    final maxExpense = expense.fold<double>(1, math.max);
    for (var i = 0; i < expense.length; i++) {
      final h = expense[i] / maxExpense * 57 * progress;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(x(i) - 7, 225 - h, 14, h),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        bar,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              expenseColor.withValues(alpha: i == selected ? 1 : .5),
              expenseColor.withValues(alpha: .15),
            ],
          ).createShader(bar.outerRect),
      );
    }
    canvas.drawLine(
      Offset(x(selected), 8),
      Offset(x(selected), 229),
      Paint()
        ..color = primary.withValues(alpha: .28)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(x(selected), y(net[selected])),
      6,
      Paint()
        ..color = primary.withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(x(selected), y(net[selected])),
      4,
      Paint()..color = primary,
    );
  }

  @override
  bool shouldRepaint(_CompositionPainter old) =>
      old.progress != progress ||
      old.selected != selected ||
      old.net != net ||
      old.primary != primary ||
      old.grid != grid;
}
