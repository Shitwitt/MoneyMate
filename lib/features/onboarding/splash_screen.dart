import 'package:flutter/material.dart';
import '../../shared/widgets.dart';

class TinkSplashScreen extends StatelessWidget {
  const TinkSplashScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:TweenAnimationBuilder<double>(
    tween:Tween(begin:0,end:1),duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:600),curve:Curves.easeOutCubic,
    builder:(context,value,_)=>Opacity(opacity:value,child:Transform.scale(scale:.95+.05*value,child:Column(mainAxisSize:MainAxisSize.min,children:[
      const TinkLogo(size:96),const SizedBox(height:20),Text('Tink',style:Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight:FontWeight.w700,fontSize:36)),
      const SizedBox(height:12),const Text('Your money. A clearer mind.'),const SizedBox(height:28),
      Container(height:3,width:32+40*value,decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(8))),
    ])))))));
}
