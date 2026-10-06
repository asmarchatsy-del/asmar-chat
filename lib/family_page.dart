
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFF070817);
const _panel = Color(0xFF11152D);
const _gold = Color(0xFFFFC94A);
const _muted = Color(0xFFA9B0D0);

class AsmarFamilyPage extends StatefulWidget {
  const AsmarFamilyPage({super.key});
  @override State<AsmarFamilyPage> createState() => _AsmarFamilyPageState();
}

class _AsmarFamilyPageState extends State<AsmarFamilyPage> {
  final db = Supabase.instance.client;
  bool loading = true;
  bool busy = false;
  List<Map<String, dynamic>> families = [];
  Map<String, dynamic>? mine;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final uid = db.auth.currentUser?.id;
      if (uid == null) throw StateError('يجب تسجيل الدخول');
      final rows = await db.from('families').select('id,name,owner_id,avatar_url,description,created_at').order('created_at', ascending: false);
      final member = await db.from('family_members').select('family_id,role').eq('user_id', uid).maybeSingle();
      Map<String, dynamic>? current;
      if (member != null) {
        final list = List<Map<String, dynamic>>.from(rows);
        final found = list.where((x) => x['id'].toString() == member['family_id'].toString()).toList();
        if (found.isNotEmpty) current = {...found.first, 'my_role': member['role']};
      }
      List<Map<String, dynamic>> currentMembers = [];
      if (current != null) {
        final m = await db.from('family_members').select('user_id,role,joined_at,profiles(username,display_name,avatar_url,is_verified)').eq('family_id', current['id']).order('joined_at');
        currentMembers = List<Map<String, dynamic>>.from(m);
      }
      if (!mounted) return;
      setState(() {
        families = List<Map<String, dynamic>>.from(rows);
        mine = current;
        members = currentMembers;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل العائلات: ' + e.toString())));
      }
    }
  }

  Future<void> _createFamily() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    try {
      final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        title: const Text('إنشاء عائلة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم العائلة')),
          const SizedBox(height: 10),
          TextField(controller: desc, maxLines: 2, decoration: const InputDecoration(labelText: 'الوصف')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('إنشاء')),
        ],
      ));
      if (ok != true || name.text.trim().isEmpty) return;
      setState(() => busy = true);
      await db.rpc('asmar_create_family', params: {
        'p_name': name.text.trim(),
        'p_description': desc.text.trim(),
      });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء العائلة: ' + e.toString())));
    } finally {
      name.dispose(); desc.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _join(String familyId) async {
    if (busy || mine != null) return;
    setState(() => busy = true);
    try {
      await db.rpc('asmar_join_family', params: {'p_family_id': familyId});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الانضمام: ' + e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _leave() async {
    if (mine == null || busy) return;
    if (mine!['my_role']?.toString() == 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مالك العائلة يجب أن ينقل الملكية قبل المغادرة.')));
      return;
    }
    setState(() => busy = true);
    try {
      await db.rpc('asmar_leave_family');
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر مغادرة العائلة: ' + e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('العائلة', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
          children: [
            if (mine != null) _mineCard() else _createCard(),
            const SizedBox(height: 14),
            const Text('العائلات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (families.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('لا توجد عائلات بعد', style: TextStyle(color: _muted))))
            else ...families.map(_familyCard),
          ],
        ),
      ),
    ),
  );

  Widget _createCard() => InkWell(
    onTap: busy ? null : _createFamily,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [_gold, Color(0xFFFF9418)])),
      child: const Row(children: [
        Icon(Icons.groups_rounded, color: Color(0xFF4A2100), size: 34),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('أنشئ عائلتك', style: TextStyle(color: Color(0xFF4A2100), fontSize: 19, fontWeight: FontWeight.w900)),
          Text('إنشاء عائلة حقيقية من قاعدة البيانات', style: TextStyle(color: Color(0xFF633000), fontSize: 11)),
        ])),
        Icon(Icons.add_circle_outline, color: Color(0xFF4A2100)),
      ]),
    ),
  );

  Widget _mineCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold.withOpacity(.45))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.verified_rounded, color: _gold),
        const SizedBox(width: 8),
        Expanded(child: Text(mine!['name'].toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        OutlinedButton(onPressed: busy ? null : _leave, child: const Text('مغادرة')),
      ]),
      const SizedBox(height: 5),
      Text(mine!['description']?.toString() ?? '', style: const TextStyle(color: _muted, fontSize: 11)),
      const SizedBox(height: 10),
      Text('الدور: ' + (mine!['my_role']?.toString() ?? 'member'), style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text('الأعضاء: ' + members.length.toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      ...members.take(20).map((m) {
        final p = m['profiles'] is Map ? Map<String, dynamic>.from(m['profiles']) : <String, dynamic>{};
        final avatar = p['avatar_url']?.toString() ?? '';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null, child: avatar.isEmpty ? const Icon(Icons.person) : null),
          title: Text(p['display_name']?.toString() ?? p['username']?.toString() ?? m['user_id'].toString()),
          subtitle: Text(m['role']?.toString() ?? 'member', style: const TextStyle(color: _muted)),
        );
      }),
    ]),
  );

  Widget _familyCard(Map<String, dynamic> f) {
    final isMine = mine?['id']?.toString() == f['id']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(17)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFF2D235A), child: const Icon(Icons.groups, color: _gold)),
        title: Text(f['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(f['description']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted)),
        trailing: isMine ? const Icon(Icons.check_circle, color: _gold) : (mine == null ? FilledButton(onPressed: busy ? null : () => _join(f['id'].toString()), child: const Text('انضمام')) : null),
      ),
    );
  }
}
