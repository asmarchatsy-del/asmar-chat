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
        await client.rpc('admin_grant_vip', params: {
          'p_user_id': parts[0],
          'p_vip_level': parts[1].toUpperCase(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم منح VIP بنجاح')));
        return;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name — صلاحية $role جاهزة للربط بالعملية الخاصة بها.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تنفيذ العملية: $e')),
      );
    }
  }

  Future<void> _showHostEarnings() async {\n    final row = await Supabase.instance.client.rpc('get_my_host_earnings');\n    if (!mounted) return;\n    final data = (row as List).isEmpty ? <String,dynamic>{} : row.first as Map;\n    await showModalBottomSheet(context: context, backgroundColor:_bg, builder:(ctx)=>Directionality(textDirection:TextDirection.rtl, child:Padding(padding:const EdgeInsets.all(20), child:Column(mainAxisSize:MainAxisSize.min, crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('💰 أرباحي',style:TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),Text('إجمالي الحركة: '+(data['total_source']??0).toString(),style:const TextStyle(color:Colors.white70)),Text('إجمالي أرباحي: '+(data['total_earned']??0).toString(),style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),Text('عدد العمليات: '+(data['entries']??0).toString(),style:const TextStyle(color:Colors.white54))]))));\n  }\n\n  Future<void> _showMyAgency() async {\n    final uid = Supabase.instance.client.auth.currentUser?.id;\n    if (uid == null) return;\n    final rows = await Supabase.instance.client.from('agencies').select('id,name,is_active,created_at').eq('owner_id', uid).limit(1);\n    if (!mounted) return;\n    final a = (rows as List).isEmpty ? null : rows.first;\n    await showModalBottomSheet(context: context, backgroundColor: _bg, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: Padding(padding: const EdgeInsets.all(20), child: a == null ? const Text('لا توجد وكالة مرتبطة بحسابك', style: TextStyle(color: Colors.white)) : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('🏢 ' + (a['name'] ?? 'وكالة').toString(), style: const TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)), const SizedBox(height:8), Text('الحالة: ' + (a['is_active'] == true ? 'نشطة' : 'متوقفة'), style: const TextStyle(color:Colors.white70)), Text('ID: ' + a['id'].toString(), style: const TextStyle(color:Colors.white54,fontSize:11))]))));\n  }\n\n  Future<void> _showMyHosts() async {\n    final uid = Supabase.instance.client.auth.currentUser?.id;\n    if (uid == null) return;\n    final agencies = await Supabase.instance.client.from('agencies').select('id,name').eq('owner_id', uid).limit(1);\n    if ((agencies as List).isEmpty) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد وكالة مرتبطة بك'))); return; }\n    final agencyId = agencies.first['id'];\n    final hosts = await Supabase.instance.client.from('profiles').select('id,display_name,role,agency_joined_at').eq('agency_id', agencyId).eq('role','HOST').order('agency_joined_at', ascending:false);\n    if (!mounted) return;\n    await showModalBottomSheet(context: context, backgroundColor:_bg, isScrollControlled:true, builder:(ctx)=>Directionality(textDirection:TextDirection.rtl, child:SizedBox(height:MediaQuery.of(ctx).size.height*.7, child:ListView(padding:const EdgeInsets.all(16),children:[const Text('🎙️ مضيفو الوكالة',style:TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:10),if ((hosts as List).isEmpty) const Text('لا يوجد مضيفون مرتبطون حاليًا',style:TextStyle(color:Colors.white70)),...hosts.map((h)=>Card(color:_card,child:ListTile(title:Text((h['display_name']??'مضيف').toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),subtitle:Text('ID: '+h['id'].toString(),style:const TextStyle(color:Colors.white54,fontSize:10))))]))));\n  }\n\n  Future<void> _showCommission() async {
    final rows = await Supabase.instance.client.from('agency_commission_ledger')
      .select('agency_id,source_amount,app_share_amount,work_share_amount,owner_amount,super_admin_amount,manager_amount,bd_amount,admin_amount,created_at')
      .order('created_at', ascending: false).limit(100);
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
    await showModalBottomSheet(context: context, backgroundColor: _bg, isScrollControlled: true,
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl,
        child: SizedBox(height: MediaQuery.of(ctx).size.height*.72,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('دفتر العمولات', style: TextStyle(color:_gold,fontSize:22,fontWeight:FontWeight.w900)),
            const SizedBox(height:12),
            _infoCard('إجمالي الحركة', 'المصدر: ${totals['source']} • نسبة التطبيق: ${totals['app']} • نسبة الشغل: ${totals['work']}'),
            _infoCard('توزيع الشغل', 'Owner: ${totals['owner']} • Super Admin: ${totals['super']} • Manager: ${totals['manager']} • BD: ${totals['bd']} • Admin: ${totals['admin']}'),
            const SizedBox(height:8),
            ...rows.map((r) => Card(color:_card, child: ListTile(
              title: Text('وكالة: ${r['agency_id']}', style: const TextStyle(color:Colors.white)),
              subtitle: Text('المصدر ${r['source_amount']} | التطبيق ${r['app_share_amount']} | الشغل ${r['work_share_amount']}', style: const TextStyle(color:Colors.white60)),
            ))),
          ]),
        ),
      ),
    );
  }

  Future<void> _showAgencies() async {
    final rows = await Supabase.instance.client
        .from('agencies')
        .select('id,name,manager_id,bd_id,opened_by,created_by_role,is_active,created_at')
        .order('created_at', ascending: false);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .75,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children:[const Expanded(child:Text('الوكالات', style: TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.w900))), if (['CEO','SUPER_ADMIN','MANAGER','BD'].contains(role)) IconButton(onPressed: _openAgency, icon: const Icon(Icons.add_business,color:_gold))]),
              const SizedBox(height: 12),
              if ((rows as List).isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد وكالات حالياً', style: TextStyle(color: Colors.white70)))
              else
                ...rows.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold2)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((a['name'] ?? 'وكالة').toString(), style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('الدور المنشئ: ${a['created_by_role'] ?? '—'}', style: const TextStyle(color: Colors.white70)),
                    Text('Manager: ${a['manager_id'] ?? '—'}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text('BD: ${a['bd_id'] ?? '—'}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
                )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAgency() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('فتح وكالة'),
          content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'اسم الوكالة')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('فتح')),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    await Supabase.instance.client.rpc('agency_open', params: {'p_name': name, 'p_manager_id': null, 'p_bd_id': null});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فتح الوكالة بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    if (role == 'CEO') return const AdminPanel();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF100805),
          foregroundColor: Colors.white,
          title: Text(title, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6B2C0B), Color(0xFF160A06)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _gold2),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF422511),
                    child: Icon(Icons.shield, color: _gold, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(color: _gold, fontSize: 21, fontWeight: FontWeight.w900))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (role == 'SUPER_ADMIN')
              _infoCard('صلاحية VIP', 'يمكن منح VIP من 1 إلى 6 فقط. لا يمكن تجاوز هذا الحد.'),
            if (role == 'MANAGER')
              _infoCard('التفويض', 'يمكن إدارة BD وAdmin والوكالات حسب الصلاحيات الممنوحة. لا توجد صلاحية VIP.'),
            if (role == 'BD')
              _infoCard('BD', 'إدارة ومتابعة الوكالات ضمن نطاقك. لا توجد صلاحية VIP.'),
            if (role == 'ADMIN')
              _infoCard('Admin', 'إدارة الأدوات المسموحة لك فقط. لا توجد صلاحية VIP.'),
            if (role == 'AGENT')
              _infoCard('الوكيل', 'إدارة وكالتك ومضيفيك. لا توجد صلاحية منح VIP.'),
            if (role == 'HOST')
              _infoCard('المضيف', 'مركزك الشخصي للأرباح والبث والمهام والمستوى.'),
            const SizedBox(height: 10),
            ...permissions.map((p) => Card(
              color: _card,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: _gold),
                title: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_left, color: Colors.white38),
                onTap: () => _action(p),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(text, style: const TextStyle(color: Colors.white70, height: 1.45)),
        ],
      ),
    );
  }
}
