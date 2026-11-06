import 'package:flutter/material.dart';

/// Fixed, value-independent shapes: no digit count, sign or magnitude is leaked.
class PrivateAmount extends StatelessWidget {
  final TextStyle? style;
  const PrivateAmount({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final size = ((effective.fontSize ?? 16) * .75)
        .clamp(12.0, 28.0)
        .toDouble();
    return Semantics(
      label: 'Amount hidden',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final icon in const [
              Icons.circle,
              Icons.diamond_rounded,
              Icons.square_rounded,
            ])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Icon(icon, size: size, color: effective.color),
              ),
          ],
        ),
      ),
    );
  }
}
