import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSvipPage extends StatefulWidget {
  const AdminSvipPage({super.key});
  @override State<AdminSvipPage> createState()=>_AdminSvipPageState();
}
class _AdminSvipPageState extends State<AdminSvipPage>{
  final c=Supabase.instance.client; bool loading=true;
  List<Map<String,dynamic>> levels=[]; List<Map<String,dynamic>> gifts=[];
  Map<int,Set<String>> selected={}; Map<int,Map<String,int>> quantities={};
  final thresholds={1:50000,2:200000,3:500000,4:1000000,5:2000000,6:3000000};
  @override void initState(){super.initState();_load();}
  Future<void> _load() async{
    try{
      final l=await c.from('svip_levels').select('level,name,min_recharge_points,is_active').order('level');
      final g=await c.from('gifts').select('id,name,emoji,asset_type,asset_url,preview_url,is_active').eq('is_active',true).order('name');
      final gi=await c.from('svip_gift_package_items').select('level,gift_id,quantity');
      final s=<int,Set<String>>{}; final q=<int,Map<String,int>>{};
      for(final x in gi){final n=(x['level'] as num).toInt();s.putIfAbsent(n,()=>{}).add(x['gift_id'].toString());q.putIfAbsent(n,()=>{})[x['gift_id'].toString()]=(x['quantity'] as num).toInt();}
      if(!mounted)return;
      setState((){loading=false;levels=l.map((x)=>Map<String,dynamic>.from(x)).toList();gifts=g.map((x)=>Map<String,dynamic>.from(x)).toList();selected=s;quantities=q;});
    }catch(e){if(mounted){setState(()=>loading=false);_msg('فشل تحميل SVIP: '+e.toString());}}
  }
  Future<void> _saveLevel(int n) async{
    try{
      final row=levels.firstWhere((x)=>(x['level'] as num).toInt()==n);
      final name=TextEditingController(text:row['name'].toString());
      final desc=TextEditingController(text:'بكج هدايا SVIP '+n.toString());
      final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:const Color(0xFF1B0E08),title:Text('SVIP '+n.toString(),style:const TextStyle(color:Color(0xFFFFD36A))),content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'اسم البكج')),
        TextField(controller:desc,decoration:const InputDecoration(labelText:'الوصف')),
      ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))]));
      if(ok!=true)return;
      await c.rpc('admin_svip_save_package',params:{'p_level':n,'p_name':name.text.trim(),'p_description':desc.text.trim(),'p_is_active':true});
      await _load();_msg('تم حفظ SVIP '+n.toString());
    }catch(e){_msg('فشل الحفظ: '+e.toString());}
  }
  Future<void> _toggleGift(int n,Map<String,dynamic> g,bool value) async{
    final id=g['id'].toString(); final qty=quantities[n]?[id]??1;
    try{await c.rpc('admin_svip_set_gift',params:{'p_level':n,'p_gift_id':id,'p_quantity':qty,'p_enabled':value});
      setState((){selected.putIfAbsent(n,()=>{});if(value)selected[n]!.add(id);else selected[n]!.remove(id);});
    }catch(e){_msg('فشل تعديل الهدية: '+e.toString());}
  }
  Future<void> _quantity(int n,Map<String,dynamic> g) async{
    final id=g['id'].toString(); final ctl=TextEditingController(text:(quantities[n]?[id]??1).toString());
    final value=await showDialog<int>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:const Color(0xFF1B0E08),title:const Text('كمية الهدية'),content:TextField(controller:ctl,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الكمية')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,int.tryParse(ctl.text)),child:const Text('حفظ'))]));
    if(value==null||value<1)return;
    final enabled=selected[n]?.contains(id)==true;
    try{await c.rpc('admin_svip_set_gift',params:{'p_level':n,'p_gift_id':id,'p_quantity':value,'p_enabled':enabled});setState(()=>quantities.putIfAbsent(n,()=>{})[id]=value);_msg('تم حفظ الكمية');}catch(e){_msg('فشل الكمية: '+e.toString());}
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    backgroundColor:const Color(0xFF090604),appBar:AppBar(title:const Text('إدارة SVIP والهدايا',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
    body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(14),children:[
      Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFF1B0E08),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFB77921))),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('نظام SVIP',style:TextStyle(color:Color(0xFFFFD36A),fontSize:20,fontWeight:FontWeight.w900)),
        SizedBox(height:5),Text('كل 100 Coins شحن فعلي = نقطة SVIP. المستويات 1 إلى 6 فقط.',style:TextStyle(color:Colors.white70,fontSize:12)),
      ])),
      const SizedBox(height:14),...List.generate(6,(i)=>_level(i+1)),
    ])));
  Widget _level(int n){
    final row=levels.where((x)=>(x['level'] as num).toInt()==n).isNotEmpty?levels.firstWhere((x)=>(x['level'] as num).toInt()==n):{'name':'SVIP '+n.toString(),'min_recharge_points':thresholds[n]};
    final req=(row['min_recharge_points'] as num).toInt();
    return Container(margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFF160A06),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFF4C2B12))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Text('SVIP '+n.toString(),style:const TextStyle(color:Color(0xFFFFD36A),fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(width:8),Expanded(child:Text(req.toString()+' نقطة = '+(req*100).toString()+' Coins',style:const TextStyle(color:Colors.white54,fontSize:10))),IconButton(onPressed:()=>_saveLevel(n),icon:const Icon(Icons.edit,color:Color(0xFFFFD36A)))]),
      const Text('بكج الهدايا',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),const SizedBox(height:8),
      ...gifts.map((g){
        final id=g['id'].toString();
        final enabled=selected[n]?.contains(id)==true;
        return ListTile(
          dense:true,
          contentPadding:EdgeInsets.zero,
          leading:Text((g['emoji']??'🎁').toString(),style:const TextStyle(fontSize:24)),
          title:Text(g['name'].toString(),style:const TextStyle(color:Colors.white,fontSize:12)),
          subtitle:Text((g['asset_type']??'').toString(),style:const TextStyle(color:Colors.white38,fontSize:9)),
          trailing:Row(mainAxisSize:MainAxisSize.min,children:[
            if(enabled) IconButton(onPressed:()=>_quantity(n,g),icon:Text('×'+(quantities[n]?[id]??1).toString(),style:const TextStyle(color:Color(0xFFFFD36A),fontWeight:FontWeight.w900))),
            Switch(value:enabled,onChanged:(v)=>_toggleGift(n,g,v)),
          ]),
        );
      }),
    ]));
  }
  void _msg(String x)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(x)));
}