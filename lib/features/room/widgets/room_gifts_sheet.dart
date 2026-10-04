import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../asmar/asmar_theme.dart';

class RoomGiftsSheet extends StatefulWidget {
  const RoomGiftsSheet({super.key, required this.roomId, required this.members});
  final String roomId; final List<String> members;
  @override State<RoomGiftsSheet> createState() => _RoomGiftsSheetState();
}

class _RoomGiftsSheetState extends State<RoomGiftsSheet> {
  final client = Supabase.instance.client;
  int category = 0, count = 1, selected = 0; String? recipient;
  late Future<List<Map<String,dynamic>>> future;
  static const categories = ['Popular','Lucky','Couple','Relationship','Funny','Customize','Flag'];
  @override void initState(){super.initState();future=_load();}
  Future<List<Map<String,dynamic>>> _load() async => List<Map<String,dynamic>>.from(await client.from('gifts').select('id,name,emoji,price,category,asset_url,preview_url').eq('is_active',true).order('price'));
  Future<void> _send(Map<String,dynamic> gift) async {
    final id = recipient;
    if(id == null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اختر مستلم الهدية أولاً')));return;}
    try {
      await client.rpc('send_gift_real', params: {'p_room_id':widget.roomId,'p_recipient_id':id,'p_gift_id':gift['id'],'p_quantity':count});
      if(mounted){Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم إرسال $count × ${gift['name']}')));}
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إرسال الهدية: $e')));}
  }
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Container(
      height: MediaQuery.sizeOf(context).height * .78,
      decoration: const BoxDecoration(color: Color(0xFF100A18), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(top:false, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18,16,12,6), child: Row(children: [const Text('الهدايا',style:TextStyle(color:AsmarTheme.gold,fontSize:20,fontWeight:FontWeight.w900)),const Spacer(),IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close,color:Colors.white54))])),
        if(widget.members.isNotEmpty) SizedBox(height:48,child:ListView.separated(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),itemCount:widget.members.length,separatorBuilder:(_,__)=>const SizedBox(width:6),itemBuilder:(_,i)=>ChoiceChip(label:Text('مقعد ${i+1}'),selected:recipient==widget.members[i],onSelected:(_)=>setState(()=>recipient=widget.members[i]),selectedColor:AsmarTheme.gold,backgroundColor:AsmarTheme.surface,labelStyle:TextStyle(color:recipient==widget.members[i]?Colors.black:Colors.white70)))),
        SizedBox(height:45,child:ListView.separated(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),itemCount:categories.length,separatorBuilder:(_,__)=>const SizedBox(width:6),itemBuilder:(_,i)=>ChoiceChip(label:Text(categories[i],style:const TextStyle(fontSize:11)),selected:i==category,onSelected:(_)=>setState(()=>category=i),selectedColor:AsmarTheme.gold,backgroundColor:AsmarTheme.surface,labelStyle:TextStyle(color:i==category?Colors.black:Colors.white70)))),
        Expanded(child:FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:AsmarTheme.gold));if(s.hasError)return Center(child:Text('تعذر تحميل الهدايا: ${s.error}'));final gifts=s.data??[];if(gifts.isEmpty)return const Center(child:Text('لا توجد هدايا'));return GridView.builder(padding:const EdgeInsets.all(14),itemCount:gifts.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:8,mainAxisSpacing:10,childAspectRatio:.78),itemBuilder:(_,i){final g=gifts[i];final on=i==selected;return InkWell(onTap:()=>setState(()=>selected=i),child:Container(decoration:BoxDecoration(color:on?const Color(0x553A250F):AsmarTheme.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:on?AsmarTheme.gold:Colors.white10)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text((g['emoji']??'🎁').toString(),style:const TextStyle(fontSize:30)),const SizedBox(height:5),Text(g['name'].toString(),textAlign:TextAlign.center,maxLines:2,style:const TextStyle(color:Colors.white,fontSize:9)),Text('${g['price']} 🪙',style:const TextStyle(color:AsmarTheme.gold,fontSize:9,fontWeight:FontWeight.bold))])));});}),),
        Padding(padding:const EdgeInsets.fromLTRB(12,4,12,12),child:Row(children:[const Text('العدد:',style:TextStyle(color:Colors.white70)),const SizedBox(width:8),...[1,7,17,77,177].map((n)=>Padding(padding:const EdgeInsets.only(left:4),child:ChoiceChip(label:Text('$n'),selected:n==count,onSelected:(_)=>setState(()=>count=n),selectedColor:AsmarTheme.gold,backgroundColor:AsmarTheme.surface,labelStyle:TextStyle(color:n==count?Colors.black:Colors.white)))),const Spacer(),FilledButton(onPressed:()=>future.then((items){if(items.isNotEmpty)_send(items[selected]);}),style:FilledButton.styleFrom(backgroundColor:AsmarTheme.gold,foregroundColor:Colors.black),child:const Text('إرسال'))]))
      ]),
    ),
  );
}
