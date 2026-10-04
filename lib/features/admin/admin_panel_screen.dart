import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _bg = Color(0xFF090604);
const _card = Color(0xFF1B0E08);

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final supabase = Supabase.instance.client;
  int tab = 0;
  bool loading = false;
  String? error;
  List<Map<String,dynamic>> users = [], rooms = [], gifts = [], store = [];
  Map<String,dynamic> settings = {};
  final search = TextEditingController();

  @override void initState(){ super.initState(); _load(); }
  Future<bool> _authorized() async {
    final u = supabase.auth.currentUser;
    if (u == null || u.email?.toLowerCase() != 'admin@asmar.com') return false;
    final row = await supabase.from('admin_roles').select('role,enabled').eq('user_id', u.id).maybeSingle();
    return row?['enabled'] == true && const ['CEO','SUPER_ADMIN','ADMIN'].contains((row?['role'] ?? '').toString().toUpperCase());
  }
  Future<void> _load() async {
    setState(() { loading=true; error=null; });
    try {
      if (!await _authorized()) throw Exception('ليس لديك صلاحية Admin');
      final r = await Future.wait([
        supabase.from('profiles').select('id,display_name,username,public_id,role,is_active,coins,diamonds,vip_level').order('created_at',ascending:false).limit(500),
        supabase.from('rooms').select('id,name,owner_id,is_active,seat_count,hot_score,cover_url,background_url').order('created_at',ascending:false).limit(300),
        supabase.from('gifts').select('id,name,emoji,price,is_active,category,asset_url,preview_url').order('name'),
        supabase.from('store_items').select('id,name,category,price_coins,image,description,is_active,rarity').order('created_at',ascending:false).limit(500),
        supabase.from('app_settings').select('key,int_value'),
      ]);
      if(!mounted)return;
      setState(() { users=List<Map<String,dynamic>>.from(r[0] as List); rooms=List<Map<String,dynamic>>.from(r[1] as List); gifts=List<Map<String,dynamic>>.from(r[2] as List); store=List<Map<String,dynamic>>.from(r[3] as List); settings={for(final x in (r[4] as List)) x['key'].toString():x['int_value']}; });
    } catch(e){ if(mounted)setState(()=>error=e.toString()); } finally { if(mounted)setState(()=>loading=false); }
  }
  Future<void> _editBalance(Map<String,dynamic> u) async {
    final c=TextEditingController(text:'${u['coins']??0}'); final d=TextEditingController(text:'${u['diamonds']??0}');
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:Text('تعديل ${u['display_name']??u['username']??'مستخدم'}'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'ذهب')),TextField(controller:d,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'ألماس'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حفظ'))]));
    if(ok!=true)return;
    await supabase.from('profiles').update({'coins':int.tryParse(c.text)??0,'diamonds':int.tryParse(d.text)??0}).eq('id',u['id']); await _load();
  }
  Future<void> _toggleUser(Map<String,dynamic> u) async { await supabase.from('profiles').update({'is_active':!(u['is_active']==true)}).eq('id',u['id']); await _load(); }
  Future<void> _toggleRoom(Map<String,dynamic> r) async { await supabase.from('rooms').update({'is_active':!(r['is_active']==true)}).eq('id',r['id']); await _load(); }
  Future<void> _editGift([Map<String,dynamic>? old]) async { final n=TextEditingController(text:'${old?['name']??''}');final p=TextEditingController(text:'${old?['price']??0}');final e=TextEditingController(text:'${old?['emoji']??'🎁'}'); final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:Text(old==null?'إضافة هدية':'تعديل هدية'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:e,decoration:const InputDecoration(labelText:'Emoji')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حفظ'))]));if(ok!=true)return; final data={'name':n.text.trim(),'emoji':e.text.trim(),'price':int.tryParse(p.text)??0,'is_active':true}; if(old==null){data['id']='gift_${DateTime.now().millisecondsSinceEpoch}';await supabase.from('gifts').insert(data);}else await supabase.from('gifts').update(data).eq('id',old['id']);await _load(); }
  Future<void> _editStore([Map<String,dynamic>? old]) async { final n=TextEditingController(text:'${old?['name']??''}');final p=TextEditingController(text:'${old?['price_coins']??0}');final cat=TextEditingController(text:'${old?['category']??'car'}'); final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:Text(old==null?'إضافة منتج':'تعديل منتج'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:cat,decoration:const InputDecoration(labelText:'الفئة')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'سعر الذهب'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حفظ'))]));if(ok!=true)return;final data={'name':n.text.trim(),'category':cat.text.trim(),'price_coins':int.tryParse(p.text)??0,'is_active':true};if(old==null){data['id']='item_${DateTime.now().millisecondsSinceEpoch}';await supabase.from('store_items').insert(data);}else await supabase.from('store_items').update(data).eq('id',old['id']);await _load();}
  Future<void> _set777() async { final c=TextEditingController(text:'${settings['lucky_777']??777}'); final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('رقم الحظ'),content:TextField(controller:c,keyboardType:TextInputType.number),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حفظ'))]));if(ok==true){await supabase.from('app_settings').upsert({'key':'lucky_777','int_value':int.tryParse(c.text)??777});await _load();}}
  @override Widget build(BuildContext context){ final session=supabase.auth.currentSession; if(session==null)return _login(); if(error!=null)return _error(); return Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:_bg,appBar:AppBar(backgroundColor:_card,title:const Text('Asmar Admin',style:TextStyle(color:_gold,fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh)),IconButton(onPressed:()=>supabase.auth.signOut(),icon:const Icon(Icons.logout))]),body:loading?const Center(child:CircularProgressIndicator(color:_gold)):Row(children:[NavigationRail(backgroundColor:_card,selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),labelType:NavigationRailLabelType.all,selectedIconTheme:const IconThemeData(color:_gold),destinations:const[NavigationRailDestination(icon:Icon(Icons.people),label:Text('المستخدمين')),NavigationRailDestination(icon:Icon(Icons.meeting_room),label:Text('الغرف')),NavigationRailDestination(icon:Icon(Icons.card_giftcard),label:Text('الهدايا')),NavigationRailDestination(icon:Icon(Icons.store),label:Text('المتجر')),NavigationRailDestination(icon:Icon(Icons.settings),label:Text('الإعدادات'))]),Expanded(child:Padding(padding:const EdgeInsets.all(18),child:_content()))])); }
  Widget _login()=>Scaffold(backgroundColor:_bg,body:Center(child:SizedBox(width:420,child:Card(color:_card,child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.admin_panel_settings,color:_gold,size:60),const SizedBox(height:14),const Text('Asmar Admin',style:TextStyle(color:_gold,fontSize:26,fontWeight:FontWeight.w900)),const SizedBox(height:20),_AdminLogin(onDone:_load)])))));
  Widget _error()=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.lock,color:_gold,size:54),const SizedBox(height:12),Text(error!,style:const TextStyle(color:Colors.white70)),const SizedBox(height:12),FilledButton(onPressed:()=>setState(()=>error=null),child:const Text('رجوع'))]));
  Widget _content()=>switch(tab){0=>_users(),1=>_rooms(),2=>_gifts(),3=>_store(),_=>_settings()};
  Widget _users(){final q=search.text.toLowerCase();final rows=users.where((u)=>'${u['display_name']} ${u['username']} ${u['public_id']}'.toLowerCase().contains(q)).toList();return Column(children:[Row(children:[Expanded(child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'بحث بالاسم أو ID'))),const SizedBox(width:12),Text('${rows.length} مستخدم')]),const SizedBox(height:12),Expanded(child:ListView.builder(itemCount:rows.length,itemBuilder:(_,i){final u=rows[i];return _row(icon:Icons.person,title:'${u['display_name']??u['username']??'مستخدم'}',sub:'ID ${u['public_id']??u['id']} • ${u['role']??'USER'}',trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>_editBalance(u),icon:const Icon(Icons.account_balance_wallet,color:_gold)),IconButton(onPressed:()=>_toggleUser(u),icon:Icon(u['is_active']==true?Icons.lock_open:Icons.lock,color:_gold))]));}))]);}
  Widget _rooms()=>ListView(children:rooms.map((r)=>_row(icon:Icons.meeting_room,title:'${r['name']??'غرفة'}',sub:'${r['id']} • ${r['seat_count']??15} مقعد • Hot ${r['hot_score']??0}',trailing:Switch(value:r['is_active']==true,activeColor:_gold,onChanged:(_)=>_toggleRoom(r)))).toList());
  Widget _gifts()=>Column(children:[Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:()=>_editGift(),icon:const Icon(Icons.add),label:const Text('إضافة هدية'))),const SizedBox(height:10),Expanded(child:ListView(children:gifts.map((g)=>_row(icon:Icons.card_giftcard,title:'${g['emoji']??'🎁'} ${g['name']}',sub:'${g['price']} ذهب • ${g['category']??'Popular'}',trailing:Wrap(children:[IconButton(onPressed:()=>_editGift(g),icon:const Icon(Icons.edit,color:_gold)),IconButton(onPressed:()=>supabase.from('gifts').update({'is_active':false}).eq('id',g['id']).then((_){_load();}),icon:const Icon(Icons.delete_outline,color:Colors.redAccent))]))).toList()))]);
  Widget _store()=>Column(children:[Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:()=>_editStore(),icon:const Icon(Icons.add),label:const Text('إضافة منتج'))),const SizedBox(height:10),Expanded(child:ListView(children:store.map((s)=>_row(icon:Icons.store,title:'${s['name']}',sub:'${s['category']} • ${s['price_coins']} ذهب • ${s['rarity']??''}',trailing:Wrap(children:[IconButton(onPressed:()=>_editStore(s),icon:const Icon(Icons.edit,color:_gold)),IconButton(onPressed:()=>supabase.from('store_items').update({'is_active':false}).eq('id',s['id']).then((_){_load();}),icon:const Icon(Icons.delete_outline,color:Colors.redAccent))]))).toList()))]);
  Widget _settings()=>ListView(children:[_row(icon:Icons.card_giftcard,title:'رقم الحظ 777',sub:'القيمة الحالية: ${settings['lucky_777']??777}',trailing:IconButton(onPressed:_set777,icon:const Icon(Icons.edit,color:_gold))),_row(icon:Icons.gamepad,title:'أسعار الألعاب',sub:'تُحفظ عبر app_settings',trailing:const Icon(Icons.chevron_left,color:_gold)),_row(icon:Icons.campaign,title:'رسالة ترحيب الغرف',sub:'تُدار من إعدادات النظام الحالية',trailing:const Icon(Icons.chevron_left,color:_gold))]);
  Widget _row({required IconData icon,required String title,required String sub,required Widget trailing})=>Container(margin:const EdgeInsets.only(bottom:9),decoration:BoxDecoration(color:_card,borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white10)),child:ListTile(leading:Icon(icon,color:_gold),title:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),subtitle:Text(sub,style:const TextStyle(color:Colors.white54)),trailing:trailing));
}

class _AdminLogin extends StatefulWidget{const _AdminLogin({required this.onDone});final VoidCallback onDone;@override State<_AdminLogin> createState()=>_AdminLoginState();}
class _AdminLoginState extends State<_AdminLogin>{final e=TextEditingController(text:'admin@asmar.com');final p=TextEditingController();bool busy=false;String? err;Future<void> go()async{setState(()=>busy=true);try{await Supabase.instance.client.auth.signInWithPassword(email:e.text.trim(),password:p.text);widget.onDone();}catch(x){setState(()=>err='فشل تسجيل الدخول أو الحساب غير مخول.');}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext context)=>Column(children:[TextField(controller:e,decoration:const InputDecoration(labelText:'البريد الإلكتروني')),TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'كلمة المرور')),if(err!=null)Text(err!,style:const TextStyle(color:Colors.redAccent)),const SizedBox(height:16),SizedBox(width:double.infinity,height:48,child:FilledButton(onPressed:busy?null:go,child:Text(busy?'...':'دخول الأدمن')))]);}
