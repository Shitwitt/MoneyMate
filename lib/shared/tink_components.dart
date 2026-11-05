import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'luxury_components.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading, success;
  final IconData? icon;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.success = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading || success ? null : onPressed,
    style: success || loading
        ? FilledButton.styleFrom(
            disabledBackgroundColor: success
                ? AppColors.incomeInk
                : Theme.of(context).colorScheme.primary,
            disabledForegroundColor: success
                ? Colors.white
                : Theme.of(context).colorScheme.onPrimary,
          )
        : null,
    child: AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      child: Row(
        key: ValueKey('$loading-$success'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          else if (success || icon != null)
            Icon(success ? Icons.check_rounded : icon, size: 22),
          if (loading || success || icon != null) const SizedBox(width: 10),
          Flexible(
            child: Text(success ? 'Done' : label, textAlign: TextAlign.center),
          ),
        ],
      ),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => icon == null
      ? OutlinedButton(onPressed: onPressed, child: Text(label))
      : OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
        );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.screen),
    this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorder,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const CategoryIcon({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 48,
  });
  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark(context);
    final foreground = dark
        ? Color.lerp(color, Colors.white, .35)!
        : Color.lerp(color, AppColors.ink, .40)!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? .18 : .12),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(icon, color: foreground, size: size * .46),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  final String? label;
  const ProgressBar(
    this.value, {
    super.key,
    this.color,
    this.height = 8,
    this.label,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: label ?? 'Progress',
    value: '${(value * 100).round()} percent',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: progress,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(
                      color ?? Theme.of(context).colorScheme.primary,
                      Colors.white,
                      .25,
                    )!,
                    color ?? Theme.of(context).colorScheme.primary,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ProgressRing extends StatelessWidget {
  final double value, size, strokeWidth;
  final Widget? child;
  final Color? color;
  const ProgressRing(
    this.value, {
    super.key,
    this.size = 72,
    this.strokeWidth = 7,
    this.child,
    this.color,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Goal progress',
    value: '${(value * 100).round()} percent',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress,
            color ?? Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.surfaceContainerHighest,
            strokeWidth,
          ),
          child: Center(child: child),
        ),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double value, width;
  final Color color, track;
  _RingPainter(this.value, this.color, this.track, this.width);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, p..color = track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      p
        ..color = color.withValues(alpha: .28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    p.maskFilter = null;
    p.shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [Color.lerp(color, Colors.white, .35)!, color],
    ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tink Pro',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      builder: (context, value, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-2 + 3 * value, 0),
            end: Alignment(-1 + 3 * value, 0),
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Color.alphaBlend(
                Colors.white.withValues(alpha: .15),
                Theme.of(context).colorScheme.primaryContainer,
              ),
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: math.sin(value * math.pi) * .12,
              ),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          'PRO',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

/// Finite entrance animation: never delays interactions or loops behind a form.
class Entrance extends StatelessWidget {
  final Widget child;
  final int index;
  const Entrance({super.key, required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + math.min(index, 5) * 50),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class TinkLogo extends StatelessWidget {
  final double size;
  final bool tile;
  const TinkLogo({super.key, this.size = 48, this.tile = true});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tink logo',
    image: true,
    child: Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .13),
      decoration: BoxDecoration(
        color: tile ? const Color(0xffFAF9F5) : null,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: const CustomPaint(painter: TinkMarkPainter()),
    ),
  );
}

class TinkBrand extends StatelessWidget {
  final double size;
  const TinkBrand({super.key, this.size = 32});
  @override
  Widget build(BuildContext context) => LuxuryWordmark(size: size);
}

/// An original scalable redraw of the head-and-spark icon supplied by the user.
class TinkMarkPainter extends CustomPainter {
  const TinkMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final head = Path()
      ..moveTo(23, 61)
      ..cubicTo(27, 42, 34, 21, 43, 18)
      ..cubicTo(50, 15, 70, 18, 76, 22)
      ..cubicTo(84, 28, 85, 48, 78, 56)
      ..quadraticBezierTo(74, 61, 64, 68)
      ..lineTo(67, 91)
      ..quadraticBezierTo(58, 93, 47, 90)
      ..lineTo(45, 68)
      ..lineTo(25, 66)
      ..quadraticBezierTo(21, 66, 23, 61);
    canvas.drawPath(
      head,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final star = Path()
      ..moveTo(53, 29)
      ..quadraticBezierTo(56, 29, 57, 39)
      ..quadraticBezierTo(60, 43, 69, 46)
      ..quadraticBezierTo(70, 48, 59, 51)
      ..quadraticBezierTo(56, 55, 53, 64)
      ..quadraticBezierTo(50, 64, 47, 53)
      ..quadraticBezierTo(44, 50, 36, 47)
      ..quadraticBezierTo(34, 45, 47, 41)
      ..quadraticBezierTo(50, 37, 53, 29);
    canvas.drawPath(star, Paint()..color = const Color(0xffFFF12B));
    final inner = Path()
      ..moveTo(53, 37)
      ..lineTo(56, 45)
      ..lineTo(62, 47)
      ..lineTo(55, 50)
      ..lineTo(52, 57)
      ..lineTo(49, 49)
      ..lineTo(43, 46)
      ..lineTo(50, 44)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xffFFF997));
    canvas.restore();
  }

  @override
  bool shouldRepaint(TinkMarkPainter old) => false;
}

/// One quiet outline pulse when a budget crosses its limit; never flashes/loops.
class BudgetWarningFrame extends StatelessWidget {
  final bool overLimit;
  final Widget child;
  const BudgetWarningFrame({
    super.key,
    required this.overLimit,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(overLimit),
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 600),
    child: child,
    builder: (context, value, child) => Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadius.cardBorder,
        border: Border.all(
          width: 1.5,
          color: AppColors.expense.withValues(
            alpha: overLimit ? math.sin(value * math.pi) * .6 : 0,
          ),
        ),
      ),
      child: child,
    ),
  );
}

/// Reveals chart ink, keeping the numeric/semantic summary independent of motion.
class ChartReveal extends StatelessWidget {
  final double progress;
  final bool circular;
  final Widget child;
  const ChartReveal({
    super.key,
    required this.progress,
    required this.child,
    this.circular = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0).toDouble();
    final edge = (p + .025).clamp(0.0, 1.0).toDouble();
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        const colors = [
          Colors.white,
          Colors.white,
          Colors.transparent,
          Colors.transparent,
        ];
        final stops = [0.0, p, edge, 1.0];
        return circular
            ? SweepGradient(
                colors: colors,
                stops: stops,
                transform: const GradientRotation(-math.pi / 2),
              ).createShader(rect)
            : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: colors,
                stops: stops,
              ).createShader(rect);
      },
      child: child,
    );
  }
}
