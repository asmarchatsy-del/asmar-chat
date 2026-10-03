import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'svip.dart';

class VipLevelData {
  final String id, animal, icon, description;
  final int price;
  final List<String> perks;
  const VipLevelData({required this.id, required this.animal, required this.icon, required this.description, required this.price, required this.perks});
}
class VipPage extends StatefulWidget {
  const VipPage({super.key});
  @override State<VipPage> createState() => _VipPageState();
}
class _VipPageState extends State<VipPage> {
  int balance=0; String? currentVip; bool loading=true;
  List<VipLevelData> levels = const [];
  RealtimeChannel? _vipChannel;
  @override void initState(){super.initState();_load();_listen();}
  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client.from('vip_levels')
        .select('id,name,animal,price_coins,perks,is_active')
        .eq('is_active', true)
        .neq('id', 'SVIP')
        .order('id');
      final c=Supabase.instance.client; final u=c.auth.currentUser; if(u==null)return;
      final parsed = (rows as List).map((r) {
        final m=Map<String,dynamic>.from(r as Map);
        final id=m['id'].toString();
        const icons={'VIP1':'🦌','VIP2':'🐺','VIP3':'🐊','VIP4':'🐘','VIP5':'🦅','VIP6':'🐻','VIP7':'🐆','VIP8':'🐯','VIP9':'🐉','VIP10':'🦁'};
        final perksRaw=m['perks'];
        final perks=perksRaw is List ? perksRaw.map((x)=>x.toString()).toList() : <String>[];
        return VipLevelData(id:id,animal:m['animal']?.toString()??'',icon:icons[id]??'⭐',description:perks.isEmpty?'مزايا VIP':perks.join(' • '),price:(m['price_coins'] as num?)?.toInt()??0,perks:perks);
      }).toList();
      final w=await c.from('wallets').select('balance').eq('user_id',u.id).maybeSingle();
      final p=await c.from('profiles').select('vip_level').eq('id',u.id).maybeSingle();
      if(!mounted)return;
      setState((){levels=parsed;balance=(w?['balance'] as num?)?.toInt()??0;currentVip=p?['vip_level']?.toString();loading=false;});
    } catch (_) { if(mounted)setState(()=>loading=false); }
  }
  void _listen(){
    _vipChannel=Supabase.instance.client.channel('vip-levels-live')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema:'public', table:'vip_levels', callback:(_)=>_load())
      .subscribe();
  }
  @override void dispose(){ if(_vipChannel!=null) Supabase.instance.client.removeChannel(_vipChannel!); super.dispose(); }
  Future<void> _buy(VipLevelData v) async {
    try {
      await Supabase.instance.client.rpc('purchase_vip', params:{'p_vip_level':v.id});
      await _load();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(v.id+' '+v.animal+' فعال الآن 🔥')));
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل شراء VIP: $e')));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090604),
        appBar: AppBar(
          title: const Text('VIP 1 — VIP 10', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [IconButton(tooltip:'SVIP',icon:const Icon(Icons.workspace_premium,color:Color(0xFFFFD36A)),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SvipPage()))),Padding(padding: const EdgeInsets.all(14), child: Center(child: Text(loading ? '...' : balance.toString()+' 🪙', style: const TextStyle(color: Color(0xFFFFD36A), fontWeight: FontWeight.w900))))],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: levels.length,
          itemBuilder: (context, i) {
            final v=levels[i]; final active=currentVip==v.id;
            return Container(
              margin: const EdgeInsets.only(bottom:12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors:[Color(0xFF2A160A),Color(0xFF0D0704)]), border: Border.all(color: active ? const Color(0xFFFFD36A) : const Color(0xFF6A421A), width: active ? 2 : 1)),
              child: Row(children:[
                Container(width:70,height:70,decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[Color(0xFFFFE08A),Color(0xFF8C4E0D)])),child:Center(child:Text(v.icon,style:const TextStyle(fontSize:38)))),
                const SizedBox(width:14),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(v.id+' • '+v.animal,style:const TextStyle(color:Color(0xFFFFD36A),fontSize:18,fontWeight:FontWeight.w900)),
                  Text(v.description,style:const TextStyle(color:Colors.white70,fontSize:12)),
                  const SizedBox(height:6),
                  Text(v.perks.join(' • '),style:const TextStyle(color:Colors.white54,fontSize:11)),
                  const SizedBox(height:8),
                  Row(children:[Text(v.price.toString()+' 🪙',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),const Spacer(),FilledButton(onPressed:active?null:()=>_buy(v),style:const ButtonStyle(backgroundColor:WidgetStatePropertyAll(Color(0xFFB77921))),child:Text(active?'مفعّل':'شراء'))]),
                ])),
              ]),
            );
          },
        ),
      ),
    );
  }
}
