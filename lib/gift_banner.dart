import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
  Map<String,dynamic>? gift;
  Timer? hideTimer;

  @override void initState(){
    super.initState();
    sub=Supabase.instance.client.from('gift_public_banners').stream(primaryKey:['id']).order('created_at',ascending:false).limit(1).listen((rows) async {
      if(rows.isEmpty||!mounted)return;
      final next=rows.first;
      Map<String,dynamic>? nextGift;
      final giftId=next['gift_id']?.toString();
      if(giftId!=null&&giftId.isNotEmpty){
        try {
          final row=await Supabase.instance.client.from('gifts').select('id,name,emoji,asset_type,asset_url,preview_url,animation_loop').eq('id',giftId).maybeSingle();
          if(row!=null) nextGift=Map<String,dynamic>.from(row);
        } catch (_) {}
      }
      if(!mounted)return;
      setState((){banner=next;gift=nextGift;});
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
        child: IgnorePointer(child: _GiftTicker(banner:banner!,gift:gift)),
      ),
  ]);
}

class _GiftTicker extends StatefulWidget{
 final Map<String,dynamic> banner;
 final Map<String,dynamic>? gift;
 const _GiftTicker({required this.banner,this.gift});
 @override State<_GiftTicker> createState()=>_GiftTickerState();
}

class _GiftTickerState extends State<_GiftTicker> with SingleTickerProviderStateMixin{
 late final AnimationController controller;

 @override void initState(){
   super.initState();
   controller=AnimationController(vsync:this,duration:const Duration(milliseconds:1200))..repeat(reverse:true);
 }

 @override void dispose(){controller.dispose();super.dispose();}

 Widget _giftVisual(){
   final g=widget.gift;
   final url=g?['asset_url']?.toString()??'';
   final preview=g?['preview_url']?.toString()??'';
   final type=g?['asset_type']?.toString()??'';
   if(type=='lottie'&&url.isNotEmpty){
     return SizedBox(width:48,height:48,child:Lottie.network(url,repeat:g?['animation_loop']!=false,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Text('🎁',style:TextStyle(fontSize:28))));
   }
   if((type=='image'||type=='3d')&&(preview.isNotEmpty||url.isNotEmpty)){
     return SizedBox(width:48,height:48,child:Image.network(preview.isNotEmpty?preview:url,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Text('🎁',style:TextStyle(fontSize:28))));
   }
   return Text(g?['emoji']?.toString()??'🎁',style:const TextStyle(fontSize:28));
 }

 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(_,__)=>Container(
   padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),
   decoration:BoxDecoration(
     borderRadius:BorderRadius.circular(30),
     gradient:const LinearGradient(colors:[Color(0xFF7A3F08),Color(0xFF1A0903),Color(0xFF7A3F08)]),
     border:Border.all(color:giftGold,width:1.5),
     boxShadow:[BoxShadow(color:giftGold.withOpacity(.22+.12*controller.value),blurRadius:16)],
   ),
   child:Row(children:[
     _giftVisual(),
     const SizedBox(width:8),
     Expanded(child:Text('${widget.gift?['name']??'إهداء فخم'} • ${widget.banner['amount']} 🪙',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))),
     const Text('✨',style:TextStyle(fontSize:20)),
   ]),
 ));
}
