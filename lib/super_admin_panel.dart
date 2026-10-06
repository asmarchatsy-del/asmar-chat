import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gold = Color(0xFFFFD36A);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

class SuperAdminPanel extends StatefulWidget {
  const SuperAdminPanel({super.key});
  @override State<SuperAdminPanel> createState() => _SuperAdminPanelState();
}

class _SuperAdminPanelState extends State<SuperAdminPanel> {
  bool loading = true;
  bool authorized = false;
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> users = [];

  @override
  void initState() { super.initState(); _loadRooms(); }

  Future<void> _loadRooms() async {
    setState(() => loading = true);
    try {
      final can = await Supabase.instance.client.rpc('admin_can_manage_dashboard') as bool? ?? false;
      if (!can) { if (mounted) setState(() { authorized = false; loading = false; }); return; }
      final result = await Future.wait([
        Supabase.instance.client.from('rooms').select('id,name,is_active,sort_order,hot_score,country_code,seat_count').order('sort_order', ascending: true, nullsFirst: false).order('hot_score', ascending: false).order('created_at', ascending: false).limit(100),
        Supabase.instance.client.from('profiles').select('id,public_id,username,display_name,role,is_active,coins,svip_level,is_verified').order('created_at', ascending: false).limit(50),
      ]);
      if (mounted) setState(() { authorized = true; rooms = List<Map<String, dynamic>>.from(result[0]); users = List<Map<String, dynamic>>.from(result[1]); loading = false; });
    } catch (e) { if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل لوحة الإدارة: $e'))); } }
  }

  Future<void> _pin(Map<String, dynamic> room, int? position) async {
    try {
      await Supabase.instance.client.rpc('admin_set_room_sort_order', params: {'p_room_id': room['id'], 'p_sort_order': position});
      await _loadRooms();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(position == null ? 'تم إلغاء تثبيت ${room['name']}' : 'تم تثبيت ${room['name']} في المركز $position')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تثبيت الغرفة: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Super Admin'), actions: [IconButton(onPressed: _loadRooms, icon: const Icon(Icons.refresh))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Global Gift Active', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (!authorized) const Card(child: ListTile(title: Text('لا توجد صلاحية إدارية')))
          else ...[
            _users(),
            const SizedBox(height: 18),
            _roomOrdering(),
          ],
        ],
      ),
    ),
  );

  Widget _users() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF4C3019))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('آخر المستخدمين (' + users.length.toString() + ')', style: const TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      if (users.isEmpty) const Text('لا توجد حسابات', style: TextStyle(color: Colors.white54))
      else ...users.take(12).map((u) => ListTile(
        dense: true, contentPadding: EdgeInsets.zero,
        leading: Icon(u['is_verified'] == true ? Icons.verified : Icons.person, color: gold),
        title: Text((u['display_name'] ?? u['username'] ?? u['public_id'] ?? 'Asmar').toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: Text('ID ' + (u['public_id'] ?? u['id']).toString() + ' • ' + (u['role'] ?? 'USER').toString() + ' • Coins ' + (u['coins'] ?? 0).toString(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
        trailing: Icon(u['is_active'] == true ? Icons.check_circle : Icons.block, color: u['is_active'] == true ? Colors.green : Colors.red, size: 18),
      )),
    ]),
  );

  Widget _roomOrdering() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF4C3019))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ترتيب غرف اللوبي', style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text('ثبّت أي غرفة في المركز الأول أو الثاني. عند تثبيت غرفة جديدة يتم تحرير المركز السابق تلقائيًا.', style: TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 12),
        if (loading) const Center(child: CircularProgressIndicator(color: gold))
        else if (rooms.isEmpty) const Text('لا توجد غرف', style: TextStyle(color: Colors.white54))
        else ...rooms.map((room) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF120805), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(room['sort_order'] != null ? Icons.push_pin : Icons.meeting_room, color: gold),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room['name'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text('${room['country_code'] ?? '—'} • ${room['seat_count'] ?? 15} مقعد • Hot ${room['hot_score'] ?? 0}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ])),
            PopupMenuButton<int?>(
              onSelected: (v) => _pin(room, v),
              itemBuilder: (_) => [
                const PopupMenuItem<int?>(value: 1, child: Text('تثبيت أول روم')),
                const PopupMenuItem<int?>(value: 2, child: Text('تثبيت ثاني روم')),
                if (room['sort_order'] != null) const PopupMenuItem<int?>(value: null, child: Text('إلغاء التثبيت')),
              ],
              icon: const Icon(Icons.push_pin, color: gold),
            ),
          ]),
        )),
      ]),
    );
  }
}
