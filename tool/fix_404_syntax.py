from pathlib import Path
import re

# Repair only Dart syntax/parenthesis damage identified by build 403.
# No LiveKit, WebRTC, Supabase schema, RPC, or voice logic is changed.

p = Path('lib/asmar_keyboard.dart')
p.write_text(r'''import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _bg = Color(0xFF100805);

class AsmarKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final String roomId;
  final void Function(Map<String,dynamic> gift)? onGiftSent;
  const AsmarKeyboard({super.key, required this.controller, required this.onSend, required this.roomId, this.onGiftSent});
  @override State<AsmarKeyboard> createState() => _AsmarKeyboardState();
}

class _AsmarKeyboardState extends State<AsmarKeyboard> {
  int tab = 0;
  bool sending = false;
  List<Map<String,dynamic>> gifts = [];
  final recipient = TextEditingController();
  @override void initState(){super.initState(); _load();}
  @override void dispose(){recipient.dispose(); super.dispose();}
  Future<void> _load() async {
    try {
      final r = await Supabase.instance.client.from('gifts').select('id,name,emoji,price_coins,animation_url,is_active').eq('is_active',true).order('price_coins');
      if(mounted) setState(() => gifts = List<Map<String,dynamic>>.from(r));
    } catch (_) {}
  }
  Future<void> _gift(Map<String,dynamic> g) async {
    final to = recipient.text.trim();
    if(to.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await Supabase.instance.client.rpc('send_gift', params:{'p_room_id':widget.roomId,'p_recipient_id':to,'p_gift_id':g['id']});
      widget.onGiftSent?.call(g);
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إرسال الهدية: $e')));
    } finally { if(mounted) setState(() => sending = false); }
  }
  Widget _tabs() => Row(children:[
    _tab(0,'😊','Emoji'), _tab(1,'🎁','هدايا'), _tab(2,'✨','Stickers')
  ]);
  Widget _tab(int i,String icon,String label) => Expanded(child:InkWell(onTap:()=>setState(()=>tab=i),child:Padding(padding:const EdgeInsets.all(7),child:Column(children:[Text(icon,style:const TextStyle(fontSize:21)),Text(label,style:TextStyle(color:tab==i?_gold:Colors.white60,fontSize:10,fontWeight:FontWeight.w800))]))));
  Widget _content(){
    if(tab==1) return Column(children:[TextField(controller:recipient,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(prefixIcon:Icon(Icons.person_search,color:_gold),hintText:'ID المستلم')),const SizedBox(height:4),Expanded(child:GridView.builder(itemCount:gifts.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,childAspectRatio:.82),itemBuilder:(_,i){final g=gifts[i];return InkWell(onTap:sending?null:()=>_gift(g),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(g['emoji']?.toString()??'🎁',style:const TextStyle(fontSize:28)),Text(g['name']?.toString()??'',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:10)),Text('${g['price_coins']??0} 🪙',style:const TextStyle(color:_gold,fontSize:9))]));}))]);
    final chars = tab==0 ? ['😀','😃','😂','🤣','😊','😍','🥰','😘','😎','🤩','🥳','😢','😭','😡','🤔','😴','🙈','❤️','💕','💯','🔥','✨','🎉','👏','👍','🙏','💎','👑','🌹','🚘','🫶','🤝'] : ['🔥','💖','👑','💎','🎉','🥳','😂','😍','😎','❤️','✨','🌹','🚘','🫶','🤝','🏆'];
    return GridView.count(crossAxisCount:8,children:chars.map((x)=>InkWell(onTap:()=>setState(()=>widget.controller.text+=' $x'),child:Center(child:Text(x,style:const TextStyle(fontSize:27))))).toList());
  }
  @override Widget build(BuildContext context) => Material(color:_bg,child:SafeArea(top:false,child:Container(height:280,padding:const EdgeInsets.fromLTRB(10,6,10,8),decoration:const BoxDecoration(color:_bg,borderRadius:BorderRadius.vertical(top:Radius.circular(24))),child:Column(children:[Row(children:[Expanded(child:TextField(controller:widget.controller,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(hintText:'اكتب رسالة…',prefixIcon:Icon(Icons.alternate_email,color:_gold)))),IconButton(onPressed:widget.onSend,icon:const Icon(Icons.send,color:_gold))]),const Divider(color:Colors.white12),_tabs(),Expanded(child:_content())])));
}
''', encoding='utf-8')

