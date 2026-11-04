import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Six original vector compositions. No stock art, external requests or bank logos.
class TinkIllustration extends StatelessWidget {
  final int page;
  const TinkIllustration(this.page, {super.key});
  @override Widget build(BuildContext context) => ExcludeSemantics(child: TweenAnimationBuilder<double>(
    tween: Tween(begin: 8, end: 0), duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 650),
    curve: Curves.easeOutCubic, builder: (context, y, _) => Transform.translate(offset: Offset(0,y),
      child: CustomPaint(size: const Size(340,300), painter: _FintechPainter(page)))));
}
class _FintechPainter extends CustomPainter {
  final int page;
  _FintechPainter(this.page);
  void box(Canvas c, Rect r, Color color, {double radius=22, bool shadow=false}) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(r,Radius.circular(radius)));
    if (shadow) c.drawShadow(path, const Color(0x180B0B0F), 12, false);
    c.drawPath(path, Paint()..color=color);
  }
  void text(Canvas c,String value,Offset p,{double size=12,Color color=AppColors.ink,FontWeight weight=FontWeight.w500,bool numeric=false}) {
    final t=TextPainter(text: TextSpan(text:value,style: TextStyle(fontFamily:numeric?'Inter':'Poppins',fontSize:size,fontWeight:weight,color:color,height:1.3)),textDirection:TextDirection.ltr)..layout(maxWidth:300);
    t.paint(c,p);
  }
  void line(Canvas c,Offset a,Offset b,Color color,{double width=1}) => c.drawLine(a,b,Paint()..color=color..strokeWidth=width..strokeCap=StrokeCap.round);
  void ring(Canvas c,Offset center,double radius,double progress,{double width=13,Color color=AppColors.primary}) {
    final rect=Rect.fromCircle(center:center,radius:radius);final p=Paint()..style=PaintingStyle.stroke..strokeWidth=width..strokeCap=StrokeCap.round;
    c.drawArc(rect,0,math.pi*2,false,p..color=AppColors.primaryLight);
    c.drawArc(rect,-math.pi/2,math.pi*2*progress,false,p..color=color);
  }
  @override void paint(Canvas c,Size s) {
    final scale=math.min(s.width/340,s.height/300);c.save();c.translate((s.width-340*scale)/2,(s.height-300*scale)/2);c.scale(scale);
    switch(page) {
      case 0:
        c.drawCircle(const Offset(170,148),124,Paint()..color=AppColors.primaryLight);
        c.drawCircle(const Offset(170,148),144,Paint()..color=AppColors.primary.withValues(alpha:.035));
        c.save();c.translate(170,150);c.rotate(-.065);
        box(c,const Rect.fromLTWH(-129,-77,258,164),AppColors.darkSurface,shadow:true);
        text(c,'YOUR EVERYDAY, IN FOCUS',const Offset(-108,-55),size:9,color:const Color(0xffCAC3DC));
        text(c,'₹28,450',const Offset(-108,-24),size:32,color:Colors.white,weight:FontWeight.w600,numeric:true);
        text(c,'A little more clarity.',const Offset(-108,48),size:11,color:const Color(0xffD9D4E7));
        c.drawCircle(const Offset(100,54),12,Paint()..color=AppColors.primary);
        line(c,const Offset(95,54),const Offset(105,54),Colors.white,width:2);
        c.restore();
        box(c,const Rect.fromLTWH(38,238,146,38),Colors.white,shadow:true,radius:19);
        c.drawCircle(const Offset(57,257),4,Paint()..color=AppColors.primary);
        text(c,'No sign-up. Just you.',const Offset(69,248),size:10);
      case 1:
        c.drawCircle(const Offset(170,146),118,Paint()..color=AppColors.infoBackground);
        c.save();c.translate(177,149);c.rotate(.055);
        box(c,const Rect.fromLTWH(-112,-118,224,238),Colors.white,shadow:true);
        box(c,const Rect.fromLTWH(-91,-97,40,40),AppColors.primaryLight,radius:14);
        text(c,'↗',const Offset(-81,-94),size:24,color:AppColors.primaryInk);
        text(c,'Coffee & a catch-up',const Offset(-91,-39),size:13,weight:FontWeight.w600);
        text(c,'₹180.00',const Offset(-91,-13),size:30,numeric:true,weight:FontWeight.w600);
        line(c,const Offset(-91,39),const Offset(91,39),AppColors.outline);
        text(c,'Food & dining',const Offset(-91,55),size:11,color:AppColors.secondary);
        text(c,'Today · 10:42 AM',const Offset(-91,79),size:10,color:AppColors.secondary);
        c.restore();
        box(c,const Rect.fromLTWH(145,233,167,38),AppColors.successBackground,radius:19);
        text(c,'✓  Saved on your device',const Offset(160,244),size:10,color:AppColors.incomeInk);
      case 2:
        c.drawCircle(const Offset(169,145),116,Paint()..color=AppColors.primaryLight);
        box(c,const Rect.fromLTWH(42,59,258,184),Colors.white,shadow:true);
        text(c,'SAFE TO SPEND',const Offset(63,82),size:9,color:AppColors.secondary,weight:FontWeight.w600);
        text(c,'₹12,400',const Offset(63,104),size:34,numeric:true,weight:FontWeight.w600);
        text(c,'Room for your everyday.',const Offset(63,157),size:11,color:AppColors.secondary);
        box(c,const Rect.fromLTWH(63,194,216,8),AppColors.primaryLight,radius:4);
        box(c,const Rect.fromLTWH(63,194,142,8),AppColors.primary,radius:4);
        c.drawCircle(const Offset(273,55),29,Paint()..color=AppColors.primary);
        text(c,'₹',const Offset(262,36),size:28,color:Colors.white,numeric:true,weight:FontWeight.w600);
      case 3:
        c.drawCircle(const Offset(169,148),126,Paint()..color=AppColors.primaryLight);
        c.save();c.translate(155,113);c.rotate(-.08);box(c,const Rect.fromLTWH(-111,-63,222,143),Colors.white,shadow:true);
        text(c,'EVERYDAY ACCOUNT',const Offset(-91,-43),size:9,color:AppColors.secondary);
        text(c,'₹28,450',const Offset(-91,-17),size:28,numeric:true,weight:FontWeight.w600);c.restore();
        c.save();c.translate(191,195);c.rotate(.055);box(c,const Rect.fromLTWH(-115,-55,230,130),AppColors.darkSurface,shadow:true);
        text(c,'SAVINGS',const Offset(-94,-35),size:9,color:const Color(0xffC5BBD8));
        text(c,'For what comes next.',const Offset(-94,-7),size:17,color:Colors.white,weight:FontWeight.w600);
        text(c,'YOUR ACCOUNTS. TOGETHER.',const Offset(-94,47),size:8,color:const Color(0xffC5BBD8));c.restore();
        for(var i=0;i<3;i++){c.drawCircle(Offset(65+i*34,245),18,Paint()..color=[AppColors.primary,AppColors.darkCard,Colors.white][i]);text(c,['₹','\$','€'][i],Offset(59+i*34,234),size:17,color:i==2?AppColors.ink:Colors.white,numeric:true);}
      case 4:
        c.drawCircle(const Offset(171,145),124,Paint()..color=AppColors.primaryLight.withValues(alpha:.65));
        box(c,const Rect.fromLTWH(62,30,216,252),Colors.white,shadow:true);
        ring(c,const Offset(170,117),57,.76,width:14);
        text(c,'76%',const Offset(137,99),size:30,numeric:true,weight:FontWeight.w600);
        text(c,'A new beginning',const Offset(91,199),size:16,weight:FontWeight.w600);
        text(c,'₹38,000 of ₹50,000',const Offset(101,227),size:11,numeric:true,color:AppColors.secondary);
        c.drawCircle(const Offset(274,211),25,Paint()..color=AppColors.primary);
        line(c,const Offset(264,211),const Offset(271,218),Colors.white,width:3);line(c,const Offset(271,218),const Offset(285,204),Colors.white,width:3);
      default:
        for(var i=0;i<3;i++)c.drawCircle(const Offset(170,143),70+i*35,Paint()..color=AppColors.primary.withValues(alpha:.035*(3-i)));
        final shield=Path()..moveTo(170,45)..quadraticBezierTo(208,69,242,76)..lineTo(237,153)..quadraticBezierTo(232,195,170,227)
          ..quadraticBezierTo(108,195,103,153)..lineTo(98,76)..quadraticBezierTo(132,69,170,45)..close();
        c.drawPath(shield,Paint()..color=AppColors.primary);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(146,122,48,43),const Radius.circular(10)),Paint()..color=Colors.white);
        c.drawArc(const Rect.fromLTWH(155,98,30,43),math.pi,math.pi,false,Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=6);
        c.drawCircle(const Offset(170,140),4,Paint()..color=AppColors.primary);
        box(c,const Rect.fromLTWH(80,247,180,35),AppColors.darkCard,radius:18);
        text(c,'No account. No server.',const Offset(101,257),size:10,color:Colors.white);
    }
    c.restore();
  }
  @override bool shouldRepaint(_FintechPainter old) => old.page != page;
}
