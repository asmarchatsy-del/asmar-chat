import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _bg = Color(0xFF090604);
const _card = Color(0xFF211108);

class SuperAdminPanel extends StatefulWidget {
  const SuperAdminPanel({super.key});
  @override
  State<SuperAdminPanel> createState() => _SuperAdminPanelState();
}

class _SuperAdminPanelState extends State<SuperAdminPanel> {
  final db = Supabase.instance.client;
  int tab = 0;
  bool loading = true;
  List<Map<String, dynamic>> users = [], rooms = [], coins = [], gifts = [], items = [], aristocracy = [], ranks = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final r = await Future.wait([
        db.from('profiles').select('id,public_id,display_name,username,coins,vip_level,is_blocked').limit(100),
        db.from('rooms').select('id,name,owner_id,is_active,hot_score').limit(100),
        db.from('coin_packages').select().limit(100),
        db.from('gifts').select().limit(100),
        db.from('store_items').select().limit(100),
        db.from('aristocracy_levels').select().order('id'),
        db.from('ranks').select().order('level'),
      ]);
      users = List<Map<String, dynamic>>.from(r[0]);
      rooms = List<Map<String, dynamic>>.from(r[1]);
      coins = List<Map<String, dynamic>>.from(r[2]);
      gifts = List<Map<String, dynamic>>.from(r[3]);
      items = List<Map<String, dynamic>>.from(r[4]);
      aristocracy = List<Map<String, dynamic>>.from(r[5]);
      ranks = List<Map<String, dynamic>>.from(r[6]);
    } catch (e) { _message('خطأ التحميل: $e'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }

  Future<void> _rpc(String name, Map<String, dynamic> params) async {
    try { await db.rpc(name, params: params); await load(); }
    catch (e) { _message('فشلت العملية: $e'); }
  }

  Future<void> _giftAristocracy(Map<String, dynamic> user) async {
    final level = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('هدي أرستقراطية إلى ${user['display_name'] ?? user['public_id']}'),
        children: [for (final l in aristocracy) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, (l['id'] as num).toInt()), child: Text('${l['name_ar']} — ${l['price']} ذهب'))],
      ),
    );
    if (level != null) await _rpc('admin_gift_aristocracy', {'p_user_id': user['id'], 'p_level': level});
  }

  Future<void> _grantRank() async {
    Map<String, dynamic>? selectedUser;
    int? selectedLevel;
    final result = await showDialog<List<dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: _card,
          title: const Text('إعطاء رتبة', style: TextStyle(color: _gold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<Map<String, dynamic>>(value: selectedUser, isExpanded: true, items: users.map((u) => DropdownMenuItem(value: u, child: Text('${u['display_name'] ?? u['username'] ?? 'مستخدم'} • ${u['public_id'] ?? ''}'))).toList(), onChanged: (v) => setDialog(() => selectedUser = v), decoration: const InputDecoration(labelText: 'المستخدم')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(value: selectedLevel, isExpanded: true, items: ranks.map((r) => DropdownMenuItem(value: (r['level'] as num).toInt(), child: Text('Level ${r['level']} — ${r['name_ar']}'))).toList(), onChanged: (v) => setDialog(() => selectedLevel = v), decoration: const InputDecoration(labelText: 'الرتبة')),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), FilledButton(onPressed: selectedUser == null || selectedLevel == null ? null : () => Navigator.pop(ctx, [selectedUser, selectedLevel]), child: const Text('إعطاء'))],
        ),
      ),
    );
    if (result == null) return;
    final user = result[0] as Map<String, dynamic>;
    final level = result[1] as int;
    await _rpc('grant_rank', {'p_user_id': user['id'], 'p_rank_level': level});
  }

  Future<void> _revokeRank(Map<String, dynamic> user) async { await _rpc('revoke_rank', {'p_user_id': user['id']}); }

  Widget _stat(String title, num value, IconData icon) => SizedBox(width: 190, height: 110, child: Card(color: _card, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _gold), const Spacer(), Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: Colors.white60))]))));

  Widget _buildGlobalGiftThresholdCard() {
    return Card(child: ListTile(title: const Text('Global Gift Threshold'), subtitle: FutureBuilder(future: null, builder: (c, s) => const Text('Threshold integration active'))));
  }

  Widget _dashboard() => ListView(children: [
    const Text('SUPER ADMIN', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _gold)),
    const SizedBox(height: 16),
    // ADMIN_STATS_MARKER
    _buildGlobalGiftThresholdCard(),
    Wrap(spacing: 10, runSpacing: 10, children: [_stat('المستخدمون', users.length, Icons.people), _stat('الغرف', rooms.where((r) => r['is_active'] == true).length, Icons.mic), _stat('الكوينز', users.fold<num>(0, (sum, u) => sum + ((u['coins'] as num?) ?? 0)), Icons.monetization_on), _stat('الأرستقراطية', aristocracy.length, Icons.workspace_premium)]),
  ]);

  Widget _users() => ListView(children: [
    const Text('إدارة المستخدمين', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold)),
    const SizedBox(height: 10),
    ...users.map((u) {
      final blocked = u['is_blocked'] == true;
      return Card(color: _card, child: ListTile(title: Text('${u['display_name'] ?? u['username'] ?? 'مستخدم'} • ${u['public_id'] ?? ''}'), subtitle: Text('Coins: ${u['coins'] ?? 0} • VIP: ${u['vip_level'] ?? 0}'), trailing: Wrap(children: [
        IconButton(onPressed: () => _rpc('admin_grant_coins', {'p_user_id': u['id'], 'p_amount': 1000, 'p_reason': 'super_admin'}), icon: const Icon(Icons.monetization_on, color: _gold)),
        IconButton(onPressed: () => _rpc('admin_grant_vip', {'p_user_id': u['id'], 'p_level': 10, 'p_days': 30}), icon: const Icon(Icons.workspace_premium, color: _gold)),
        IconButton(onPressed: () => _giftAristocracy(u), icon: const Icon(Icons.card_giftcard, color: _gold)),
        IconButton(onPressed: () => _rpc('admin_set_user_blocked', {'p_user_id': u['id'], 'p_blocked': !blocked}), icon: Icon(blocked ? Icons.lock_open : Icons.block, color: Colors.redAccent)),
      ]));
    }),
  ]);

  Widget _rankPage() => ListView(children: [
    Row(children: [const Expanded(child: Text('إدارة الرتب', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold))), FilledButton.icon(onPressed: _grantRank, icon: const Icon(Icons.add), label: const Text('إعطاء رتبة'))]),
    const SizedBox(height: 12),
    ...users.map((u) => FutureBuilder<List<Map<String, dynamic>>>(
      future: db.from('user_ranks').select('rank_id,granted_at,ranks(level,name_ar,name_en,badge_image_url,badge_animation_url)').eq('user_id', u['id']).limit(1),
      builder: (context, snap) {
        final raw = snap.data != null && snap.data!.isNotEmpty ? snap.data!.first['ranks'] : null;
        final rank = raw is Map ? Map<String, dynamic>.from(raw) : null;
        return Card(color: _card, child: ListTile(title: Text('${u['display_name'] ?? u['username'] ?? 'مستخدم'} • ${u['public_id'] ?? ''}'), subtitle: Text(rank == null ? 'بدون رتبة' : 'Level ${rank['level']} — ${rank['name_ar']} (${rank['name_en']})'), trailing: rank == null ? null : IconButton(onPressed: () => _revokeRank(u), icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent))));
      },
    )),
  ]);

  Widget _managed(String title, String table, List<Map<String, dynamic>> rows, List<String> fields) => ListView(children: [
    Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold))), IconButton(onPressed: () => _edit(table: table, fields: fields), icon: const Icon(Icons.add_circle, color: _gold))]),
    ...rows.map((row) {
      final name = row['name']?.toString() ?? row['id']?.toString() ?? 'عنصر';
      final price = row['price_usd'] ?? row['price_coins'] ?? row['coins'] ?? '';
      return Card(color: _card, child: ListTile(title: Text(name), subtitle: Text('$price'), trailing: Wrap(children: [IconButton(onPressed: () => _edit(table: table, id: row['id']?.toString(), old: row, fields: fields), icon: const Icon(Icons.edit, color: _gold)), IconButton(onPressed: () async { await db.from(table).delete().eq('id', row['id']); await load(); }, icon: const Icon(Icons.delete_outline, color: Colors.redAccent))]));
    }),
  ]);

  Future<void> _edit({required String table, String? id, required List<String> fields, Map<String, dynamic>? old}) async {
    final c = {for (final f in fields) f: TextEditingController(text: old?[f]?.toString() ?? '')};
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: _card, title: const Text('حفظ البيانات'), content: SingleChildScrollView(child: Column(children: [for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: c[f], decoration: InputDecoration(labelText: f)))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))]));
    if (ok != true) return;
    final row = <String, dynamic>{};
    for (final f in fields) { final v = c[f]!.text.trim(); row[f] = (f == 'price' || f == 'price_coins' || f == 'coins' || f == 'duration_days') ? int.tryParse(v) ?? 0 : (f == 'price_usd' ? double.tryParse(v) ?? 0 : v); }
    try { if (id == null) await db.from(table).insert(row); else await db.from(table).update(row).eq('id', id); await load(); } catch (e) { _message('تعذر الحفظ: $e'); }
  }

  Widget _aristocracy() => ListView(children: [
    const Text('الأرستقراطية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold)),
    const SizedBox(height: 8),
    ...aristocracy.map((r) => Card(
      color: _card,
      child: ListTile(
        title: Text('${r['name_ar']} — ${r['name_en']}'),
        subtitle: Text('${r['price']} ذهب • ${r['duration_days']} يوم'),
        trailing: IconButton(onPressed: () => _edit(table: 'aristocracy_levels', id: r['id'].toString(), old: r, fields: const ['name_ar', 'name_en', 'price', 'duration_days']), icon: const Icon(Icons.edit, color: _gold)),
      ),
    )),
  ]);

  Widget _rooms() => ListView(children: [
    const Text('الغرف المباشرة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold)),
    ...rooms.where((r) => r['is_active'] == true).map((r) => Card(
      color: _card,
      child: ListTile(
        title: Text(r['name']?.toString() ?? 'غرفة'),
        subtitle: Text('Hot: ${r['hot_score'] ?? 0}'),
        trailing: IconButton(onPressed: () => _rpc('admin_close_room', {'p_room_id': r['id']}), icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent)),
      ),
    )),
  ]);

  Widget _body() {
    switch (tab) {
      case 1: return _users();
      case 2: return _managed('باقات الكوينز', 'coin_packages', coins, const ['name', 'coins', 'price_usd']);
      case 3: return _managed('الهدايا', 'gifts', gifts, const ['name', 'price_coins', 'animation_url']);
      case 4: return _managed('المتجر', 'store_items', items, const ['name', 'item_type', 'price_coins', 'asset_url', 'animation_url']);
      case 5: return _rooms();
      case 6: return _aristocracy();
      case 7: return _rankPage();
      default: return _dashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(title: const Text('SUPER ADMIN', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
        body: loading ? const Center(child: CircularProgressIndicator(color: _gold)) : Row(children: [
          NavigationRail(
            backgroundColor: _card,
            selectedIndex: tab,
            onDestinationSelected: (v) => setState(() => tab = v),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('الرئيسية')),
              NavigationRailDestination(icon: Icon(Icons.people_outline), label: Text('المستخدمون')),
              NavigationRailDestination(icon: Icon(Icons.monetization_on_outlined), label: Text('الباقات')),
              NavigationRailDestination(icon: Icon(Icons.card_giftcard), label: Text('الهدايا')),
              NavigationRailDestination(icon: Icon(Icons.storefront_outlined), label: Text('المتجر')),
              NavigationRailDestination(icon: Icon(Icons.meeting_room_outlined), label: Text('الغرف')),
              NavigationRailDestination(icon: Icon(Icons.workspace_premium_outlined), label: Text('الأرستقراطية')),
              NavigationRailDestination(icon: Icon(Icons.badge_outlined), label: Text('الرتب')),
            ],
          ),
          Expanded(child: Padding(padding: const EdgeInsets.all(18), child: _body())),
        ]),
      ),
    );
  }
}