p = Path('lib/widgets/asmar_keyboard.dart')
p.write_text(r'''import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';

class AsmarKeyboard extends StatefulWidget {
  final ValueChanged<String>? onText;
  final ValueChanged<Map<String,dynamic>>? onGift;
  final ValueChanged<String>? onSticker;
  const AsmarKeyboard({super.key,this.onText,this.onGift,this.onSticker});
  @override State<AsmarKeyboard> createState()=>_AsmarKeyboardState();
}
class _AsmarKeyboardState extends State<AsmarKeyboard>{
  int tab=0;
  final emojis=<String>['😀','😃','😄','😁','😆','😂','🤣','😊','😍','🥰','😘','😎','🤩','🥳','😢','😭','😡','🤔','😴','🙈','❤️','💕','💯','🔥','✨','🎉','👏','👍','🙏','💎','👑','🌹'];
  @override Widget build(BuildContext context)=>Material(color:const Color(0xFF140B07),child:SizedBox(height:330,child:Column(children:[Container(height:48,decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0x334C3019)))),child:Row(children:[_tab('😊','إيموجي',0),_tab('🎁','هدايا',1),_tab('✨','ستيكرات',2)])),Expanded(child:tab==0?_emojiGrid():tab==1?_gifts():_stickers())])));
  Widget _tab(String icon,String title,int value)=>Expanded(child:InkWell(onTap:()=>setState(()=>tab=value),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(icon,style:const TextStyle(fontSize:18)),Text(title,style:TextStyle(fontSize:10,color:tab==value?const Color(0xFFFFD36A):Colors.white54,fontWeight:FontWeight.w800))])));
  Widget _emojiGrid()=>GridView.builder(padding:const EdgeInsets.all(8),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:8),itemCount:emojis.length,itemBuilder:(_,i)=>InkWell(onTap:()=>onText(emojis[i]),child:Center(child:Text(emojis[i],style:const TextStyle(fontSize:25)))));
  void onText(String value)=>widget.onText?.call(value);
  Widget _gifts()=>FutureBuilder(future:Supabase.instance.client.from('gifts').select('id,name,emoji,price_coins,animation_url,is_active').eq('is_active',true).order('price_coins'),builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:Color(0xFFFFD36A)));if(s.hasError)return Center(child:Text('تعذر تحميل الهدايا: ${s.error}'));final rows=List<Map<String,dynamic>>.from(s.data??const[]);return GridView.builder(padding:const EdgeInsets.all(8),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4),itemCount:rows.length,itemBuilder:(_,i){final g=rows[i];final url=g['animation_url']?.toString()??'';return InkWell(onTap:()=>widget.onGift?.call(g),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Expanded(child:url.isNotEmpty?Lottie.network(url,errorBuilder:(_,__,___)=>Text(g['emoji']?.toString()??'🎁',style:const TextStyle(fontSize:30))):Text(g['emoji']?.toString()??'🎁',style:const TextStyle(fontSize:30))),Text(g['name']?.toString()??'',maxLines:1,overflow:TextOverflow.ellipsis),Text('${g['price_coins']??0} 🪙',style:const TextStyle(color:Color(0xFFFFD36A),fontSize:10,fontWeight:FontWeight.w900))]));});});
  Widget _stickers()=>FutureBuilder(future:Supabase.instance.client.from('user_items').select('item_id,item_name,asset_url').eq('user_id',Supabase.instance.client.auth.currentUser!.id).eq('item_type','sticker').order('purchased_at',ascending:false),builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:Color(0xFFFFD36A)));if(s.hasError)return Center(child:Text('تعذر تحميل الستيكرات: ${s.error}'));final rows=List<Map<String,dynamic>>.from(s.data??const[]);return GridView.builder(padding:const EdgeInsets.all(8),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4),itemCount:rows.length,itemBuilder:(_,i){final x=rows[i];final u=x['asset_url']?.toString()??'';return InkWell(onTap:()=>widget.onSticker?.call(x['item_id'].toString()),child:Column(children:[Expanded(child:u.isNotEmpty?Image.network(u,fit:BoxFit.contain):const Icon(Icons.emoji_emotions,color:Color(0xFFFFD36A),size:35)),Text(x['item_name']?.toString()??'ستيكر',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10))]));});});
}
''', encoding='utf-8')

