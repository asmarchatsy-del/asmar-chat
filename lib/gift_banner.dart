import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const giftGold = Color(0xFFFFD36A);

class GlobalGiftBanner extends StatefulWidget {
  final Widget child;
  final void Function(String roomId, String roomName)? onRoomTap;
  const GlobalGiftBanner({super.key, required this.child, this.onRoomTap});
  @override State<GlobalGiftBanner> createState()=>_GlobalGiftBannerState();
}
class _GlobalGiftBannerState extends State<GlobalGiftBanner>{
  StreamSubscription<List<Map<String,dynamic>>>? sub; Map<String,dynamic>? banner; Timer? hideTimer;
  @override void initState(){super.initState();sub=Supabase.instance.client.from('global_gift_events').stream(primaryKey:['id']).order('created_at',ascending:false).limit(1).listen((rows){if(rows.isEmpty||!mounted)return;final next=rows.first;setState(()=>banner=next);hideTimer?.cancel();hideTimer=Timer(const Duration(seconds:5),(){if(mounted)setState(()=>banner=null);});});}
  @override void dispose(){sub?.cancel();hideTimer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>Stack(children:[widget.child,if(banner!=null)Positioned(top:MediaQuery.of(context).padding.top+8,left:10,right:10,child:Material(color:Colors.transparent,child:InkWell(onTap:(){final id=banner!['room_id']?.toString();final name=banner!['room_name']?.toString()??'غرفة';if(id!=null&&id.isNotEmpty)widget.onRoomTap?.call(id,name);},borderRadius:BorderRadius.circular(30),child:_GiftTicker(banner:banner!))))]);
}
class _GiftTicker extends StatefulWidget{final Map<String,dynamic> banner;const _GiftTicker({required this.banner});@override State<_GiftTicker> createState()=>_GiftTickerState();}
class _GiftTickerState extends State<_GiftTicker> with SingleTickerProviderStateMixin{late final AnimationController controller;@override void initState(){super.initState();controller=AnimationController(vsync:this,duration:const Duration(milliseconds:900))..repeat(reverse:true);}@override void dispose(){controller.dispose();super.dispose();}@override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(_,__)=>SlideTransition(position:Tween<Offset>(begin:const Offset(0,-1),end:Offset.zero).animate(CurvedAnimation(parent:controller,curve:Curves.easeOut)),child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),gradient:const LinearGradient(colors:[Color(0xFF8B4B0A),Color(0xFF130703),Color(0xFF8B4B0A)]),border:Border.all(color:giftGold,width:1.5),boxShadow:[BoxShadow(color:Color(0x66FFD36A),blurRadius:18)]),child:Row(children:[const Text('🎁',style:TextStyle(fontSize:26)),const SizedBox(width:8),Expanded(child:Text('🎁 ${widget.banner['sender_name']} أهدى ${widget.banner['gift_name']} لـ ${widget.banner['receiver_name']}',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))),const SizedBox(width:6),Text('${widget.banner['gift_value']} 🪙',style:const TextStyle(color:giftGold,fontWeight:FontWeight.w900)),const SizedBox(width:5),const Text('✨',style:TextStyle(fontSize:18))]))));}
}