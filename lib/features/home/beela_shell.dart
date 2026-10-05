import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../asmar/asmar_theme.dart';
import '../../room.dart';

class BeelaShell extends StatefulWidget {
  const BeelaShell({super.key});
  @override State<BeelaShell> createState() => _BeelaShellState();
}

class _BeelaShellState extends State<BeelaShell> {
  String filter = 'الكل';
  String query = '';
  bool loading = true;
  List<Map<String, dynamic>> rooms = [];
  final filters = const ['الكل', 'Hot 🔥', 'Jordan 🇯🇴', 'Turkey 🇹🇷', 'Syria 🇸🇾', 'Egypt 🇪🇬'];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    if (mounted) setState(() => loading = true);
    try {
      final db = Supabase.instance.client;
      final rows = await db
          .from('rooms')
          .select('id,name,owner_id,is_active,hot_score,cover_url,country_code,sort_order,seat_count')
          .eq('is_active', true)
          .order('sort_order', ascending: true, nullsFirst: false)
          .order('hot_score', ascending: false)
          .order('created_at', ascending: false);
      final loaded = List<Map<String, dynamic>>.from(rows);
      if (loaded.isNotEmpty) {
        final ids = loaded.map((r) => r['id'].toString()).toList();
        final seats = await db.from('room_seats').select('room_id,occupant_id').inFilter('room_id', ids);
        final counts = <String, int>{};
        for (final s in List<Map<String, dynamic>>.from(seats)) {
          if (s['occupant_id'] != null) counts[s['room_id'].toString()] = (counts[s['room_id'].toString()] ?? 0) + 1;
        }
        for (final r in loaded) r['people_count'] = counts[r['id'].toString()] ?? 0;
      }
      if (mounted) setState(() { rooms = loaded; loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل الغرف: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get visibleRooms {
    return rooms.where((r) {
      final name = r['name']?.toString().toLowerCase() ?? '';
      final country = r['country_code']?.toString().toUpperCase() ?? '';
      final q = query.trim().toLowerCase();
      if (q.isNotEmpty && !name.contains(q) && !r['id'].toString().toLowerCase().contains(q)) return false;
      switch (filter) {
        case 'Hot 🔥': return (r['hot_score'] as num? ?? 0) > 0;
        case 'Jordan 🇯🇴': return country == 'JO';
        case 'Turkey 🇹🇷': return country == 'TR';
        case 'Syria 🇸🇾': return country == 'SY';
        case 'Egypt 🇪🇬': return country == 'EG';
        default: return true;
      }
    }).toList();
  }

  Future<void> _createRoom() async {
    final name = TextEditingController();
    String country = 'JO';
    int seats = 15;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AsmarTheme.surface,
        title: const Text('إنشاء غرفة', style: TextStyle(color: AsmarTheme.gold, fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اسم الغرفة', prefixIcon: Icon(Icons.meeting_room))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: country, dropdownColor: AsmarTheme.surface, items: const [
            DropdownMenuItem(value: 'JO', child: Text('🇯🇴 الأردن')),
            DropdownMenuItem(value: 'TR', child: Text('🇹🇷 تركيا')),
            DropdownMenuItem(value: 'SY', child: Text('🇸🇾 سوريا')),
            DropdownMenuItem(value: 'EG', child: Text('🇪🇬 مصر')),
          ], onChanged: (v) { if (v != null) setDialogState(() => country = v); }, decoration: const InputDecoration(labelText: 'البلد')),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(value: seats, dropdownColor: AsmarTheme.surface, items: const [6,8,10,12,15,20].map((n) => DropdownMenuItem(value: n, child: Text('$n مقاعد'))).toList(), onChanged: (v) { if (v != null) setDialogState(() => seats = v); }, decoration: const InputDecoration(labelText: 'عدد المقاعد')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنشاء')),
        ],
      )),
    );
    if (created != true || name.text.trim().isEmpty) { name.dispose(); return; }
    try {
      await Supabase.instance.client.rpc('create_room', params: {'p_name': name.text.trim(), 'p_country_code': country, 'p_seat_count': seats});
      name.dispose();
      await _loadRooms();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الغرفة فعليًا')));
    } catch (e) {
      name.dispose();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إنشاء الغرفة: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: AsmarTheme.background,
      floatingActionButton: FloatingActionButton.extended(onPressed: _createRoom, backgroundColor: AsmarTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('إنشاء غرفة')),
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _filters()),
          if (loading) const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: AsmarTheme.gold)))
          else if (visibleRooms.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('لا توجد غرف ضمن هذا الفلتر', style: TextStyle(color: Colors.white54))))
          else SliverPadding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 100), sliver: SliverList.builder(itemCount: visibleRooms.length, itemBuilder: (_, i) => _room(visibleRooms[i]))),
        ]),
      ),
    ),
  );

  Widget _header() => Container(
    height: 255,
    decoration: const BoxDecoration(image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1539768942893-daf53e448371?auto=format&fit=crop&w=1200&q=85'), fit: BoxFit.cover)),
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0x33000000), Color(0xF0000000)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: SafeArea(bottom: false, child: Column(children: [
        Row(children: [const Icon(Icons.mic, color: AsmarTheme.gold, size: 28), const SizedBox(width: 7), const Text('ASMAR CHAT', style: TextStyle(color: AsmarTheme.gold, fontSize: 22, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: _loadRooms, icon: const Icon(Icons.refresh, color: Colors.white))]),
        const Spacer(),
        const Align(alignment: Alignment.centerRight, child: Text('غرف الصوت', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))),
        const SizedBox(height: 12),
        Container(height: 44, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)), child: TextField(onChanged: (v) => setState(() => query = v), textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'ابحث عن الغرفة أو Room ID...', hintStyle: TextStyle(color: Colors.white60), prefixIcon: Icon(Icons.search, color: AsmarTheme.gold), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 11)))),
      ])),
    ),
  );

  Widget _filters() => SizedBox(height: 58, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), scrollDirection: Axis.horizontal, itemCount: filters.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ChoiceChip(label: Text(filters[i]), selected: filter == filters[i], onSelected: (_) => setState(() => filter = filters[i]), selectedColor: AsmarTheme.gold, labelStyle: TextStyle(color: filter == filters[i] ? Colors.black : Colors.white70, fontWeight: FontWeight.bold), backgroundColor: AsmarTheme.surface, side: const BorderSide(color: Color(0xFF4B321A))));

  Widget _room(Map<String, dynamic> room) {
    final cover = room['cover_url']?.toString() ?? '';
    final people = (room['people_count'] as num? ?? 0).toInt();
    final pinned = room['sort_order'] as num?;
    final country = room['country_code']?.toString().toUpperCase() ?? '';
    final flag = {'JO':'🇯🇴','TR':'🇹🇷','SY':'🇸🇾','EG':'🇪🇬'}[country] ?? '🌐';
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Room(name: room['name'].toString(), roomId: room['id'].toString()))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(9), decoration: AsmarTheme.card(),
        child: Row(children: [
          CircleAvatar(radius: 31, backgroundColor: const Color(0xFF422511), backgroundImage: cover.isNotEmpty ? NetworkImage(cover) : null, child: cover.isEmpty ? const Icon(Icons.mic, color: AsmarTheme.gold) : null),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [if (pinned != null) const Icon(Icons.push_pin, color: AsmarTheme.gold, size: 15), if (pinned != null) const SizedBox(width: 4), Flexible(child: Text(room['name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)))]),
            const SizedBox(height: 5),
            Row(children: [Text('ID ${room['id'].toString().substring(0,8)}', style: const TextStyle(color: AsmarTheme.muted, fontSize: 10)), const SizedBox(width: 8), Text(flag, style: const TextStyle(fontSize: 15)), const SizedBox(width: 7), const Icon(Icons.people_alt_outlined, color: Colors.greenAccent, size: 14), const SizedBox(width: 3), Text('$people / ${room['seat_count'] ?? 15}', style: const TextStyle(color: AsmarTheme.muted, fontSize: 11))]),
          ])),
          const Icon(Icons.chevron_left, color: AsmarTheme.gold),
        ]),
      ),
    );
  }
}
