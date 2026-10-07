
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsmarRankingPage extends StatefulWidget {
  final String type;
  const AsmarRankingPage({super.key, required this.type});
  @override State<AsmarRankingPage> createState() => _AsmarRankingPageState();
}

class _AsmarRankingPageState extends State<AsmarRankingPage> {
  bool loading = true;
  List<Map<String, dynamic>> rows = [];
  final db = Supabase.instance.client;

  String get title => switch (widget.type) {
    'cp' => 'ترتيب CP',
    'family' => 'ترتيب العائلات',
    _ => 'ترتيب الثروة',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      if (widget.type == 'family') {
        final members = List<Map<String, dynamic>>.from(await db.from('family_members').select('family_id'));
        final counts = <String, int>{};
        for (final m in members) {
          final id = m['family_id'].toString();
          counts[id] = (counts[id] ?? 0) + 1;
        }
        final ids = counts.keys.toList();
        if (ids.isNotEmpty) {
          final fs = List<Map<String, dynamic>>.from(await db.from('families').select('id,name,owner_id,avatar_url,description').inFilter('id', ids));
          rows = fs.map((f) => {...f, 'score': counts[f['id'].toString()] ?? 0}).toList()..sort((a,b) => (b['score'] as int).compareTo(a['score'] as int));
        } else {
          rows = [];
        }
      } else {
        final field = widget.type == 'cp' ? 'support_points' : 'coins';
        final data = await db.from('profiles').select('id,display_name,username,public_id,avatar_url,is_verified,$field').order(field, ascending: false).limit(100);
        rows = List<Map<String, dynamic>>.from(data);
      }
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل الترتيب: ' + e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = rows[i];
            final avatar = r['avatar_url']?.toString() ?? '';
            final score = r['score'] ?? (r[widget.type == 'cp' ? 'support_points' : 'coins'] ?? 0);
            return Container(
              decoration: BoxDecoration(color: const Color(0xFF1A100B), borderRadius: BorderRadius.circular(17), border: Border.all(color: i < 3 ? const Color(0xFFFFD36A) : const Color(0xFF3A2412))),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty ? Text((i + 1).toString(), style: const TextStyle(fontWeight: FontWeight.w900)) : null,
                ),
                title: Text(r['name']?.toString() ?? r['display_name']?.toString() ?? r['username']?.toString() ?? 'Asmar', style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(r['public_id']?.toString() ?? 'المركز ' + (i + 1).toString(), style: const TextStyle(color: Color(0xFFB9A995))),
                trailing: Text(score.toString() + (widget.type == 'family' ? ' عضو' : ' 🪙'), style: const TextStyle(color: Color(0xFFFFD36A), fontWeight: FontWeight.w900)),
              ),
            );
          },
        ),
      ),
    ),
  );
}