p = Path('lib/me_page.dart')
s = p.read_text()
main = r'''class MePage extends StatefulWidget { const MePage({super.key}); @override State<MePage> createState()=>_MePageState(); }
class _MePageState extends State<MePage>{
 Future<Map<String,dynamic>>? _future;
 @override void initState(){super.initState();_reload();}
 void _reload()=>setState(()=>_future=_loadProfile());
 Future<Map<String,dynamic>> _loadProfile()async{final uid=Supabase.instance.client.auth.currentUser?.id;if(uid==null)throw Exception('لا توجد جلسة دخول');final row=await Supabase.instance.client.from('profiles').select('id,username,display_name,bio,avatar_url,avatar_is_animated,public_id,vip_level,svip_level,user_level,recharge_points,coins,diamonds,golden_frame,special_frame').eq('id',uid).maybeSingle();if(row==null)throw Exception('لم يتم العثور على الملف الشخصي');return Map<String,dynamic>.from(row);}
 Future<Map<String,int>> _stats(String uid)async{final c=Supabase.instance.client;final a=await c.from('visitors').select('visitor_id').eq('profile_id',uid);final b=await c.from('follows').select('following_id').eq('follower_id',uid);final d=await c.from('follows').select('follower_id').eq('following_id',uid);return {'visitors':a.length,'following':b.length,'followers':d.length};}
 Future<void> _copyId(String id)async{await Clipboard.setData(ClipboardData(text:id));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نسخ الـID')));}
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:_bg,appBar:AppBar(backgroundColor:_bg,title:const Text('أنا',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsPage())),icon:const Icon(Icons.settings_outlined))]),body:FutureBuilder<Map<String,dynamic>>(future:_future,builder:(context,snap){if(snap.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:_gold));if(snap.hasError||snap.data==null)return Center(child:Text('تعذر تحميل الملف: ${snap.error??''}'));final p=snap.data!;final uid=p['id'].toString();final publicId=p['public_id']?.toString()??'---';final name=(p['display_name']?.toString().isNotEmpty==true)?p['display_name'].toString():(p['username']?.toString()??'مستخدم');final avatar=p['avatar_url']?.toString()??'';final level=(p['user_level'] as num?)?.toInt()??1;final aristocracy=p['vip_level']?.toString()??'';final specialLevel=(p['svip_level'] as num?)?.toInt()??0;return RefreshIndicator(color:_gold,onRefresh:()async{_reload();await _future;},child:ListView(padding:const EdgeInsets.fromLTRB(14,8,14,28),children:[InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>EditProfilePage(profile:p))).then((_)=>_reload()),borderRadius:BorderRadius.circular(24),child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF3A1C08),Color(0xFF160B06)]),borderRadius:BorderRadius.circular(24),border:Border.all(color:_gold2)),child:Row(children:[SecretAdminAvatarTrigger(publicId:publicId,child:RankFrame(role:'USER',vipLevel:aristocracy.isEmpty?null:aristocracy,size:96,child:CircleAvatar(radius:34,backgroundColor:const Color(0xFF100804),backgroundImage:avatar.isEmpty?null:NetworkImage(avatar),child:avatar.isEmpty?const Icon(Icons.person,color:_gold,size:34):null))),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),Row(children:[Text('ID: $publicId',style:const TextStyle(color:_gold,fontWeight:FontWeight.w800)),IconButton(visualDensity:VisualDensity.compact,onPressed:()=>_copyId(publicId),icon:const Icon(Icons.copy,size:18,color:_gold))]),Text(p['bio']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white60,fontSize:12))])),const Icon(Icons.edit_outlined,color:_gold)]))),const SizedBox(height:12),FutureBuilder<Map<String,int>>(future:_stats(uid),builder:(context,s){final st=s.data??const {'visitors':0,'following':0,'followers':0};return Row(children:[Expanded(child:_StatButton('الزوار',st['visitors']!,Icons.visibility_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>VisitorsPage(profileId:uid))))),Expanded(child:_StatButton('المتابَعون',st['following']!,Icons.person_add_alt_1_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RelationshipPage(title:'المتابَعون',followerId:uid))))),Expanded(child:_StatButton('المتابعون',st['followers']!,Icons.people_outline,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RelationshipPage(title:'المتابعون',followingId:uid)))))]);}),const SizedBox(height:12),Row(children:[Expanded(child:_MembershipCard(title:'أرستقراطية',subtitle:aristocracy.isEmpty?'اشترِ العضوية':'المستوى $aristocracy',icon:Icons.workspace_premium_outlined,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AristocracyStorePage(special:false))).then((_)=>_reload()))),const SizedBox(width:8),Expanded(child:_MembershipCard(title:'أرستقراطية مميزة',subtitle:specialLevel>0?'المستوى $specialLevel':'الدخول المميز',icon:Icons.diamond_outlined,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AristocracyStorePage(special:true))).then((_)=>_reload())))]),const SizedBox(height:12),_QuickRow([_QuickAction('المحفظة',Icons.account_balance_wallet_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const WalletPage()))),_QuickAction('المتجر',Icons.storefront_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const StorePage()))),_QuickAction('الشنطة',Icons.shopping_bag_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MyBagPage()))]),const SizedBox(height:10),_MenuCard([_MenuItem('العائلة',Icons.family_restroom,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const FamilyCenterPage()))),_MenuItem('CP',Icons.favorite_outline,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CpCenterPage()))),_MenuItem('الأخ والأخت',Icons.people_alt_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SiblingsPage()))),_MenuItem('المستوى',Icons.stars_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const LevelCenterPage()))),_MenuItem('مركز المضيف',Icons.mic_external_on_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HostCenterPage()))),_MenuItem('تواصل مع المسؤول الرسمي',Icons.support_agent_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CustomerServicePage()))),_MenuItem('الإعدادات',Icons.settings_outlined,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsPage()))]),const SizedBox(height:12),Text('مستوى المستخدم $level',style:const TextStyle(color:_gold,fontWeight:FontWeight.w800)),const SizedBox(height:5),FutureBuilder<Map<String,dynamic>?>(future:Supabase.instance.client.from('user_exp').select().eq('user_id',uid).maybeSingle(),builder:(_,e){final exp=(e.data?['user_exp'] as num?)?.toInt()??0;return LinearProgressIndicator(value:(exp%1000)/1000,color:_gold,backgroundColor:Colors.white12);})]));}));
}
'''
s=re.sub(r'class MePage extends StatefulWidget.*?\nclass _StatButton', main+'\nclass _StatButton', s, count=1, flags=re.S)
quick=r'''class _QuickRow extends StatelessWidget{final List<_QuickAction> items;const _QuickRow(this.items);@override Widget build(BuildContext context){return Row(children:items.map((e)=>Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:InkWell(onTap:e.onTap,borderRadius:BorderRadius.circular(14),child:Container(height:74,decoration:BoxDecoration(color:_card,borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFF5A3515))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(e.icon,color:_gold,size:25),const SizedBox(height:5),Text(e.label,style:const TextStyle(fontSize:11,color:Colors.white70))])))))).toList());}}
'''
s=re.sub(r'class _QuickRow extends StatelessWidget.*?\nclass _MenuItem',quick+'class _MenuItem',s,count=1,flags=re.S)
store=r'''class AristocracyStorePage extends StatelessWidget{final bool special;const AristocracyStorePage({super.key,required this.special});Future<void> _buy(BuildContext context,Map<String,dynamic> p)async{try{final r=await Supabase.instance.client.rpc('purchase_aristocracy_package',params:{'p_package_id':p['id']});if(context.mounted){final m=Map<String,dynamic>.from(r as Map);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم الشراء الحقيقي. الرصيد الجديد: ${m['balance']}')));Navigator.pop(context);}}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الشراء: $e')));}}@override Widget build(BuildContext context){return Scaffold(backgroundColor:_bg,appBar:AppBar(title:Text(special?'أرستقراطية مميزة':'أرستقراطية')),body:FutureBuilder(future:Supabase.instance.client.from('aristocracy_packages').select().eq('tier',special?'aristocracy_special':'aristocracy').eq('is_active',true).order('price_usd'),builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator(color:_gold));if(s.hasError)return Center(child:Text('تعذر تحميل الباقات: ${s.error}'));final rows=List<Map<String,dynamic>>.from(s.data??const[]);return ListView(padding:const EdgeInsets.all(16),children:rows.map((p)=>Card(color:_card,child:ListTile(leading:Icon(special?Icons.diamond:Icons.workspace_premium,color:_gold,size:34),title:Text(p['name'].toString(),style:const TextStyle(color:_gold,fontWeight:FontWeight.w900)),subtitle:Text('${p['billing_period']=='monthly'?'شهري':'سنوي'} • \\$${p['price_usd']} • ${p['coin_price']??'-'} كوين'),trailing:FilledButton(onPressed:()=>_buy(context,p),child:const Text('شراء')))).toList());}));}}
'''
s=re.sub(r'class AristocracyStorePage extends StatelessWidget.*?\nclass MyBagPage',store+'\nclass MyBagPage',s,count=1,flags=re.S)
level=r'''class LevelCenterPage extends StatelessWidget{const LevelCenterPage({super.key});@override Widget build(BuildContext context){return FutureBuilder(future:Supabase.instance.client.from('user_exp').select().eq('user_id',Supabase.instance.client.auth.currentUser!.id).maybeSingle(),builder:(_,s){if(s.connectionState!=ConnectionState.done)return const Scaffold(body:Center(child:CircularProgressIndicator()));final d=Map<String,dynamic>.from(s.data??{'user_exp':0,'host_exp':0});return Scaffold(backgroundColor:_bg,appBar:AppBar(title:const Text('مركز المستوى')),body:ListView(padding:const EdgeInsets.all(18),children:[_LevelCard('مستوى المستخدم',(d['user_exp'] as num?)?.toInt()??0),const SizedBox(height:12),_LevelCard('مستوى المضيف',(d['host_exp'] as num?)?.toInt()??0)]));});}}
'''
s=re.sub(r'class LevelCenterPage extends StatelessWidget.*?\nclass HostCenterPage',level+'\nclass HostCenterPage',s,count=1,flags=re.S)
host=r'''class HostCenterPage extends StatelessWidget{const HostCenterPage({super.key});@override Widget build(BuildContext context){return FutureBuilder(future:Supabase.instance.client.from('host_earnings').select().eq('host_id',Supabase.instance.client.auth.currentUser!.id).order('created_at',ascending:false),builder:(_,s){if(s.connectionState!=ConnectionState.done)return const Scaffold(body:Center(child:CircularProgressIndicator()));if(s.hasError)return Scaffold(body:Center(child:Text('${s.error}')));final rows=List<Map<String,dynamic>>.from(s.data??const[]);final total=rows.fold<num>(0,(a,r)=>a+((r['host_amount'] as num?)??0));return Scaffold(backgroundColor:_bg,appBar:AppBar(title:const Text('مركز المضيف')),body:ListView(padding:const EdgeInsets.all(16),children:[Card(color:_card,child:ListTile(title:const Text('الأرباح'),trailing:Text('$total'))),const SizedBox(height:12),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HostWithdrawPage())),child:const Text('سحب'))]));});}}
'''
s=re.sub(r'class HostCenterPage extends StatelessWidget.*?\nclass HostWithdrawPage',host+'\nclass HostWithdrawPage',s,count=1,flags=re.S)
p.write_text(s,encoding='utf-8')

