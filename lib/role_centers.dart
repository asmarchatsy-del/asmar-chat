import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_panel.dart';

const _gold = Color(0xFFFFD36A);
const _gold2 = Color(0xFFB77921);
const _bg = Color(0xFF090604);
const _card = Color(0xFF1B0E08);

class RoleCenterPage extends StatefulWidget {
  final String role;
  const RoleCenterPage({super.key, required this.role});
  @override
  State<RoleCenterPage> createState() => _RoleCenterPageState();
}

class _RoleCenterPageState extends State<RoleCenterPage> {
  String get role => widget.role.toUpperCase();

  String get title {
    switch (role) {
      case 'CEO': return 'لوحة Chat الرئيسية';
      case 'SUPER_ADMIN': return 'مركز Super Admin';
      case 'MANAGER': return 'مركز Manager';
      case 'BD': return 'مركز BD';
      case 'ADMIN': return 'مركز Admin';
      case 'AGENT': return 'مركز الوكيل';
      case 'HOST': return 'مركز المضيف';
      default: return 'المركز';
    }
  }

  List<String> get permissions {
    switch (role) {
      case 'SUPER_ADMIN': return ['المستخدمون', 'الغرف', 'المضيفون', 'الوكالات', 'VIP 1 → VIP 6'];
      case 'MANAGER': return ['المضيفون', 'الوكالات', 'BD', 'Admin'];
      case 'BD': return ['الوكالات', 'متابعة الوكالات'];
      case 'ADMIN': return ['المستخدمون', 'الغرف', 'المضيفون'];
      case 'AGENT': return ['وكالتي', 'المضيفون', 'الإحصائيات'];
      case 'HOST': return ['أرباحي', 'ساعات البث', 'المهام', 'المستوى'];
      default: return [];
    }
  }

