import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const giftGold = Color(0xFFFFD36A);

class GlobalGiftBanner extends StatefulWidget {
  final Widget child;
  const GlobalGiftBanner({super.key, required this.child});
  @override State<GlobalGiftBanner> createState()=>_GlobalGiftBannerState();
}

class _GlobalGiftBannerState extends State<GlobalGiftBanner> {
  StreamSubscription<List<Map<String,dynamic>>>? sub;
  Map<String,dynamic>? banner;
  Timer? hideTimer;

  @override void initState(){
    super.initState();
    sub=Supabase.instance.client.from('gift_public_banners').stream(primaryKey:['id']).order('created_at',ascending:false).limit(1).listen((rows){
      if(rows.isEmpty||!mounted)return;
      setState(()=>banner=rows.first);
      hideTimer?.cancel();
      hideTimer=Timer(const Duration(seconds:6),(){if(mounted)setState(()=>banner=null);});
    });
  }
  @override void dispose(){sub?.cancel();hideTimer?.cancel();super.dispose();}

  @override Widget build(BuildContext context)=>Stack(children:[
    widget.child,
    if(banner!=null)
      Positioned(
        top: MediaQuery.of(context).padding.top+8,
        left: 10,right: 10,
        child: IgnorePointer(child: _GiftTicker(banner:banner!)),
      ),
  ]);
}

class _GiftTicker extends StatefulWidget{
 final Map<String,dynamic> banner;
 const _GiftTicker({required this.banner});
 @override State<_GiftTicker> createState()=>_GiftTickerState();
}
class _GiftTickerState extends State<_GiftTicker> with SingleTickerProviderStateMixin{
 late final AnimationController controller;
 @override void initState(){super.initState();controller=AnimationController(vsync:this,duration:const Duration(milliseconds:1200))..repeat(reverse:true);}
 @override void dispose(){controller.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(_,__)=>Container(
   padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
   decoration:BoxDecoration(
     borderRadius:BorderRadius.circular(30),
     gradient:const LinearGradient(colors:[Color(0xFF7A3F08),Color(0xFF1A0903),Color(0xFF7A3F08)]),
     border:Border.all(color:giftGold,width:1.5),
     boxShadow:[BoxShadow(color:giftGold.withOpacity(.22+.12*controller.value),blurRadius:16)],
   ),
   child:Row(children:[
     const Text('🎁',style:TextStyle(fontSize:24)),
     const SizedBox(width:8),
     Expanded(child:Text('إهداء فخم • '+widget.banner['amount'].toString()+' 🪙',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))),
     const Text('✨',style:TextStyle(fontSize:20)),
   ]),
 ));
}
