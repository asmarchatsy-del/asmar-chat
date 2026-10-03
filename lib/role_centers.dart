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
      case 'CEO':
        return 'لوحة Chat الرئيسية';
      case 'SUPER_ADMIN':
        return 'مركز Super Admin';
      case 'MANAGER':
        return 'مركز Manager';
      case 'BD':
        return 'مركز BD';
      case 'ADMIN':
        return 'مركز Admin';
      case 'AGENT':
        return 'مركز الوكيل';
      case 'HOST':
        return 'مركز المضيف';
      default:
        return 'المركز';
    }
  }

  List<String> get permissions {
    switch (role) {
      case 'SUPER_ADMIN':
        return ['المستخدمون', 'الغرف', 'المضيفون', 'الوكالات', 'المحافظ', 'VIP 1 → VIP 6'];
      case 'MANAGER':
        return ['المستخدمون', 'المضيفون', 'الوكالات', 'BD', 'Admin'];
      case 'BD':
        return ['المستخدمون', 'الوكالات', 'متابعة الوكالات'];
      case 'BD':
        return ['الوكالات', 'متابعة الوكالات'];
      case 'ADMIN':
        return ['المستخدمون', 'الغرف', 'المضيفون'];
      case 'AGENT':
        return ['وكالتي', 'المضيفون', 'الإحصائيات'];
      case 'HOST':
        return ['أرباحي', 'ساعات البث', 'المهام', 'المستوى'];
      default:
        return [];
    }
  }

  Future<void> _action(String name) async {
    try {
      if (name == 'الوكالات' && ['CEO', 'SUPER_ADMIN', 'MANAGER', 'BD'].contains(role)) {
        await _showAgencies();
        return;
      }
      if (name == 'متابعة الوكالات') {
        await _showCommission();
        return;
      }
      if (name == 'المستخدمون' && ['SUPER_ADMIN', 'ADMIN'].contains(role)) {
        await _showUsers();
        return;
      }
      if (name == 'المستخدمون' && role == 'MANAGER') {
        await _showManagerUsers();
        return;
      }
      if (name == 'المستخدمون' && role == 'BD') {
        await _showBdUsers();
        return;
      }
      if (name == 'المحافظ' && role == 'SUPER_ADMIN') {
        await _showWalletOverview();
        return;
      }
      if (name == 'الغرف' && ['SUPER_ADMIN', 'ADMIN'].contains(role)) {
        await _showRooms();
        return;
      }
      if (name == 'المضيفون' && ['SUPER_ADMIN', 'MANAGER', 'ADMIN'].contains(role)) {
        await _showHostsScoped();
        return;
      }
      if (name == 'المضيفون' && role == 'AGENT') {
        await _showMyHosts();
        return;
      }
      if (name == 'وكالتي' && role == 'AGENT') {
        await _showMyAgency();
        return;
      }
      if (name == 'الإحصائيات' && role == 'AGENT') {
        await _showAgentStats();
        return;
      }
      if (name == 'BD' && role == 'MANAGER') {
        await _showMyBD();
        return;
      }
      if (name == 'Admin' && role == 'MANAGER') {
        await _showTeamRole('ADMIN');
        return;
      }
      if (name == 'أرباحي' && role == 'HOST') {
        await _showHostEarnings();
        return;
      }
      if (name == 'ساعات البث' && role == 'HOST') {
        await _showHostStats();
        return;
      }
      if (name == 'المهام' && role == 'HOST') {
        await _showHostTasks();
        return;
      }
      if (name == 'المستوى' && role == 'HOST') {
        await _showHostLevel();
        return;
      }
      if (name == 'VIP 1 → VIP 6' && role == 'SUPER_ADMIN') {
        await _grantVip();
        return;
      }
      _message('$name — الصلاحية جاهزة.');
    } catch (e) {
      _message('تعذر تنفيذ العملية: $e');
    }
  }

  Future<void> _grantVip() async {
    final target = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final id = TextEditingController();
        final vip = TextEditingController(text: 'VIP6');
        return AlertDialog(
          title: const Text('منح VIP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: id, decoration: const InputDecoration(labelText: 'ID المستخدم (UUID)')),
              TextField(controller: vip, decoration: const InputDecoration(labelText: 'VIP 1 إلى VIP 6')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, '${id.text.trim()}|${vip.text.trim()}'),
              child: const Text('منح'),
            ),
          ],
        );
      },
    );
    if (target == null) return;
    final parts = target.split('|');
    if (parts.length != 2 || parts[0].isEmpty) throw Exception('بيانات غير صحيحة');
    await Supabase.instance.client.rpc(
      'admin_grant_vip',
      params: {'p_user_id': parts[0], 'p_vip_level': parts[1].toUpperCase()},
    );
    _message('تم منح VIP بنجاح');
  }

  Future<void> _showHostEarnings() async {
    final row = await Supabase.instance.client.rpc('get_my_host_earnings');
    if (!mounted) return;
    final list = row is List ? row : <dynamic>[];
    final data = list.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(list.first as Map);
    await _sheet(
      '💰 أرباحي',
      [
        Text('إجمالي الحركة: ${data['total_source'] ?? 0}', style: const TextStyle(color: Colors.white70)),
        Text('إجمالي أرباحي: ${data['total_earned'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text('عدد العمليات: ${data['entries'] ?? 0}', style: const TextStyle(color: Colors.white54)),
      ],
    );
  }

  Future<void> _showMyAgency() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final rows = await Supabase.instance.client.from('agencies').select('id,name,is_active,created_at').eq('owner_id', uid).limit(1);
    if (!mounted) return;
    final list = List<dynamic>.from(rows);
    final a = list.isEmpty ? null : Map<String, dynamic>.from(list.first as Map);
    await _sheet(
      '🏢 وكالتي',
      [
        if (a == null)
          const Text('لا توجد وكالة مرتبطة بحسابك', style: TextStyle(color: Colors.white))
        else ...[
          Text(a['name']?.toString() ?? 'وكالة', style: const TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('الحالة: ${a['is_active'] == true ? 'نشطة' : 'متوقفة'}', style: const TextStyle(color: Colors.white70)),
          Text('ID: ${a['id']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ],
    );
  }

  Future<void> _showMyHosts() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final agencies = await Supabase.instance.client.from('agencies').select('id').eq('owner_id', uid).limit(1);
    final agencyList = List<dynamic>.from(agencies);
    if (agencyList.isEmpty) {
      _message('لا توجد وكالة مرتبطة بك');
      return;
    }
    final agencyId = agencyList.first['id'];
    final hosts = await Supabase.instance.client.from('profiles').select('id,display_name,role').eq('agency_id', agencyId).eq('role', 'HOST').order('created_at', ascending: false);
    if (!mounted) return;
    await _simpleList('🎙️ مضيفو الوكالة', hosts, (r) => '${r['display_name'] ?? 'مضيف'} • ${r['role']}');
  }

  Future<void> _showCommission() async {
    final rows = await Supabase.instance.client.from('agency_commission_ledger').select('agency_id,source_amount,app_share_amount,work_share_amount,owner_amount,super_admin_amount,manager_amount,bd_amount,admin_amount,created_at').order('created_at', ascending: false).limit(100);
    if (!mounted) return;
    final list = List<dynamic>.from(rows);
    final totals = <String, int>{'source': 0, 'app': 0, 'work': 0, 'owner': 0, 'super': 0, 'manager': 0, 'bd': 0, 'admin': 0};
    for (final item in list) {
      final r = Map<String, dynamic>.from(item as Map);
      totals['source'] = totals['source']! + ((r['source_amount'] as num?)?.toInt() ?? 0);
      totals['app'] = totals['app']! + ((r['app_share_amount'] as num?)?.toInt() ?? 0);
      totals['work'] = totals['work']! + ((r['work_share_amount'] as num?)?.toInt() ?? 0);
      totals['owner'] = totals['owner']! + ((r['owner_amount'] as num?)?.toInt() ?? 0);
      totals['super'] = totals['super']! + ((r['super_admin_amount'] as num?)?.toInt() ?? 0);
      totals['manager'] = totals['manager']! + ((r['manager_amount'] as num?)?.toInt() ?? 0);
      totals['bd'] = totals['bd']! + ((r['bd_amount'] as num?)?.toInt() ?? 0);
      totals['admin'] = totals['admin']! + ((r['admin_amount'] as num?)?.toInt() ?? 0);
    }
    await _sheet(
      'دفتر العمولات',
      [
        _infoCard('إجمالي الحركة', 'المصدر: ${totals['source']} • التطبيق: ${totals['app']} • الشغل: ${totals['work']}'),
        _infoCard('توزيع الشغل', 'Owner: ${totals['owner']} • Super Admin: ${totals['super']} • Manager: ${totals['manager']} • BD: ${totals['bd']} • Admin: ${totals['admin']}'),
        ...list.map((item) {
          final r = Map<String, dynamic>.from(item as Map);
          return Card(
            color: _card,
            child: ListTile(
              title: Text('وكالة: ${r['agency_id']}', style: const TextStyle(color: Colors.white)),
              subtitle: Text('المصدر ${r['source_amount']} | التطبيق ${r['app_share_amount']} | الشغل ${r['work_share_amount']}', style: const TextStyle(color: Colors.white60)),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showAgencies() async {
    final rows = await Supabase.instance.client.from('agencies').select('id,name,manager_id,bd_id,opened_by,created_by_role,is_active,created_at').order('created_at', ascending: false);
    if (!mounted) return;
    final list = List<dynamic>.from(rows);
    await _sheet(
      'الوكالات',
      [
        if (['CEO', 'SUPER_ADMIN', 'MANAGER', 'BD'].contains(role))
          Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: _openAgency, icon: const Icon(Icons.add_business, color: _gold))),
        if (list.isEmpty) const Text('لا توجد وكالات حالياً', style: TextStyle(color: Colors.white70)),
        ...list.map((item) {
          final a = Map<String, dynamic>.from(item as Map);
          return Card(
            color: _card,
            child: ListTile(
              title: Text(a['name']?.toString() ?? 'وكالة', style: const TextStyle(color: _gold, fontWeight: FontWeight.w900)),
              subtitle: Text('Manager: ${a['manager_id'] ?? '—'}\nBD: ${a['bd_id'] ?? '—'}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ),
          );
        }),
      ],
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
    _message('تم فتح الوكالة بنجاح');
  }

  Future<void> _showUsers() async {
    final rows = await Supabase.instance.client.from('profiles').select('id,display_name,username,role,is_active,vip_level').order('created_at', ascending: false).limit(150);
    if (!mounted) return;
    await _simpleList('👥 المستخدمون', rows, (r) => '${r['display_name'] ?? r['username'] ?? 'مستخدم'} • ${r['role']} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<List<dynamic>> _myManagedAgencyIds(String column) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await Supabase.instance.client.from('agencies').select('id').eq(column, uid);
    return List<dynamic>.from(rows).map((r) => r['id']).toList();
  }

  Future<void> _showManagerUsers() async {
    final ids = await _myManagedAgencyIds('manager_id');
    if (ids.isEmpty) { _message('لا توجد وكالة مرتبطة بك كـManager'); return; }
    final rows = await Supabase.instance.client.from('profiles')
        .select('id,display_name,username,role,is_active,vip_level,agency_id')
        .inFilter('agency_id', ids).order('created_at', ascending: false).limit(200);
    if (!mounted) return;
    await _simpleList('👥 مستخدمو نطاق Manager', rows,
      (r) => '${r['display_name'] ?? r['username'] ?? 'مستخدم'} • ${r['role']} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<void> _showMyBD() async {
    final ids = await _myManagedAgencyIds('manager_id');
    if (ids.isEmpty) { _message('لا توجد وكالة مرتبطة بك كـManager'); return; }
    final rows = await Supabase.instance.client.from('profiles')
        .select('id,display_name,username,role,is_active,agency_id')
        .eq('role', 'BD').inFilter('agency_id', ids).order('created_at', ascending: false).limit(100);
    if (!mounted) return;
    await _simpleList('💼 BD التابعون لنطاقك', rows,
      (r) => '${r['display_name'] ?? r['username'] ?? 'BD'} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<void> _showBdUsers() async {
    final ids = await _myManagedAgencyIds('bd_id');
    if (ids.isEmpty) { _message('لا توجد وكالة مرتبطة بك كـBD'); return; }
    final rows = await Supabase.instance.client.from('profiles')
        .select('id,display_name,username,role,is_active,vip_level,agency_id')
        .inFilter('agency_id', ids).order('created_at', ascending: false).limit(200);
    if (!mounted) return;
    await _simpleList('👥 مستخدمو نطاق BD', rows,
      (r) => '${r['display_name'] ?? r['username'] ?? 'مستخدم'} • ${r['role']} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<void> _showWalletOverview() async {
    final rows = await Supabase.instance.client.from('wallets')
        .select('user_id,coins,updated_at').order('updated_at', ascending: false).limit(150);
    if (!mounted) return;
    await _simpleList('💰 المحافظ', rows,
      (r) => 'المستخدم: ${r['user_id']} • الرصيد: ${r['coins'] ?? 0}');
  }

  Future<void> _showRooms() async {
    final rows = await Supabase.instance.client.from('rooms').select('id,name,owner_id,is_active,created_at').order('created_at', ascending: false).limit(100);
    if (!mounted) return;
    await _simpleList('🚪 الغرف', rows, (r) => '${r['name'] ?? 'غرفة'} • ${r['is_active'] == true ? 'نشطة' : 'متوقفة'}');
  }

  Future<void> _showHostsScoped() async {
    final rows = await Supabase.instance.client.from('profiles').select('id,display_name,username,role,is_active,agency_id').eq('role', 'HOST').order('created_at', ascending: false).limit(150);
    if (!mounted) return;
    await _simpleList('🎙️ المضيفون', rows, (r) => '${r['display_name'] ?? r['username'] ?? 'مضيف'} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<void> _showTeamRole(String wanted) async {
    final rows = await Supabase.instance.client.from('profiles').select('id,display_name,username,role,is_active').eq('role', wanted).order('created_at', ascending: false).limit(100);
    if (!mounted) return;
    await _simpleList(wanted == 'BD' ? '💼 فريق BD' : '🛡️ فريق Admin', rows, (r) => '${r['display_name'] ?? r['username'] ?? wanted} • ${r['is_active'] == true ? 'نشط' : 'متوقف'}');
  }

  Future<void> _simpleList(String title, List rows, String Function(dynamic) label) async {
    await _sheet(
      title,
      [
        if (rows.isEmpty) const Text('لا توجد بيانات', style: TextStyle(color: Colors.white54)),
        ...rows.map((r) => Card(
          color: _card,
          child: ListTile(
            title: Text(label(r), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(r['id'].toString(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        )),
      ],
    );
  }

  Future<void> _showAgentStats() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final agencies = await Supabase.instance.client.from('agencies').select('id').eq('owner_id', uid).limit(1);
    final list = List<dynamic>.from(agencies);
    if (list.isEmpty) {
      _message('لا توجد وكالة مرتبطة بك');
      return;
    }
    final aid = list.first['id'];
    final hosts = await Supabase.instance.client.from('profiles').select('id').eq('agency_id', aid).eq('role', 'HOST');
    final ledger = await Supabase.instance.client.from('agency_commission_ledger').select('source_amount,work_share_amount').eq('agency_id', aid);
    int source = 0;
    int work = 0;
    for (final item in ledger) {
      final r = Map<String, dynamic>.from(item as Map);
      source += (r['source_amount'] as num?)?.toInt() ?? 0;
      work += (r['work_share_amount'] as num?)?.toInt() ?? 0;
    }
    _infoDialog('📈 إحصائيات الوكالة', 'المضيفون: ${hosts.length}\nحركة المصدر: $source\nحصة الشغل: $work');
  }

  Future<void> _showHostStats() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final rows = await Supabase.instance.client.from('host_earnings').select('source_amount,created_at').eq('host_id', uid).limit(200);
    int total = 0;
    for (final item in rows) {
      total += (item['source_amount'] as num?)?.toInt() ?? 0;
    }
    _infoDialog('⏱️ سجل البث', 'عمليات الأرباح: ${rows.length}\nالحركة المسجلة: $total');
  }

  Future<void> _showHostTasks() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final rows = await Supabase.instance.client.from('host_earnings').select('source_amount,created_at').eq('host_id', uid).order('created_at', ascending: false).limit(30);
    if (!mounted) return;
    await _simpleList('📋 المهام والنشاط', rows, (r) => 'نشاط: ${r['source_amount']} • ${r['created_at']}');
  }

  Future<void> _showHostLevel() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final p = await Supabase.instance.client.from('profiles').select('vip_level,is_verified').eq('id', uid).maybeSingle();
    _infoDialog('⭐ المستوى', 'VIP: ${p?['vip_level'] ?? '—'}\nالتحقق: ${p?['is_verified'] == true ? 'موثق' : 'غير موثق'}');
  }

  Future<void> _sheet(String title, List<Widget> children) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
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
              Text(title, style: const TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  void _infoDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: Text(title, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900)),
        content: Text(body, style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: _gold2));
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
                  const CircleAvatar(radius: 28, backgroundColor: Color(0xFF422511), child: Icon(Icons.shield, color: _gold, size: 30)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(color: _gold, fontSize: 21, fontWeight: FontWeight.w900))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (role == 'SUPER_ADMIN') _infoCard('صلاحية VIP', 'يمكن منح VIP من 1 إلى 6 فقط.'),
            if (role == 'MANAGER') _infoCard('التفويض', 'إدارة BD وAdmin والوكالات حسب الصلاحيات.'),
            if (role == 'BD') _infoCard('BD', 'إدارة ومتابعة الوكالات ضمن نطاقك.'),
            if (role == 'ADMIN') _infoCard('Admin', 'إدارة الأدوات المسموحة لك فقط.'),
            if (role == 'AGENT') _infoCard('الوكيل', 'إدارة وكالتك ومضيفيك.'),
            if (role == 'HOST') _infoCard('المضيف', 'مركزك الشخصي للأرباح والبث والمهام والمستوى.'),
            const SizedBox(height: 10),
            ...permissions.map(
              (p) => Card(
                color: _card,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: _gold),
                  title: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_left, color: Colors.white38),
                  onTap: () => _action(p),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _gold2)),
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