  Future<void> _action(String name) async {
    final client = Supabase.instance.client;
    try {
      if (name == 'الوكالات' && ['CEO','SUPER_ADMIN','MANAGER','BD'].contains(role)) { await _showAgencies(); return; }
      if (name == 'متابعة الوكالات' && ['CEO','SUPER_ADMIN','MANAGER','BD','ADMIN'].contains(role)) { await _showCommission(); return; }
      if (name == 'المستخدمون' && ['SUPER_ADMIN','ADMIN'].contains(role)) { await _showUsers(); return; }
      if (name == 'الغرف' && ['SUPER_ADMIN','ADMIN'].contains(role)) { await _showRooms(); return; }
      if (name == 'المضيفون' && ['SUPER_ADMIN','MANAGER','ADMIN'].contains(role)) { await _showHostsScoped(); return; }
      if (name == 'BD' && role == 'MANAGER') { await _showTeamRole('BD'); return; }
      if (name == 'Admin' && role == 'MANAGER') { await _showTeamRole('ADMIN'); return; }
      if (name == 'الإحصائيات' && role == 'AGENT') { await _showAgentStats(); return; }
      if (name == 'الشحن' && role == 'AGENT') { await _agentRecharge(); return; }
      if (name == 'ساعات البث' && role == 'HOST') { await _showHostStats(); return; }
      if (name == 'المهام' && role == 'HOST') { await _showHostTasks(); return; }
      if (name == 'المستوى' && role == 'HOST') { await _showHostLevel(); return; }
      if (name == 'وكالتي' && role == 'AGENT') { await _showMyAgency(); return; }
      if (name == 'المضيفون' && role == 'AGENT') { await _showMyHosts(); return; }
      if (name == 'أرباحي' && role == 'HOST') { await _showHostEarnings(); return; }
      if (name == 'VIP 1 → VIP 6' && role == 'SUPER_ADMIN') {
        final target = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final id = TextEditingController();
            final vip = TextEditingController(text: 'VIP6');
            return AlertDialog(
              title: const Text('منح VIP'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: id, decoration: const InputDecoration(labelText: 'ID المستخدم (UUID)')),
                TextField(controller: vip, decoration: const InputDecoration(labelText: 'VIP 1 إلى VIP 6')),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                FilledButton(onPressed: () => Navigator.pop(ctx, id.text.trim() + '|' + vip.text.trim()), child: const Text('منح')),
              ],
            );
          },
        );
        if (target == null) return;
        final parts = target.split('|');
        if (parts.length != 2) throw Exception('بيانات غير صحيحة');
        await client.rpc('admin_grant_vip', params: {'p_user_id': parts[0], 'p_vip_level': parts[1].toUpperCase()});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم منح VIP بنجاح')));
        return;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name — صلاحية $role جاهزة للربط بالعملية الخاصة بها.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
    }
  }

  Future<void> _showHostEarnings() async {
    final row = await Supabase.instance.client.rpc('get_my_host_earnings');
    if (!mounted) return;
    final data = (row as List).isEmpty ? <String,dynamic>{} : row.first as Map;
    await showModalBottomSheet(context: context, backgroundColor:_bg, builder:(ctx)=>Directionality(textDirection:TextDirection.rtl, child:Padding(padding:const EdgeInsets.all(20), child:Column(mainAxisSize:MainAxisSize.min, crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('💰 أرباحي',style:TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),Text('إجمالي الحركة: '+(data['total_source']??0).toString(),style:const TextStyle(color:Colors.white70)),Text('إجمالي أرباحي: '+(data['total_earned']??0).toString(),style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),Text('عدد العمليات: '+(data['entries']??0).toString(),style:const TextStyle(color:Colors.white54))]))));
  }

  Future<void> _showMyAgency() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final rows = await Supabase.instance.client.from('agencies').select('id,name,is_active,created_at').eq('owner_id', uid).limit(1);
    if (!mounted) return;
    final a = (rows as List).isEmpty ? null : rows.first;
    await showModalBottomSheet(context: context, backgroundColor: _bg, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: Padding(padding: const EdgeInsets.all(20), child: a == null ? const Text('لا توجد وكالة مرتبطة بحسابك', style: TextStyle(color: Colors.white)) : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('🏢 ' + (a['name'] ?? 'وكالة').toString(), style: const TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)), const SizedBox(height:8), Text('الحالة: ' + (a['is_active'] == true ? 'نشطة' : 'متوقفة'), style: const TextStyle(color:Colors.white70)), Text('ID: ' + a['id'].toString(), style: const TextStyle(color:Colors.white54,fontSize:11))]))));
  }

  Future<void> _showMyHosts() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final agencies = await Supabase.instance.client.from('agencies').select('id,name').eq('owner_id', uid).limit(1);
    if ((agencies as List).isEmpty) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد وكالة مرتبطة بك'))); return; }
    final agencyId = agencies.first['id'];
    final hosts = await Supabase.instance.client.from('profiles').select('id,display_name,role,agency_joined_at').eq('agency_id', agencyId).eq('role','HOST').order('agency_joined_at', ascending:false);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .7,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('🎙️ مضيفو الوكالة', style: TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)),
              const SizedBox(height: 10),
              if ((hosts as List).isEmpty) const Text('لا يوجد مضيفون مرتبطون حاليًا', style: TextStyle(color:Colors.white70)),
              ...hosts.map((h) => Card(
                color: _card,
                child: ListTile(
                  title: Text((h['display_name'] ?? 'مضيف').toString(), style: const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
                  subtitle: Text('ID: ${h['id']}', style: const TextStyle(color:Colors.white54,fontSize:10)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCommission() async {
    final rows = await Supabase.instance.client.from('agency_commission_ledger').select('agency_id,source_amount,app_share_amount,work_share_amount,owner_amount,super_admin_amount,manager_amount,bd_amount,admin_amount,created_at').order('created_at', ascending: false).limit(100);
    if (!mounted) return;
    final totals = <String,int>{'source':0,'app':0,'work':0,'owner':0,'super':0,'manager':0,'bd':0,'admin':0};
    for (final r in rows) {
      totals['source'] = totals['source']! + ((r['source_amount'] as num?)?.toInt() ?? 0);
      totals['app'] = totals['app']! + ((r['app_share_amount'] as num?)?.toInt() ?? 0);
      totals['work'] = totals['work']! + ((r['work_share_amount'] as num?)?.toInt() ?? 0);
      totals['owner'] = totals['owner']! + ((r['owner_amount'] as num?)?.toInt() ?? 0);
      totals['super'] = totals['super']! + ((r['super_admin_amount'] as num?)?.toInt() ?? 0);
      totals['manager'] = totals['manager']! + ((r['manager_amount'] as num?)?.toInt() ?? 0);
      totals['bd'] = totals['bd']! + ((r['bd_amount'] as num?)?.toInt() ?? 0);
      totals['admin'] = totals['admin']! + ((r['admin_amount'] as num?)?.toInt() ?? 0);
    }
    if (!mounted) return;
    await showModalBottomSheet(context: context, backgroundColor: _bg, isScrollControlled: true, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: SizedBox(height: MediaQuery.of(ctx).size.height*.72, child: ListView(padding: const EdgeInsets.all(16), children: [const Text('دفتر العمولات', style: TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),_infoCard('إجمالي الحركة', 'المصدر: ${totals['source']} • نسبة التطبيق: ${totals['app']} • نسبة الشغل: ${totals['work']}'),_infoCard('توزيع الشغل', 'Owner: ${totals['owner']} • Super Admin: ${totals['super']} • Manager: ${totals['manager']} • BD: ${totals['bd']} • Admin: ${totals['admin']}'),const SizedBox(height:8),...rows.map((r) => Card(color:_card, child: ListTile(title: Text('وكالة: ${r['agency_id']}', style: const TextStyle(color:Colors.white)),subtitle: Text('المصدر ${r['source_amount']} | التطبيق ${r['app_share_amount']} | الشغل ${r['work_share_amount']}', style: const TextStyle(color:Colors.white60))))]))));
  }

  Future<void> _showAgencies() async {
    final rows = await Supabase.instance.client.from('agencies').select('id,name,manager_id,bd_id,opened_by,created_by_role,is_active,created_at').order('created_at', ascending: false);
    if (!mounted) return;
    await showModalBottomSheet(context: context, backgroundColor: _bg, isScrollControlled: true, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: SizedBox(height: MediaQuery.of(ctx).size.height * .75, child: ListView(padding: const EdgeInsets.all(16), children: [Row(children:[const Expanded(child:Text('الوكالات', style: TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.w900))), if (['CEO','SUPER_ADMIN','MANAGER','BD'].contains(role)) IconButton(onPressed: _openAgency, icon: const Icon(Icons.add_business,color:_gold))]),const SizedBox(height: 12),if ((rows as List).isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد وكالات حالياً', style: TextStyle(color: Colors.white70))) else ...rows.map((a) => Container(margin: const EdgeInsets.only(bottom: 10),padding: const EdgeInsets.all(14),decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold2)),child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((a['name'] ?? 'وكالة').toString(), style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w900)),const SizedBox(height: 6),Text('الدور المنشئ: ${a['created_by_role'] ?? '—'}', style: const TextStyle(color: Colors.white70)),Text('Manager: ${a['manager_id'] ?? '—'}', style: const TextStyle(color: Colors.white54, fontSize: 11)),Text('BD: ${a['bd_id'] ?? '—'}', style: const TextStyle(color: Colors.white54, fontSize: 11))])))]))));
  }

  Future<void> _openAgency() async {
    final name = await showDialog<String>(context: context, builder: (ctx) { final controller = TextEditingController(); return AlertDialog(title: const Text('فتح وكالة'), content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم الوكالة')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('فتح'))]); });
    if (name == null || name.isEmpty) return;
    await Supabase.instance.client.rpc('agency_open', params: {'p_name': name, 'p_manager_id': null, 'p_bd_id': null});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فتح الوكالة بنجاح')));
  }

  Future<void> _showUsers() async {
    final rows = await Supabase.instance.client.from('profiles').select('id,display_name,username,role,is_active,vip_level').order('created_at',ascending:false).limit(150);
    if (!mounted) return;
    await _simpleList('👥 المستخدمون', rows, (r) => '${r['display_name'] ?? r['username'] ?? 'مستخدم'} • ${r['role']} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<void> _showRooms() async {
    final rows = await Supabase.instance.client.from('rooms').select('id,name,owner_id,is_active,created_at').order('created_at',ascending:false).limit(100);
    if (!mounted) return;
    await showModalBottomSheet(context:context, backgroundColor:_bg, isScrollControlled:true, builder:(ctx)=>Directionality(textDirection:TextDirection.rtl, child:SizedBox(height:MediaQuery.of(ctx).size.height*.75, child:ListView(padding:const EdgeInsets.all(16), children:[const Text('🚪 الغرف',style:TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)),...rows.map((r)=>Card(color:_card,child:SwitchListTile(value:r['is_active']==true,title:Text(r['name']??'غرفة',style:const TextStyle(color:Colors.white)),subtitle:Text(r['id'].toString(),style:const TextStyle(color:Colors.white38,fontSize:10)),activeColor:_gold,onChanged:(v) async { try { await Supabase.instance.client.rpc('admin_set_room_active',params:{'p_room_id':r['id'],'p_active':v}); if(mounted){Navigator.pop(ctx); _showRooms();} } catch(e){ if(mounted)_message('فشل تحديث الغرفة: $e'); } }))),]))));
  }

  Future<void> _showHostsScoped() async {
    final rows = await Supabase.instance.client.from('profiles').select('id,display_name,username,role,is_active,agency_id').eq('role','HOST').order('created_at',ascending:false).limit(150);
    if (!mounted) return;
    await _simpleList('🎙️ المضيفون',rows,(r)=>'${r['display_name'] ?? r['username'] ?? 'مضيف'} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<void> _showTeamRole(String wanted) async {
    final rows = await Supabase.instance.client.from('profiles').select('id,display_name,username,role,is_active').eq('role',wanted).order('created_at',ascending:false).limit(100);
    if (!mounted) return;
    await _simpleList(wanted == 'BD' ? '💼 فريق BD' : '🛡️ فريق Admin',rows,(r)=>'${r['display_name'] ?? r['username'] ?? wanted} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<void> _simpleList(String title,List rows,String Function(dynamic) label) async {
    await showModalBottomSheet(context:context,backgroundColor:_bg,isScrollControlled:true,builder:(ctx)=>Directionality(textDirection:TextDirection.rtl,child:SizedBox(height:MediaQuery.of(ctx).size.height*.75,child:ListView(padding:const EdgeInsets.all(16),children:[Text(title,style:const TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)),if(rows.isEmpty) const Text('لا توجد بيانات',style:TextStyle(color:Colors.white54)),...rows.map((r)=>Card(color:_card,child:ListTile(title:Text(label(r),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),subtitle:Text(r['id'].toString(),style:const TextStyle(color:Colors.white38,fontSize:10))))),]))));
  }

  Future<void> _showAgentStats() async {
    final uid=Supabase.instance.client.auth.currentUser?.id;if(uid==null)return;
    final agencies=await Supabase.instance.client.from('agencies').select('id,name').eq('owner_id',uid).limit(1);
    if((agencies as List).isEmpty){if(mounted)_message('لا توجد وكالة مرتبطة بك');return;}
    final aid=agencies.first['id'];
    final hosts=await Supabase.instance.client.from('profiles').select('id').eq('agency_id',aid).eq('role','HOST');
    final ledger=await Supabase.instance.client.from('agency_commission_ledger').select('source_amount,work_share_amount').eq('agency_id',aid);
    final source=ledger.fold<int>(0,(n,r)=>n+((r['source_amount'] as num?)?.toInt()??0));
    final work=ledger.fold<int>(0,(n,r)=>n+((r['work_share_amount'] as num?)?.toInt()??0));
    if(mounted)_infoDialog('📈 إحصائيات الوكالة','المضيفون: ${hosts.length}\nحركة المصدر: $source\nحصة الشغل: $work');
  }

  Future<void> _agentRecharge() async {
    final id=TextEditingController();final amount=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('شحن مستخدم'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:id,decoration:const InputDecoration(labelText:'UUID أو Username')),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الكوينز'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('شحن'))]));
    if(ok!=true)return;
    final n=int.tryParse(amount.text.trim())??0;if(n<=0){_message('أدخل كمية صحيحة');return;}
    await Supabase.instance.client.rpc('agent_recharge',params:{'p_recipient_id':id.text.trim(),'p_amount':n});
    if(mounted)_message('تم الشحن بنجاح');
  }

  Future<void> _showHostStats() async {
    final uid=Supabase.instance.client.auth.currentUser?.id;if(uid==null)return;
    final rows=await Supabase.instance.client.from('host_earnings').select('source_amount,created_at').eq('host_id',uid).limit(200);
    final total=rows.fold<int>(0,(n,r)=>n+((r['source_amount'] as num?)?.toInt()??0));
    if(mounted)_infoDialog('⏱️ سجل البث','عمليات الأرباح: ${rows.length}\nالحركة المسجلة: $total');
  }

  Future<void> _showHostTasks() async {
    final uid=Supabase.instance.client.auth.currentUser?.id;if(uid==null)return;
    final rows=await Supabase.instance.client.from('host_earnings').select('source_amount,created_at').eq('host_id',uid).order('created_at',ascending:false).limit(30);
    if(!mounted)return;
    await _simpleList('📋 المهام والنشاط',rows,(r)=>'نشاط: ${r['source_amount']} • ${r['created_at']}');
  }

  Future<void> _showHostLevel() async {
    final uid=Supabase.instance.client.auth.currentUser?.id;if(uid==null)return;
    final p=await Supabase.instance.client.from('profiles').select('vip_level,is_verified').eq('id',uid).maybeSingle();
    if(mounted)_infoDialog('⭐ المستوى','VIP: ${p?['vip_level'] ?? '—'}\nالتحقق: ${p?['is_verified'] == true ? 'موثق' : 'غير موثق'}');
  }

  void _infoDialog(String title,String body){ showDialog(context:context,builder:(ctx)=>AlertDialog(backgroundColor:_card,title:Text(title,style:const TextStyle(color:_gold,fontWeight:FontWeight.w900)),content:Text(body,style:const TextStyle(color:Colors.white70,height:1.5)),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إغلاق'))])); }
  void _message(String text){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text),backgroundColor:_gold2));}

  @override
  Widget build(BuildContext context) {
    if (role == 'CEO') return const AdminPanel();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: _bg, appBar: AppBar(backgroundColor: const Color(0xFF100805), foregroundColor: Colors.white, title: Text(title, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900))), body: ListView(padding: const EdgeInsets.all(16), children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6B2C0B), Color(0xFF160A06)]), borderRadius: BorderRadius.circular(22), border: Border.all(color: _gold2)), child: Row(children: [const CircleAvatar(radius: 28, backgroundColor: Color(0xFF422511), child: Icon(Icons.shield, color: _gold, size: 30)),const SizedBox(width: 12),Expanded(child: Text(title, style: const TextStyle(color: _gold, fontSize: 21, fontWeight: FontWeight.w900)))])),const SizedBox(height: 18),if (role == 'SUPER_ADMIN') _infoCard('صلاحية VIP', 'يمكن منح VIP من 1 إلى 6 فقط. لا يمكن تجاوز هذا الحد.'),if (role == 'MANAGER') _infoCard('التفويض', 'يمكن إدارة BD وAdmin والوكالات حسب الصلاحيات الممنوحة. لا توجد صلاحية VIP.'),if (role == 'BD') _infoCard('BD', 'إدارة ومتابعة الوكالات ضمن نطاقك. لا توجد صلاحية VIP.'),if (role == 'ADMIN') _infoCard('Admin', 'إدارة الأدوات المسموحة لك فقط. لا توجد صلاحية VIP.'),if (role == 'AGENT') _infoCard('الوكيل', 'إدارة وكالتك ومضيفيك. لا توجد صلاحية منح VIP.'),if (role == 'HOST') _infoCard('المضيف', 'مركزك الشخصي للأرباح والبث والمهام والمستوى.'),const SizedBox(height: 10),...permissions.map((p) => Card(color: _card, child: ListTile(leading: const Icon(Icons.check_circle, color: _gold), title: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.chevron_left, color: Colors.white38), onTap: () => _action(p))))]));
  }

  Widget _infoCard(String label, String text) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold2)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w900)),const SizedBox(height: 7),Text(text, style: const TextStyle(color: Colors.white70, height: 1.45))]));
  }
}
