import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SvipPage extends StatefulWidget {
  const SvipPage({super.key});
  @override State<SvipPage> createState() => _SvipPageState();
}
class _SvipPageState extends State<SvipPage> {
  bool loading=true; int level=0; int monthlyPoints=0;
  List<Map<String,dynamic>> levels=[]; Map<int,List<Map<String,dynamic>>> gifts={};
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    try {
      final c=Supabase.instance.client; final u=c.auth.currentUser; if(u==null)return;
      final p=await c.from('profiles').select('svip_level').eq('id',u.id).maybeSingle();
      final month=DateTime(DateTime.now().year,DateTime.now().month,1);
      final mp=await c.from('svip_monthly_points').select('points').eq('user_id',u.id)
        .eq('month_start',month.toIso8601String().substring(0,10)).maybeSingle();
      final ls=await c.from('svip_levels').select('level,name,min_recharge_points,perks').eq('is_active',true).order('level');
      final ps=await c.from('svip_gift_package_items').select('level,quantity,gifts(id,name,emoji,asset_type,asset_url,preview_url,is_active)').order('level');
      final grouped=<int,List<Map<String,dynamic>>>{};
      for(final row in ps){final l=(row['level'] as num).toInt(); final g=row['gifts'];
        if(g is Map && g['is_active']==true){grouped.putIfAbsent(l,()=>[]).add({...Map<String,dynamic>.from(g),'quantity':row['quantity']});}}
      if(!mounted)return; setState((){level=(p?['svip_level'] as num?)?.toInt()??0;monthlyPoints=(mp?['points'] as num?)?.toInt()??0;levels=ls.map((x)=>Map<String,dynamic>.from(x)).toList();gifts=grouped;loading=false;});
    } catch(_){if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    backgroundColor:const Color(0xFF090604),
    appBar:AppBar(title:const Text('SVIP',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(14),children:[
      _summary(),const SizedBox(height:16),const Text('مستويات SVIP',style:TextStyle(color:Color(0xFFFFD36A),fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:10),...levels.map(_levelCard)]),
  ));
  Widget _summary()=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF6B2C0B),Color(0xFF160A06)]),border:Border.all(color:const Color(0xFFB77921))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(level>0?'SVIP '+level.toString():'بدون SVIP',style:const TextStyle(color:Color(0xFFFFD36A),fontSize:25,fontWeight:FontWeight.w900)),
    const SizedBox(height:6),Text(monthlyPoints.toString()+' نقطة هذا الشهر',style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.bold)),
    const SizedBox(height:5),const Text('كل 100 Coins شحن فعلي = نقطة SVIP واحدة',style:TextStyle(color:Colors.white60,fontSize:11)),
    const SizedBox(height:5),const Text('النقاط شهرية، والمستوى الحالي يستمر إلى الشهر التالي وفق نظام SVIP.',style:TextStyle(color:Colors.white54,fontSize:11))]));
  Widget _levelCard(Map<String,dynamic> row){
    final l=(row['level'] as num).toInt(); final active=level==l; final req=(row['min_recharge_points'] as num).toInt(); final pack=gifts[l]??const <Map<String,dynamic>>[];
    return Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(16),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),color:const Color(0xFF160A06),border:Border.all(color:active?const Color(0xFFFFD36A):const Color(0xFF4C2B12),width:active?2:1)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Text('SVIP '+l.toString(),style:const TextStyle(color:Color(0xFFFFD36A),fontSize:19,fontWeight:FontWeight.w900)),const Spacer(),if(active)const Chip(label:Text('مفعّل'),avatar:Icon(Icons.verified,size:16))]),
      const SizedBox(height:5),Text(req.toString()+' نقطة = '+(req*100).toString()+' Coins شحن',style:const TextStyle(color:Colors.white70,fontSize:12)),
      const SizedBox(height:12),const Text('بكج الهدايا',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),const SizedBox(height:8),
      if(pack.isEmpty)const Text('لا توجد هدايا مفعلة لهذا المستوى حالياً',style:TextStyle(color:Colors.white38,fontSize:11))
      else Wrap(spacing:8,runSpacing:8,children:pack.map((g)=>Chip(avatar:Text((g['emoji']??'🎁').toString(),style:const TextStyle(fontSize:18)),label:Text(g['name'].toString()+' ×'+g['quantity'].toString()))).toList())
    ]));
  }
}