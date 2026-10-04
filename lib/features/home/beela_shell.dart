import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../asmar/asmar_theme.dart';
import '../room/room_screen.dart';

class BeelaShell extends StatefulWidget {
  const BeelaShell({super.key});
  @override State<BeelaShell> createState() => _BeelaShellState();
}

class _BeelaShellState extends State<BeelaShell> {
  final client = Supabase.instance.client;
  final search = TextEditingController();
  int tab = 0;
  String filter = 'All';
  late final Stream<List<Map<String, dynamic>>> roomsStream;
  late final Stream<List<Map<String, dynamic>>> membersStream;
  final filters = const ['All', 'Jordan 🇯🇴', 'Turkey 🇹🇷', 'Syria 🇸🇾', 'Hot 🔥'];

  @override void initState() {
    super.initState();
    roomsStream = client.from('rooms').stream(primaryKey: ['id']).eq('is_active', true).order('hot_score', ascending: false);
    membersStream = client.from('room_members').stream(primaryKey: ['room_id', 'user_id']);
    search.addListener(_changed);
  }
  void _changed() { if (mounted) setState(() {}); }
  @override void dispose() { search.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: roomsStream,
        builder: (context, rs) {
          if (rs.hasError) return Center(child: Text('تعذر تحميل الغرف: ${rs.error}'));
          final rooms = rs.data ?? const <Map<String, dynamic>>[];
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: membersStream,
            builder: (context, ms) => CustomScrollView(slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _banner()),
              SliverToBoxAdapter(child: _topRooms(rooms)),
              SliverToBoxAdapter(child: _tabs()),
              SliverToBoxAdapter(child: _filters()),
              SliverPadding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 28), sliver: SliverList.builder(
                itemCount: _filtered(rooms).length,
                itemBuilder: (_, i) => _room(_filtered(rooms)[i], ms.data ?? const []),
              )),
            ]),
          );
        },
      ),
    ),
  );

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> rooms) {
    final q = search.text.trim().toLowerCase();
    return rooms.where((r) {
      final name = r['name'].toString().toLowerCase();
      final id = r['id'].toString().toLowerCase();
      final tags = (r['tags'] as List?)?.map((x) => x.toString()).toList() ?? const [];
      final matchesSearch = q.isEmpty || name.contains(q) || id.contains(q);
      final matchesFilter = filter == 'All' || (filter == 'Hot 🔥' ? ((r['hot_score'] ?? 0) as num) > 0 : tags.any((t) => t.toLowerCase().contains(filter.split(' ').first.toLowerCase())));
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _header() => Container(
    height: 205,
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2A160B), Color(0xFF090604)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Row(children: [const Icon(Icons.mic, color: AsmarTheme.gold, size: 28), const SizedBox(width: 7), const Text('ASMAR', style: TextStyle(color: AsmarTheme.gold, fontSize: 22, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.white))]),
      const Spacer(),
      Container(height: 44, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)), child: TextField(controller: search, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'ابحث عن الغرفة أو Room ID...', hintStyle: TextStyle(color: Colors.white60), prefixIcon: Icon(Icons.search, color: AsmarTheme.gold), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 11)))),
    ])),
  );

  Widget _banner() => Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(16), decoration: AsmarTheme.goldCard(radius: 18), child: const Row(children: [Icon(Icons.card_giftcard, color: AsmarTheme.gold, size: 34), SizedBox(width: 12), Expanded(child: Text('تعالوا احصلوا على الهدية المخصصة الخاصة بك!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)))]));

  Widget _topRooms(List<Map<String, dynamic>> rooms) => SizedBox(height: 126, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: rooms.take(3).length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) {
    final r = rooms[i];
    return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomScreen(roomName: r['name'].toString(), roomId: r['id'].toString()))), child: Container(width: 190, decoration: BoxDecoration(color: AsmarTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: [Colors.redAccent, Colors.deepPurpleAccent, AsmarTheme.gold][i], width: 2)), padding: const EdgeInsets.all(9), child: Row(children: [
      CircleAvatar(radius: 30, backgroundImage: (r['cover_url'] ?? '').toString().isNotEmpty ? NetworkImage(r['cover_url'].toString()) : null, child: (r['cover_url'] ?? '').toString().isEmpty ? const Icon(Icons.mic, color: AsmarTheme.gold) : null), const SizedBox(width: 8),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r['name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), Text('🔥 ${r['hot_score'] ?? 0}', style: const TextStyle(color: Colors.white60, fontSize: 10)), Text('Room:${r['id']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AsmarTheme.gold, fontSize: 9))]))
    ])));
  });

  Widget _tabs() => Padding(padding: const EdgeInsets.fromLTRB(12, 14, 12, 8), child: Row(children: ['شائع','جديد','فيديو','متألق'].asMap().entries.map((e) {
    final active = e.key == tab;
    return Expanded(child: GestureDetector(onTap: () => setState(() => tab = e.key), child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(color: active ? AsmarTheme.gold : AsmarTheme.surface, borderRadius: BorderRadius.circular(12)), child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.w800))));
  }).toList()));

  Widget _filters() => SizedBox(height: 52, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), scrollDirection: Axis.horizontal, itemCount: filters.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ChoiceChip(label: Text(filters[i]), selected: filter == filters[i], onSelected: (_) => setState(() => filter = filters[i]), selectedColor: AsmarTheme.gold, labelStyle: TextStyle(color: filter == filters[i] ? Colors.black : Colors.white70, fontWeight: FontWeight.bold), backgroundColor: AsmarTheme.surface, side: const BorderSide(color: Color(0xFF4B321A)))));

  Widget _room(Map<String, dynamic> r, List<Map<String, dynamic>> members) {
    final online = members.where((m) => m['room_id'] == r['id'] && m['left_at'] == null).length;
    final cover = (r['cover_url'] ?? '').toString();
    return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomScreen(roomName: r['name'].toString(), roomId: r['id'].toString()))), borderRadius: BorderRadius.circular(16), child: Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: const Color(0xFFE9E0D6), borderRadius: BorderRadius.circular(16)), child: Row(children: [
      CircleAvatar(radius: 32, backgroundImage: cover.isNotEmpty ? NetworkImage(cover) : null, child: cover.isEmpty ? const Icon(Icons.mic, color: Color(0xFF6A4030)) : null), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r['name'].toString(), style: const TextStyle(color: Color(0xFF24180F), fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(height: 5), Row(children: [Text('Room:${r['id']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF675C54), fontSize: 9)), const SizedBox(width: 8), const Icon(Icons.people_alt_outlined, color: Colors.green, size: 14), const SizedBox(width: 3), Text('$online', style: const TextStyle(color: Color(0xFF675C54), fontSize: 11)), if ((r['password_hash'] ?? '').toString().isNotEmpty) const Padding(padding: EdgeInsets.only(left: 7), child: Icon(Icons.lock_outline, size: 15, color: Color(0xFF6A4030)))])]))
    ])));
  }
}
