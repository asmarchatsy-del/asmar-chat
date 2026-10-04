import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _gold = Color(0xFFFFD36A);
const Color _bg = Color(0xFF090604);
const Color _card = Color(0xFF211108);

class SuperAdminPanel extends StatefulWidget {
  const SuperAdminPanel({super.key});
  @override
  State<SuperAdminPanel> createState() => _SuperAdminPanelState();
}

class _SuperAdminPanelState extends State<SuperAdminPanel> {
  final db = Supabase.instance.client;
  int tab = 0;
  bool loading = true;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> coins = [];
  List<Map<String, dynamic>> vips = [];
  List<Map<String, dynamic>> gifts = [];
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        db.from('profiles').select('id,public_id,display_name,username,coins,vip_level,is_blocked').limit(100),
        db.from('rooms').select('id,name,owner_id,is_active,hot_score').limit(100),
        db.from('coin_packages').select().limit(100),
        db.from('vip_packages').select().limit(100),
        db.from('gifts').select().limit(100),
        db.from('store_items').select().limit(100),
      ]);
      users = List<Map<String, dynamic>>.from(results[0]);
      rooms = List<Map<String, dynamic>>.from(results[1]);
      coins = List<Map<String, dynamic>>.from(results[2]);
      vips = List<Map<String, dynamic>>.from(results[3]);
      gifts = List<Map<String, dynamic>>.from(results[4]);
      items = List<Map<String, dynamic>>.from(results[5]);
    } catch (e) {
      _message('خطأ التحميل: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _rpc(String name, Map<String, dynamic> params) async {
    try {
      await db.rpc(name, params: params);
      await load();
    } catch (e) {
      _message('فشلت العملية: $e');
    }
  }

  Future<void> _editRow({required String table, String? id, required List<String> fields, Map<String, dynamic>? old}) async {
    final controllers = <String, TextEditingController>{};
    for (final field in fields) {
      controllers[field] = TextEditingController(text: old?[field]?.toString() ?? '');
    }
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text('حفظ البيانات'),
          content: SingleChildScrollView(
            child: Column(
              children: fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: controllers[field],
                    decoration: InputDecoration(labelText: field),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ')),
          ],
        );
      },
    );
    if (save != true) return;
    final row = <String, dynamic>{};
    for (final field in fields) {
      final value = controllers[field]!.text.trim();
      if (field == 'coins' || field == 'price_coins') {
        row[field] = int.tryParse(value) ?? 0;
      } else if (field == 'price_usd') {
        row[field] = double.tryParse(value) ?? 0;
      } else {
        row[field] = value;
      }
    }
    try {
      if (id == null) {
        await db.from(table).insert(row);
      } else {
        await db.from(table).update(row).eq('id', id);
      }
      await load();
    } catch (e) {
      _message('تعذر الحفظ: $e');
    }
  }

  Widget _stat(String title, num value, IconData icon) {
    return SizedBox(
      width: 190,
      height: 110,
      child: Card(
        color: _card,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: _gold),
            const Spacer(),
            Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(title, style: const TextStyle(color: Colors.white60)),
          ]),
        ),
      ),
    );
  }

  Widget _dashboard() {
    return ListView(
      children: [
        const Text('SUPER ADMIN', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _gold)),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _stat('المستخدمون', users.length, Icons.people),
          _stat('الغرف', rooms.where((r) => r['is_active'] == true).length, Icons.mic),
          _stat('الكوينز', users.fold<num>(0, (sum, u) => sum + ((u['coins'] as num?) ?? 0)), Icons.monetization_on),
        ]),
      ],
    );
  }

  Widget _users() {
    return ListView(
      children: [
        const Text('إدارة المستخدمين', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold)),
        const SizedBox(height: 10),
        ...users.map((u) {
          final blocked = u['is_blocked'] == true;
          return Card(
            color: _card,
            child: ListTile(
              title: Text('${u['display_name'] ?? u['username'] ?? 'مستخدم'} • ${u['public_id'] ?? ''}'),
              subtitle: Text('Coins: ${u['coins'] ?? 0} • Level: ${u['vip_level'] ?? 0}'),
              trailing: Wrap(children: [
                IconButton(onPressed: () => _rpc('admin_grant_coins', {'p_user_id': u['id'], 'p_amount': 1000, 'p_reason': 'super_admin'}), icon: const Icon(Icons.monetization_on, color: _gold)),
                IconButton(onPressed: () => _rpc('admin_grant_vip', {'p_user_id': u['id'], 'p_level': 10, 'p_days': 30}), icon: const Icon(Icons.workspace_premium, color: _gold)),
                IconButton(onPressed: () => _rpc('admin_set_user_blocked', {'p_user_id': u['id'], 'p_blocked': !blocked}), icon: Icon(blocked ? Icons.lock_open : Icons.block, color: Colors.redAccent)),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _managedList(String title, String table, List<Map<String, dynamic>> rows, List<String> fields) {
    return ListView(
      children: [
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold))),
          IconButton(onPressed: () => _editRow(table: table, fields: fields), icon: const Icon(Icons.add_circle, color: _gold)),
        ]),
        ...rows.map((row) {
          final name = row['name']?.toString() ?? row['id']?.toString() ?? 'عنصر';
          final price = row['price_usd'] ?? row['price_coins'] ?? row['coins'] ?? '';
          return Card(
            color: _card,
            child: ListTile(
              title: Text(name),
              subtitle: Text('$price'),
              trailing: Wrap(children: [
                IconButton(onPressed: () => _editRow(table: table, id: row['id']?.toString(), old: row, fields: fields), icon: const Icon(Icons.edit, color: _gold)),
                IconButton(onPressed: () async { await db.from(table).delete().eq('id', row['id']); await load(); }, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _rooms() {
    return ListView(
      children: [
        const Text('الغرف المباشرة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold)),
        ...rooms.where((r) => r['is_active'] == true).map((r) => Card(
          color: _card,
          child: ListTile(
            title: Text(r['name']?.toString() ?? 'غرفة'),
            subtitle: Text('Hot: ${r['hot_score'] ?? 0}'),
            trailing: IconButton(onPressed: () => _rpc('admin_close_room', {'p_room_id': r['id']}), icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent)),
          ),
        )),
      ],
    );
  }

  Widget _body() {
    switch (tab) {
      case 1:
        return _users();
      case 2:
        return _managedList('باقات الكوينز', 'coin_packages', coins, ['name', 'coins', 'price_usd']);
      case 3:
        return _managedList('الهدايا', 'gifts', gifts, ['name', 'price_coins', 'animation_url']);
      case 4:
        return _managedList('المتجر', 'store_items', items, ['name', 'item_type', 'price_coins', 'asset_url', 'animation_url']);
      case 5:
        return _rooms();
      default:
        return _dashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('SUPER ADMIN', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)),
          actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator(color: _gold))
            : Row(children: [
                NavigationRail(
                  backgroundColor: _card,
                  selectedIndex: tab,
                  onDestinationSelected: (value) => setState(() => tab = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('الرئيسية')),
                    NavigationRailDestination(icon: Icon(Icons.people_outline), label: Text('المستخدمون')),
                    NavigationRailDestination(icon: Icon(Icons.monetization_on_outlined), label: Text('الباقات')),
                    NavigationRailDestination(icon: Icon(Icons.card_giftcard), label: Text('الهدايا')),
                    NavigationRailDestination(icon: Icon(Icons.storefront_outlined), label: Text('المتجر')),
                    NavigationRailDestination(icon: Icon(Icons.meeting_room_outlined), label: Text('الغرف')),
                  ],
                ),
                Expanded(child: Padding(padding: const EdgeInsets.all(16), child: _body())),
              ]),
      ),
    );
  }
}
