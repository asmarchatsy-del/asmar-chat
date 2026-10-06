
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsmarBlockedUsersPage extends StatefulWidget {
  const AsmarBlockedUsersPage({super.key});
  @override State<AsmarBlockedUsersPage> createState() => _AsmarBlockedUsersPageState();
}

class _AsmarBlockedUsersPageState extends State<AsmarBlockedUsersPage> {
  final db = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await db.from('blacklist').select('blocked_user_id,created_at').order('created_at', ascending: false);
      final ids = List<Map<String, dynamic>>.from(r);
      final profiles = ids.isEmpty ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(await db.from('profiles').select('id,display_name,username,avatar_url').inFilter('id', ids.map((x) => x['blocked_user_id']).toList()));
      final byId = {for (final p in profiles) p['id'].toString(): p};
      if (!mounted) return;
      setState(() {
        rows = ids.map((x) => {...x, 'profile': byId[x['blocked_user_id'].toString()]}).toList();
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل قائمة الحظر: ' + e.toString())));
      }
    }
  }

  Future<void> _unblock(String id) async {
    try {
      await db.from('blacklist').delete().eq('blocked_user_id', id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إلغاء الحظر: ' + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المستخدمون المحظورون')),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: rows.isEmpty
          ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا يوجد مستخدمون محظورون'))])
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = rows[i]['profile'] is Map ? Map<String, dynamic>.from(rows[i]['profile']) : <String, dynamic>{};
                final avatar = p['avatar_url']?.toString() ?? '';
                final id = rows[i]['blocked_user_id'].toString();
                return ListTile(
                  tileColor: const Color(0xFF11152D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: CircleAvatar(backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null, child: avatar.isEmpty ? const Icon(Icons.person) : null),
                  title: Text(p['display_name']?.toString() ?? p['username']?.toString() ?? id),
                  subtitle: Text(id, style: const TextStyle(color: Color(0xFFA9B0D0))),
                  trailing: OutlinedButton(onPressed: () => _unblock(id), child: const Text('إلغاء الحظر')),
                );
              },
            ),
      ),
    ),
  );
}
