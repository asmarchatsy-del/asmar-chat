import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';

class AsmarKeyboard extends StatefulWidget {
  final ValueChanged<String>? onText;
  final ValueChanged<Map<String,dynamic>>? onGift;
  final ValueChanged<String>? onSticker;
  const AsmarKeyboard({super.key,this.onText,this.onGift,this.onSticker});
  @override State<AsmarKeyboard> createState()=>_AsmarKeyboardState();
}
class _AsmarKeyboardState extends State<AsmarKeyboard> {
  int tab=0;
  final emojis=<String>['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😙','😚','😋','😛','😝','😜','🤪','🤨','🧐','🤓','😎','🤩','🥳','😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢','😭','😤','😠','😡','🤬','🤯','😳','🥵','🥶','😱','😨','😰','😥','😓','🤗','🤔','🤭','🤫','🤥','😶','😐','😑','😬','🙄','😯','😦','😧','😮','😲','🥱','😴','🤤','😪','😵','🤐','🥴','🤢','🤮','🤧','😷','🤒','🤕','🤑','🤠','👋','🤚','🖐️','✋','🖖','👌','🤏','✌️','🤞','🤟','🤘','🤙','👏','🙌','👐','🤲','🙏','❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝','💟','✨','⭐','🌟','💫','🔥','🎉','🎊','🎁','💎','👑'];
  @override Widget build(BuildContext context)=>Material(
    color:const Color(0xFF140B07),
    child:SizedBox(height:330,child:Column(children:[
      Container(height:48,decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0x334C3019)))),child:Row(children:[
        _tab('😊','إيموجي',0),_tab('🎁','هدايا',1),_tab('✨','ستيكرات',2),
      ])),
      Expanded(child:tab==0?_emojiGrid():tab==1?_gifts():_stickers()),
    ])),
  );
  Widget _tab(String icon,String title,int value)=>Expanded(child:InkWell(onTap:()=>setState(()=>tab=value),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(icon,style:const TextStyle(fontSize:18)),Text(title,style:TextStyle(fontSize:10,color:tab==value?const Color(0xFFFFD36A):Colors.white54,fontWeight:FontWeight.w800))])));
  Widget _emojiGrid()=>GridView.builder(padding:const EdgeInsets.all(8),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:8),itemCount:emojis.length,itemBuilder:(_,i)=>InkWell(onTap:()=>widget.onText?.call(emojis[i]),child:Center(child:Text(emojis[i],style:const TextStyle(fontSize:25)))));
  Widget _gifts()=>FutureBuilder(future:Supabase.instance.client.from('gifts').select('id,name,emoji,price,asset_type,asset_url,animation_loop').eq('is_active',true).order('price'),builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:Color(0xFFFFD36A)));if(s.hasError)return Center(child:Text('تعذر تحميل الهدايا: ${s.error}'));final rows=List<Map<String,dynamic>>.from(s.data??const[]);if(rows.isEmpty)return const Center(child:Text('لا توجد هدايا'));return GridView.builder(padding:const EdgeInsets.all(8),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:.78),itemCount:rows.length,itemBuilder:(_,i){final g=rows[i];final url=g['asset_url']?.toString()??'';return InkWell(onTap:()=>widget.onGift?.call(g),borderRadius:BorderRadius.circular(12),child:Container(decoration:BoxDecoration(color:const Color(0xFF211108),borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFF5A3515))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Expanded(child:Padding(padding:const EdgeInsets.all(6),child:url.isNotEmpty&&g['asset_type']=='lottie'?Lottie.network(url,repeat:g['animation_loop']==true,errorBuilder:(_,__,___)=>Text(g['emoji']?.toString()??'🎁',style:const TextStyle(fontSize:32))):url.isNotEmpty?Image.network(url,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Text(g['emoji']?.toString()??'🎁',style:const TextStyle(fontSize:32))):Center(child:Text(g['emoji']?.toString()??'🎁',style:const TextStyle(fontSize:32))))),Text(g['name']?.toString()??'',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10)),Text('${g['price']??0} 🪙',style:const TextStyle(color:Color(0xFFFFD36A),fontSize:10,fontWeight:FontWeight.w900)),const SizedBox(height:5)])));});
  Widget _stickers()=>FutureBuilder(future:Supabase.instance.client.from('user_items').select('item_id,item_name,asset_url').eq('user_id',Supabase.instance.client.auth.currentUser!.id).eq('item_type','sticker').order('purchased_at',ascending:false),builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:Color(0xFFFFD36A)));if(s.hasError)return Center(child:Text('تعذر تحميل الستيكرات: ${s.error}'));final rows=List<Map<String,dynamic>>.from(s.data??const[]);if(rows.isEmpty)return const Center(child:Text('لا توجد ستيكرات مملوكة'));return GridView.builder(padding:const EdgeInsets.all(8),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4),itemCount:rows.length,itemBuilder:(_,i){final x=rows[i];return InkWell(onTap:()=>widget.onSticker?.call(x['item_id'].toString()),child:Column(children:[Expanded(child:x['asset_url']?.toString().isNotEmpty==true?Image.network(x['asset_url'].toString()):const Icon(Icons.emoji_emotions,color:Color(0xFFFFD36A),size:35)),Text(x['item_name']?.toString()??'ستيكر',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10))]));});
}
