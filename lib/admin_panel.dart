import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_finance.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int selected = 0;
  int coins = 0;

  final List<Map<String, dynamic>> coinTransactions = [];

  final List<Map<String, dynamic>> users = [];

  final List<Map<String, dynamic>> hosts = [];

  final List<Map<String, dynamic>> agencies = [];

  final List<Map<String, dynamic>> rooms = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await client.from('profiles').select('id,display_name,username,public_id,role,is_active').eq('id', user.id).maybeSingle();
      final role = (profile?['role'] as String? ?? 'USER').toUpperCase();
      // Owner dashboard is strictly CEO-only. Other roles use their own RoleCenter.
      if (role != 'CEO') return;

      final profiles = await client.from('profiles').select('id,display_name,username,public_id,role,is_active,vip_level').order('created_at', ascending: false);
      final wallets = await client.from('wallets').select('user_id,balance');
      final walletByUser = <String, int>{for (final w in wallets) w['user_id'] as String: (w['balance'] as num).toInt()};
      final agenciesData = await client.from('agencies').select('id,name,manager_id,is_active,created_at');
      final roomsData = await client.from('rooms').select('id,name,owner_id,livekit_room_name,is_active,created_at').order('created_at', ascending: false);
      final transactions = await client.from('coin_transactions').select('id,from_user_id,to_user_id,amount,reason,created_at').or('from_user_id.eq.${user.id},to_user_id.eq.${user.id}').order('created_at', ascending: false).limit(100);

      if (!mounted) return;
      setState(() {
        users..clear()..addAll(profiles.map<Map<String, dynamic>>((p) => {
          'id': p['id'], 'publicId': (p['public_id'] ?? p['id']).toString(), 'name': (p['display_name'] ?? p['username'] ?? 'مستخدم').toString(),
          'role': p['role'].toString(), 'vip': p['vip_level']?.toString() ?? '', 'coins': walletByUser[p['id']] ?? 0, 'online': p['is_active'] == true, 'active': p['is_active'] == true,
        }));
        hosts..clear()..addAll(users.where((u) => u['role'] == 'HOST').map((u) => {
          'id': u['id'], 'name': u['name'], 'agency': '—', 'status': true, 'coins': u['coins'],
        }));
        agencies..clear()..addAll(agenciesData.map<Map<String, dynamic>>((a) => {
          'id': a['id'], 'name': a['name'], 'manager': a['manager_id']?.toString() ?? '—',
          'hosts': profiles.where((p) => p['role'] == 'HOST').length, 'status': a['is_active'] == true,
        }));
        rooms..clear()..addAll(roomsData.map<Map<String, dynamic>>((r) => {
          'id': r['id'], 'name': r['name'], 'host': r['owner_id']?.toString() ?? '—',
          'users': 0, 'active': r['is_active'] == true,
        }));
        coins = walletByUser[user.id] ?? 0;
        coinTransactions..clear()..addAll(transactions.map<Map<String, dynamic>>((t) => {
          'id': t['id'], 'recipient': t['to_user_id']?.toString() ?? '—',
          'type': t['reason']?.toString() ?? 'transfer', 'amount': (t['amount'] as num).toInt(),
          'balanceAfter': coins, 'time': t['created_at'].toString(),
        }));
      });
    } catch (e) {
      if (mounted) _message('تعذر تحميل بيانات الإدارة: $e');
    }
  }



  Future<void> _saveData() async {}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF100805),
          foregroundColor: Colors.white,
          title: const Text(
            'لوحة الإدارة',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            _header(),
            const SizedBox(height: 12),
            _tabs(),
            const SizedBox(height: 12),
            Expanded(
              child: selected == 0
                  ? _dashboard()
                  : selected == 1
                      ? _rooms()
                      : _settings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6B2C0B),
              Color(0xFF160A06),
            ],
          ),
          border: Border.all(color: gold2),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF422511),
              child: Icon(
                Icons.admin_panel_settings,
                color: gold,
                size: 32,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHAT • OWNER',
                    style: TextStyle(
                      color: gold,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'لوحة Chat الرئيسية • تحكم المالك',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.verified,
              color: gold,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tabButton(0, 'الرئيسية', Icons.dashboard),
          _tabButton(1, 'الغرف', Icons.meeting_room),
          _tabButton(2, 'الإعدادات', Icons.settings),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String title, IconData icon) {
    final active = selected == index;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => selected = index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF4A2C12) : card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? gold2 : Colors.white12,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: active ? gold : Colors.white60,
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: active ? gold : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ownerWallet(),
        const SizedBox(height: 16),
        const Text(
          'الأوسمة والصلاحيات',
          style: TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _RoleBadge(title: 'CEO', icon: Icons.workspace_premium),
            _RoleBadge(title: 'SUPER ADMIN', icon: Icons.shield),
            _RoleBadge(title: 'ADMIN', icon: Icons.admin_panel_settings),
            _RoleBadge(title: 'MANAGER', icon: Icons.manage_accounts),
            _RoleBadge(title: 'HOST', icon: Icons.mic),
            _RoleBadge(title: 'AGENT', icon: Icons.business),
            _RoleBadge(title: 'BD', icon: Icons.handshake),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'المستخدمون',
                '${users.length}',
                Icons.people,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'الغرف',
                '${rooms.length}',
                Icons.meeting_room,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'المضيفون',
                '${hosts.length}',
                Icons.mic,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'VIP',
                '${users.where((u) => ((u['vip'] ?? 0) as num) > 0).length}',
                Icons.workspace_premium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            color: gold,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _action(
          'إضافة غرفة',
          Icons.add_home_work,
          _addRoom,
        ),
        _action(
          'إدارة المضيفين',
          Icons.mic_external_on,
          _manageHosts,
        ),
        _action(
          'إدارة الوكالات',
          Icons.business,
          _manageAgencies,
        ),
      ],
    );
  }

  Widget _rooms() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF4C3019)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF422511),
                child: Icon(
                  Icons.mic,
                  color: gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${room['host']} • ${room['users']} مستخدم',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: room['active'],
                activeColor: gold,
                onChanged: (value) async {
                  try { await Supabase.instance.client.rpc('admin_set_room_active', params: {'p_room_id': room['id'], 'p_active': value}); if (mounted) { setState(() => room['active'] = value); _message('تم تحديث حالة الغرفة'); } } catch (e) { _message('فشل تحديث الغرفة: $e'); }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _setting(
          'الإشعارات',
          Icons.notifications,
          true,
        ),
        _setting(
          'وضع المشرف',
          Icons.admin_panel_settings,
          true,
        ),
        _setting(
          'السماح بالغرف العامة',
          Icons.public,
          true,
        ),
        _setting(
          'الحماية',
          Icons.security,
          true,
        ),
      ],
    );
  }

  int get activeHosts => hosts.where((h) => h['status'] == true).length;
  int get activeAgencies => agencies.where((a) => a['status'] == true).length;
  int get totalUserCoins => users.fold<int>(0, (sum, u) => sum + ((u['coins'] ?? 0) as int));
  int get totalHostCoins => hosts.fold<int>(0, (sum, h) => sum + ((h['coins'] ?? 0) as int));

  String _roleLabel(String role) {
    switch (role) {
      case 'CEO': return 'CEO';
      case 'SUPER_ADMIN': return 'SUPER ADMIN';
      case 'MANAGER': return 'MANAGER';
      case 'ADMIN': return 'ADMIN';
      case 'HOST': return 'HOST';
      case 'AGENT': return 'AGENT';
      case 'BD': return 'BD';
      default: return 'USER';
    }
  }

  List<String> _permissionsFor(String role) {
    switch (role) {
      case 'CEO': return ['إدارة كاملة', 'الكوينزات', 'المستخدمون', 'الغرف', 'المضيفون', 'الوكالات', 'الصلاحيات'];
      case 'SUPER_ADMIN': return ['المستخدمون', 'الغرف', 'المضيفون', 'الوكالات', 'الإعدادات'];
      case 'MANAGER': return ['المضيفون', 'الوكالات', 'الغرف'];
      case 'ADMIN': return ['المستخدمون', 'الغرف'];
      case 'HOST': return ['إدارة الغرفة', 'المضيفون'];
      case 'AGENT': return ['الوكالات', 'المضيفون'];
      default: return ['الدردشة'];
    }
  }

  Widget _stat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF4C3019))),
      child: Row(children: [
        Icon(icon, color: gold, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ])),
      ]),
    );
  }

  Widget _roleBadge(String role) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFD36A), Color(0xFF9A5A12)]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(_roleLabel(role), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
  );

  void _liveStats() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إحصائيات مباشرة', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _stat('المستخدمون', users.length.toString(), Icons.people)),
                const SizedBox(width: 8),
                Expanded(child: _stat('المضيفون', activeHosts.toString(), Icons.mic)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _stat('الوكالات', activeAgencies.toString(), Icons.business)),
                const SizedBox(width: 8),
                Expanded(child: _stat('تحويلات', coinTransactions.length.toString(), Icons.swap_horiz)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _stat('كوينز المستخدمين', totalUserCoins.toString(), Icons.monetization_on)),
                const SizedBox(width: 8),
                Expanded(child: _stat('كوينز المضيفين', totalHostCoins.toString(), Icons.stars)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addRoom() async {
    final name=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      backgroundColor:card,title:const Text('إضافة غرفة',style:TextStyle(color:gold,fontWeight:FontWeight.w900)),
      content:TextField(controller:name,decoration:const InputDecoration(labelText:'اسم الغرفة')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('إضافة'))],
    ));
    if(ok!=true||name.text.trim().isEmpty)return;
    try{
      await Supabase.instance.client.from('rooms').insert({'name':name.text.trim(),'owner_id':Supabase.instance.client.auth.currentUser!.id,'is_active':true});
      await _loadData(); _message('تمت إضافة الغرفة');
    }catch(e){_message('فشل إضافة الغرفة: $e');}
  }

  void _manageRoles() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .78,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('نظام الرتب والصلاحيات', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('صلاحيات واجهة الإدارة الحالية — تحتاج حماية Backend عند ربط قاعدة البيانات.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              ...['CEO','SUPER_ADMIN','MANAGER','ADMIN','HOST','AGENT','USER'].map((role) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4C3019))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _roleBadge(role),
                      const Spacer(),
                      Text(role == 'CEO' ? 'صلاحيات كاملة' : _permissionsFor(role).length.toString() + ' صلاحيات', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _permissionsFor(role).map((p) => Chip(
                        label: Text(p, style: const TextStyle(fontSize: 10)),
                        backgroundColor: const Color(0xFF2A180D),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _manageHosts() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .75,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('إدارة المضيفين', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...hosts.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4C3019))),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF422511), child: Icon(h['status'] ? Icons.mic : Icons.mic_off, color: gold)),
                  title: Text(h['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(h['agency'] + ' • ' + h['coins'].toString() + ' Coins', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: Switch(
                    value: h['status'],
                    onChanged: (v) { setState(() => h['status'] = v); _saveData(); Navigator.pop(context); _manageHosts(); },
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _manageAgencies() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .7,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('إدارة الوكالات', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...agencies.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4C3019))),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFF422511), child: Icon(Icons.business, color: gold)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(a['manager'] + ' • ' + a['hosts'].toString() + ' مضيف', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ])),
                    Switch(value: a['status'], onChanged: (v) { setState(() => a['status'] = v); _saveData(); }),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _manageUsers() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .72,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('إدارة المستخدمين', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...users.map((u) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF4C3019))),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF422511), child: Icon(u['online'] ? Icons.person : Icons.person_off, color: gold)),
                  title: Text(u['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${u['publicId']} • ${u['role']} • ${u['coins']} Coins', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async { if (value == 'role') await _changeRole(u); if (value == 'id') await _changePublicId(u); if (value == 'active') await _toggleUser(u); },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'id', child: Text('تغيير ID المستخدم')),
                      PopupMenuItem(value: 'role', child: Text('تغيير الصلاحية')),
                      PopupMenuItem(value: 'active', child: Text('تفعيل / تعطيل')),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleUser(Map<String,dynamic> u) async { try { final next = !(u['active'] == true); await Supabase.instance.client.rpc('admin_set_user_active', params: {'p_user_id': u['id'], 'p_active': next}); await _loadData(); _message(next ? 'تم تفعيل الحساب' : 'تم تعطيل الحساب'); } catch (e) { _message('فشل تحديث الحساب: $e'); } }

  Future<void> _changePublicId(Map<String,dynamic> u) async {
    final controller = TextEditingController(text: (u['publicId'] ?? '').toString());
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        title: Text('تغيير ID • ${u['name']}', style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'ID الظاهر للمستخدم', hintText: 'مثال: 257305 أو ASMAR_1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
    if (value == null || value.trim().isEmpty || value.trim().toUpperCase() == (u['publicId'] ?? '').toString().toUpperCase()) return;
    try {
      await Supabase.instance.client.rpc('admin_set_public_id', params: {'p_user_id': u['id'], 'p_public_id': value.trim()});
      await _loadData();
      _message('تم تغيير ID المستخدم إلى ${value.trim().toUpperCase()}');
    } catch (e) {
      _message('فشل تغيير ID: $e');
    }
  }

  Future<void> _changeRole(Map<String,dynamic> u) async { final roles = ['USER','HOST','AGENT','ADMIN','BD','MANAGER','SUPER_ADMIN']; String selected = (u['role'] ?? 'USER').toString(); final value = await showDialog<String>(context: context, builder: (ctx)=>AlertDialog(backgroundColor: card,title: Text('تغيير رتبة '+u['name'].toString(),style:const TextStyle(color:gold,fontWeight:FontWeight.w900)),content: StatefulBuilder(builder:(ctx,setState)=>DropdownButtonFormField<String>(value: roles.contains(selected) ? selected : 'USER',dropdownColor: card,items: roles.map((r)=>DropdownMenuItem(value:r,child:Text(r))).toList(),onChanged:(v){if(v!=null){selected=v;setState((){});}})),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,selected),child:const Text('حفظ'))],)); if(value==null || value==u['role']) return; try { await Supabase.instance.client.rpc('admin_set_user_role', params: {'p_user_id':u['id'],'p_role':value}); await _loadData(); _message('تم تغيير الرتبة إلى '+value); } catch(e){_message('فشل تغيير الرتبة: $e');} }

  void _coinHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .72,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('سجل تحويلات الكوينز', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              if (coinTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('لا توجد عمليات تحويل حتى الآن', style: TextStyle(color: Colors.white54))),
                )
              else
                ...coinTransactions.reversed.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF4C3019))),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFF422511), child: Icon(Icons.swap_horiz, color: gold)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t['recipient'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(t['type'] + ' • ' + t['time'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        Text('الرصيد بعد العملية: ' + t['balanceAfter'].toString() + ' Coins', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ])),
                      Text('+' + t['amount'].toString(), style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _transferCoins() {
    String type = 'مستخدم';
    String recipient = users.first['name'];
    final amountController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: card,
          title: const Text('توزيع الكوينزات', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: card,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'نوع المستلم'),
                items: const ['مستخدم','مضيف','وكيل'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() {
                    type = v;
                    final list = type == 'مضيف' ? hosts : users;
                    recipient = list.first['name'];
                  });
                },
              ),
              const SizedBox(height: 12),
              Builder(builder: (_) {
                final list = type == 'مضيف' ? hosts : type == 'وكالة' ? agencies : users;
                return DropdownButtonFormField<String>(
                  value: recipient,
                  dropdownColor: card,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'المستلم'),
                  items: list.map<DropdownMenuItem<String>>((x) => DropdownMenuItem<String>(value: x['name'], child: Text(x['name']))).toList(),
                  onChanged: (v) => setDialogState(() => recipient = v ?? recipient),
                );
              }),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'عدد الكوينز'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text) ?? 0;
                if (amount <= 0 || amount > coins) {
                  _message('قيمة الكوينز غير صالحة');
                  return;
                }
                try {
                  final recipientRow = users.firstWhere((u) => u['name'] == recipient);
                  await Supabase.instance.client.rpc('admin_transfer_coins', params: {
                    'p_to_user_id': recipientRow['id'], 'p_amount': amount, 'p_reason': 'owner_transfer',
                  });
                  if (mounted) { Navigator.pop(context); await _loadData(); _message('تم تحويل $amount Coins إلى $recipient'); }
                } catch (e) { _message('فشل التحويل: $e'); }
              },
              child: const Text('تحويل'),
            ),
          ],
        ),
      ),
    );
  }

  void _distributeCoins() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: card,
        title: const Text('توزيع الكوينزات', style: TextStyle(color: gold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'عدد الكوينزات',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0 && amount <= coins) {
                setState(() => coins -= amount);
                Navigator.pop(dialogContext);
                _message('تم تجهيز توزيع $amount Coins');
              } else {
                _message('أدخل مبلغًا صحيحًا ضمن الرصيد');
              }
            },
            child: const Text('توزيع'),
          ),
        ],
      ),
    );
  }

  Widget _ownerWallet() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF7A3A0C), Color(0xFF251006)],
        ),
        border: Border.all(color: gold2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFF422511),
            child: Icon(Icons.account_balance_wallet, color: gold, size: 29),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('محفظة المالك', style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 3),
                Text('$coins Coins', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('الرصيد الحالي: $coins Coins • رصيد حقيقي من قاعدة البيانات', style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Icon(Icons.send, color: gold),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4C3019)),
      ),
      child: Column(
        children: [
          Icon(icon, color: gold, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        tileColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF4C3019)),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF422511),
          child: Icon(icon, color: gold),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white54,
          size: 16,
        ),
      ),
    );
  }

  Widget _setting(
    String title,
    IconData icon,
    bool value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4C3019)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: (_) {},
        activeColor: gold,
        secondary: Icon(icon, color: gold),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: gold2,
      ),
    );
  }
}


class _RoleBadge extends StatelessWidget {
  final String title;
  final IconData icon;
  const _RoleBadge({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF241307),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: gold, size: 18),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
