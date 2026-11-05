import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/models/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/money.dart';
import 'luxury_components.dart';

const accountFinishes = <String, String>{
  'auto': 'Signature',
  'onyx': 'Onyx',
  'pearl': 'Pearl',
  'amethyst': 'Amethyst',
  'sage': 'Sage',
  'copper': 'Copper',
};

/// Original procedural artwork. No issuer logos, PANs, banknote replicas or
/// remotely loaded images. All amounts are bookkeeping balances, not bank feeds.
class AccountArtwork extends StatelessWidget {
  final Account account;
  final int balance;
  final bool hidden, preview, indian;
  final String locale;
  final VoidCallback? onTap;
  const AccountArtwork({
    super.key,
    required this.account,
    required this.balance,
    this.hidden = false,
    this.indian = true,
    this.locale = 'en',
    this.preview = false,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cash = account.type == 'cash';
    final bank = account.type == 'bank' || account.type == 'savings';
    final finish = account.cardStyle == 'auto'
        ? cash
              ? 'sage'
              : bank
              ? 'pearl'
              : account.type == 'credit card'
              ? 'onyx'
              : 'amethyst'
        : account.cardStyle;
    final light = ['pearl', 'sage', 'copper'].contains(finish);
    final palette = switch (finish) {
      'pearl' => const [
        Color(0xffF3F1EB),
        Color(0xffE0DFDB),
        Color(0xffFAF9F6),
      ],
      'sage' => const [Color(0xffD9EDB8), Color(0xffB9D99D), Color(0xffEBF2D5)],
      'copper' => const [
        Color(0xffF5D8C2),
        Color(0xffD9A78B),
        Color(0xffF7E4D7),
      ],
      'amethyst' => const [
        Color(0xff3B285E),
        Color(0xff775BA4),
        Color(0xff2C2441),
      ],
      _ => const [Color(0xff121419), Color(0xff34373F), Color(0xff14161C)],
    };
    final colors = account.cardStyle == 'auto'
        ? palette
              .map(
                (c) => Color.alphaBlend(
                  Color(account.color).withValues(alpha: .10),
                  c,
                ),
              )
              .toList()
        : palette;
    final ink = light ? const Color(0xff20241D) : const Color(0xffFFFDF5);
    final muted = light ? const Color(0xff363B30) : const Color(0xffD4D0DB);
    final amount = money(
      balance,
      account.currency,
      hidden: hidden,
      indian: indian,
      locale: locale,
    );
    final type = account.type.isEmpty
        ? 'Account'
        : account.type[0].toUpperCase() + account.type.substring(1);
    return Semantics(
      label:
          '$type account ${account.name}. ${preview ? 'Opening' : 'Recorded'} balance $amount.${account.archived ? ' Archived.' : ''}${account.excluded ? ' Excluded from net worth.' : ''}',
      child: ShineSurface(
        colors: colors,
        radius: cash ? 22 : 28,
        shineKey:
            '${account.name}|${account.type}|${account.currency}|$finish|$balance',
        glow: finish == 'amethyst' ? const Color(0xff916CFF) : null,
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AccountEngraving(
                    cash: cash,
                    bank: bank,
                    color: ink.withValues(alpha: .09),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (account.imageBase64.isNotEmpty)
                        CircleAvatar(
                          radius: 17,
                          backgroundImage: MemoryImage(
                            base64Decode(account.imageBase64),
                          ),
                        )
                      else
                        Icon(
                          cash
                              ? Icons.payments_outlined
                              : bank
                              ? Icons.account_balance_outlined
                              : Icons.credit_card_rounded,
                          color: ink,
                          size: 29,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          type,
                          style: AppTextStyles.data(13, FontWeight.w600, muted),
                        ),
                      ),
                      Text(
                        account.currency,
                        style: AppTextStyles.data(15, FontWeight.w600, ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 21),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!cash && !bank) ...[
                        Container(
                          width: 35,
                          height: 27,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xffE9D6A7),
                                Color(0xffBDA879),
                                Color(0xffF4E8C5),
                              ],
                            ),
                            border: Border.all(color: const Color(0xff9F8E67)),
                          ),
                          child: const Icon(
                            Icons.view_module_outlined,
                            size: 25,
                            color: Color(0xff736345),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.wifi_rounded, color: muted, size: 22),
                      ] else
                        Expanded(
                          child: Text(
                            cash ? 'A little in hand.' : 'Room for tomorrow.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.display(25, ink),
                          ),
                        ),
                      if (!cash && !bank) const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    account.name.isEmpty ? 'Your account name' : account.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ui(19, FontWeight.w600, ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.data(
                      32,
                      FontWeight.w600,
                      ink,
                    ).copyWith(letterSpacing: -1),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview
                              ? 'LIVE PREVIEW · OPENING BALANCE'
                              : 'LOCAL RECORD · ${account.archived
                                    ? 'ARCHIVED'
                                    : account.excluded
                                    ? 'EXCLUDED'
                                    : 'OFFLINE'}',
                          style: AppTextStyles.data(
                            10,
                            FontWeight.w500,
                            muted,
                          ).copyWith(letterSpacing: 1),
                        ),
                      ),
                      if (onTap != null)
                        Icon(Icons.north_east_rounded, size: 19, color: ink),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountEngraving extends CustomPainter {
  final bool cash, bank;
  final Color color;
  _AccountEngraving({
    required this.cash,
    required this.bank,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    if (cash) {
      for (var inset = 8.0; inset < 15; inset += 5) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            (Offset.zero & size).deflate(inset),
            const Radius.circular(15),
          ),
          paint,
        );
      }
      final center = Offset(size.width * .81, size.height * .52);
      for (var i = 0; i < 24; i++) {
        final angle = i * math.pi / 12;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(24, 0), width: 105, height: 42),
          paint,
        );
        canvas.restore();
      }
    } else if (bank) {
      final x = size.width * .62, y = size.height * .27;
      final path = Path()
        ..moveTo(x - 20, y + 20)
        ..lineTo(x + 45, y - 20)
        ..lineTo(x + 110, y + 20)
        ..close();
      canvas.drawPath(path, paint..strokeWidth = 2);
      for (var i = 0; i < 4; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + i * 30, y + 29, 14, 83),
            const Radius.circular(3),
          ),
          paint,
        );
      }
      canvas.drawLine(Offset(x - 12, y + 120), Offset(x + 106, y + 120), paint);
    } else {
      for (var i = 0; i < 12; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * .9, size.height * .05),
            width: 170.0 + i * 24,
            height: 105.0 + i * 23,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AccountEngraving old) =>
      old.cash != cash || old.bank != bank || old.color != color;
}