p=Path('lib/super_admin_panel.dart');s=p.read_text()
users=r'''Widget _users()=>ListView(children:[const Text('إدارة المستخدمين',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:_gold)),...users.map((u)=>card('${u['display_name']??u['username']??'مستخدم'} • ID ${u['public_id']??''}','Coins: ${u['coins']??0} • Level: ${u['vip_level']??0}',(){showModalBottomSheet(context:context,builder:(_)=>Column(mainAxisSize:MainAxisSize.min,children:[ListTile(title:const Text('إعطاء 1000 كوين'),onTap:(){Navigator.pop(context);action('coins',u['id'].toString(),amount:1000);}),ListTile(title:const Text('إعطاء أرستقراطية مستوى 10'),onTap:(){Navigator.pop(context);action('vip',u['id'].toString(),vip:10);}),ListTile(title:Text(u['is_blocked']==true?'فك الحظر':'حظر'),onTap:(){Navigator.pop(context);action(u['is_blocked']==true?'unblock':'block',u['id'].toString());})]));},()=>action(u['is_blocked']==true?'unblock':'block',u['id'].toString()))]);
'''
s=re.sub(r'Widget _users\(\)=>ListView\(children:\[const Text\(.*?\nWidget _packages',users+'Widget _packages',s,count=1,flags=re.S)
build=r'''@override Widget build(BuildContext context){return Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:_bg,appBar:AppBar(title:const Text('SUPER ADMIN',style:TextStyle(color:_gold,fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator(color:_gold)):Row(children:[NavigationRail(backgroundColor:_card,selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),labelType:NavigationRailLabelType.all,destinations:const[NavigationRailDestination(icon:Icon(Icons.dashboard_outlined),label:Text('الرئيسية')),NavigationRailDestination(icon:Icon(Icons.people_outline),label:Text('المستخدمون')),NavigationRailDestination(icon:Icon(Icons.monetization_on_outlined),label:Text('الباقات')),NavigationRailDestination(icon:Icon(Icons.card_giftcard),label:Text('الهدايا')),NavigationRailDestination(icon:Icon(Icons.storefront_outlined),label:Text('المتجر')),NavigationRailDestination(icon:Icon(Icons.meeting_room_outlined),label:Text('الغرف'))]),Expanded(child:Padding(padding:const EdgeInsets.all(16),child:_body()))]));}
}
'''
s=re.sub(r'@override Widget build\(BuildContext context\)=>Directionality\(.*?\n\}',build,s,count=1,flags=re.S)
p.write_text(s,encoding='utf-8')
