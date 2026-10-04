import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _gold = Color(0xFFFFD36A);
const _bg = Color(0xFF090604);
const _card = Color(0xFF211108);
final _db = Supabase.instance.client;

class SuperAdminPanel extends StatefulWidget {
  const SuperAdminPanel({super.key});
  @override State<SuperAdminPanel> createState() => _SuperAdminPanelState();
}

class _SuperAdminPanelState extends State<SuperAdminPanel> {
  int tab = 0;
  bool loading = true;
  List<Map<String, dynamic>> users = [], rooms = [], coins = [], vips = [], items = [], gifts = [];

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final result = await Future.wait([
        _db.from('profiles').select('id,public_id,display_name,username,coins,diamonds,vip_level,is_blocked').order('created_at', ascending: false).limit(100),
        _db.from('rooms').select('id,name,owner_id,is_active,hot_score,created_at').order('created_at', ascending: false).limit(100),
        _db.from('coin_packages').select().order('created_at', ascending: false),
        _db.from('vip_packages').select().order('tier').order('billing_period'),
        _db.from('store_items').select().order('created_at', ascending: false),
        _db.from('gifts').select().order('created_at', ascending: false),
      ]);
      users = List<Map<String, dynamic>>.from(result[0]);
      rooms = List<Map<String, dynamic>>.from(result[1]);
      coins = List<Map<String, dynamic>>.from(result[2]);
      vips = List<Map<String, dynamic>>.from(result[3]);
      items = List<Map<String, dynamic>>.from(result[4]);
      gifts = List<Map<String, dynamic>>.from(result[5]);
    } catch (e) { _msg('خطأ التحميل: $e'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  void _msg(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }

  Future<void> _action(String action, String id, {int amount = 0, int vip = 0}) async {
    try {
      if (action == 'coins') await _db.rpc('admin_grant_coins', params: {'p_user_id': id, 'p_amount': amount, 'p_reason': 'super_admin_panel'});
      if (action == 'vip') await _db.rpc('admin_grant_vip', params: {'p_user_id': id, 'p_level': vip, 'p_days': 30});
      if (action == 'block' || action == 'unblock') await _db.rpc('admin_set_user_blocked', params: {'p_user_id': id, 'p_blocked': action == 'block'});
      if (action == 'close') await _db.rpc('admin_close_room', params: {'p_room_id': id});
      await load();
    } catch (e) { _msg('فشلت العملية: $e'); }
  }

  Future<void> _form(String title, Map<String, dynamic>? old, Future<void> Function(Map<String, String>) save, List<String> fields) async {
    final controllers = {for (final field in fields) field: TextEditingController(text: old?[field]?.toString() ?? '')};
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      title: Text(title),
      content: SingleChildScrollView(child: Column(children: fields.map((field) => Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: controllers[field], decoration: InputDecoration(labelText: field)))).toList())),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ'))],
    ));
    if (ok == true) { await save({for (final entry in controllers.entries) entry.key: entry.value.text.trim()}); await load(); }
  }

  Future<void> _coinSave(Map<String, String> data, String? id) async {
    final row = {'name': data['name'], 'coins': int.tryParse(data['coins'] ?? '') ?? 0, 'price_usd': double.tryParse(data['price_usd'] ?? '') ?? 0, 'is_active': true};
    if (id == null) await _db.from('coin_packages').insert(row); else await _db.from('coin_packages').update(row).eq('id', id);
  }

  Future<void> _vipSave(Map<String, String> data, String? id) async {
    final row = {'name': data['name'], 'tier': data['tier'], 'billing_period': data['billing_period'], 'price_usd': double.tryParse(data['price_usd'] ?? '') ?? 0, 'coin_price': int.tryParse(data['coin_price'] ?? '')};
    if (id == null) await _db.from('vip_packages').insert(row); else await _db.from('vip_packages').update(row).eq('id', id);
  }

  Future<void> _itemSave(Map<String, String> data, String? id) async {
    final row = {'name': data['name'], 'item_type': data['item_type'], 'price_coins': int.tryParse(data['price_coins'] ?? '') ?? 0, 'asset_url': data['asset_url'], 'animation_url': data['animation_url'], 'is_active': true};
    if (id == null) await _db.from('store_items').insert(row); else await _db.from('store_items').update(row).eq('id', id);
  }

  Future<void> _giftSave(Map<String, String> data, String? id) async {
    final row = {'name': data['name'], 'price_coins': int.tryParse(data['price_coins'] ?? '') ?? 0, 'animation_url': data['animation_url'], 'is_active': true};
    if (id == null) await _db.from('gifts').insert(row); else await _db.from('gifts').update(row).eq('id', id);
  }

  Widget _card(String title, String subtitle, VoidCallback edit, VoidCallback remove) => Card(color: _card, child: ListTile(title: Text(title), subtitle: Text(subtitle), trailing: Wrap(children: [IconButton(onPressed: edit, icon: const Icon(Icons.edit, color: _gold)), IconButton(onPressed: remove, icon: const Icon(Icons.delete_outline, color: Colors.redAccent))])));
  Widget _stat(String title, num value, IconData icon) => SizedBox(width: 220, height: 120, child: Card(color: _card, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _gold), const Spacer(), Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: Colors.white60))]))));

  Widget _dashboard() => ListView(children: [const Text('لوحة Super Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _gold)), const SizedBox(height: 18), Wrap(spacing: 10, runSpacing: 10, children: [_stat('المستخدمون', users.length, Icons.people), _stat('الغرف المباشرة', rooms.where((r) => r['is_active'] == true).length, Icons.mic), _stat('إجمالي الكوينز', users.fold<num>(0, (sum, u) => sum + ((u['coins'] as num?) ?? 0)), Icons.monetization_on)]), const SizedBox(height: 20), _walletStats()]);

  Widget _walletStats() => FutureBuilder<List<Map<String, dynamic>>>(future: _db.from('wallet_transactions').select('amount,created_at').gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String()), builder: (_, snap) { final rows = snap.data ?? const <Map<String, dynamic>>[]; final total = rows.fold<num>(0, (sum, row) => sum + ((row['amount'] as num?) ?? 0)); return Card(color: _card, child: ListTile(title: const Text('إحصائيات الأرباح — آخر 30 يوم'), subtitle: Text('${rows.length} عملية'), trailing: Text('$total'))); });

  Widget _users() => ListView(children: [const Text('إدارة المستخدمين', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold)), ...users.map((u) => _card('${u['display_name'] ?? u['username'] ?? 'مستخدم'} • ID ${u['public_id'] ?? ''}', 'Coins: ${u['coins'] ?? 0} • Level: ${u['vip_level'] ?? 0}', () => showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [ListTile(title: const Text('إعطاء 1000 كوين'), onTap: () { Navigator.pop(context); _action('coins', u['id'].toString(), amount: 1000); }), ListTile(title: const Text('إعطاء أرستقراطية مستوى 10'), onTap: () { Navigator.pop(context); _action('vip', u['id'].toString(), vip: 10); }), ListTile(title: Text(u['is_blocked'] == true ? 'فك الحظر' : 'حظر'), onTap: () { Navigator.pop(context); _action(u['is_blocked'] == true ? 'unblock' : 'block', u['id'].toString()); })])), () => _action(u['is_blocked'] == true ? 'unblock' : 'block', u['id'].toString()))) ]);

  Widget _packages() => ListView(children: [Row(children: [const Expanded(child: Text('باقات الكوينز', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold))), IconButton(onPressed: () => _form('إضافة باقة', null, (d) => _coinSave(d, null), ['name', 'coins', 'price_usd']), icon: const Icon(Icons.add_circle, color: _gold))]), ...coins.map((r) => _card(r['name'].toString(), '${r['coins']} كوين = \$${r['price_usd']}', () => _form('تعديل', r, (d) => _coinSave(d, r['id'].toString()), ['name', 'coins', 'price_usd']), () => _db.from('coin_packages').delete().eq('id', r['id']).then((_) => load()))), const SizedBox(height: 18), Row(children: [const Expanded(child: Text('باقات الأرستقراطية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold))), IconButton(onPressed: () => _form('إضافة باقة', null, (d) => _vipSave(d, null), ['name', 'tier', 'billing_period', 'price_usd', 'coin_price']), icon: const Icon(Icons.add_circle, color: _gold))]), ...vips.map((r) => _card(r['name'].toString(), '${r['billing_period']} • \$${r['price_usd']}', () => _form('تعديل', r, (d) => _vipSave(d, r['id'].toString()), ['name', 'tier', 'billing_period', 'price_usd', 'coin_price']), () => _db.from('vip_packages').delete().eq('id', r['id']).then((_) => load()))) ]);

  Widget _section(String title, Widget body, VoidCallback add) => ListView(children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold))), IconButton(onPressed: add, icon: const Icon(Icons.add_circle, color: _gold))]), body]);
  Widget _gifts() => _section('الهدايا', Column(children: gifts.map((r) => _card(r['name'].toString(), '${r['price_coins']} كوين • ${r['animation_url'] ?? ''}', () => _form('تعديل هدية', r, (d) => _giftSave(d, r['id'].toString()), ['name', 'price_coins', 'animation_url']), () => _db.from('gifts').delete().eq('id', r['id']).then((_) => load()))).toList()), () => _form('إضافة هدية', null, (d) => _giftSave(d, null), ['name', 'price_coins', 'animation_url']));
  Widget _store() => _section('المتجر', Column(children: items.map((r) => _card(r['name'].toString(), '${r['item_type']} • ${r['price_coins']} كوين', () => _form('تعديل عنصر', r, (d) => _itemSave(d, r['id'].toString()), ['name', 'item_type', 'price_coins', 'asset_url', 'animation_url']), () => _db.from('store_items').delete().eq('id', r['id']).then((_) => load()))).toList()), () => _form('إضافة عنصر', null, (d) => _itemSave(d, null), ['name', 'item_type', 'price_coins', 'asset_url', 'animation_url']));
  Widget _rooms() => ListView(children: [const Text('الغرف المباشرة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gold)), ...rooms.where((r) => r['is_active'] == true).map((r) => _card(r['name'].toString(), 'Hot: ${r['hot_score'] ?? 0}', () {}, () => _action('close', r['id'].toString()))) ]);

  Widget _body() { switch (tab) { case 1: return _users(); case 2: return _packages(); case 3: return _gifts(); case 4: return _store(); case 5: return _rooms(); default: return _dashboard(); } }

  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: _bg, appBar: AppBar(title: const Text('SUPER ADMIN', style: TextStyle(color: _gold, fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]), body: loading ? const Center(child: CircularProgressIndicator(color: _gold)) : Row(children: [NavigationRail(backgroundColor: _card, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), labelType: NavigationRailLabelType.all, destinations: const [NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('الرئيسية')), NavigationRailDestination(icon: Icon(Icons.people_outline), label: Text('المستخدمون')), NavigationRailDestination(icon: Icon(Icons.monetization_on_outlined), label: Text('الباقات')), NavigationRailDestination(icon: Icon(Icons.card_giftcard), label: Text('الهدايا')), NavigationRailDestination(icon: Icon(Icons.storefront_outlined), label: Text('المتجر')), NavigationRailDestination(icon: Icon(Icons.meeting_room_outlined), label: Text('الغرف'))]), Expanded(child: Padding(padding: const EdgeInsets.all(16), child: _body()))]));
}
