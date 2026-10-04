import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_gate.dart';
import 'aristocracy_page.dart';
import 'rank_frame.dart';
import 'store.dart';
import 'wallet.dart';

const _gold = Color(0xFFFFD36A);
const _goldDark = Color(0xFFB77921);
const _bg = Color(0xFF120A06);
const _card = Color(0xFF211108);

class MePage extends StatefulWidget {
  const MePage({super.key});
  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late Future<Map<String, dynamic>> _future;
  final _db = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw Exception('لا توجد جلسة دخول');
    final row = await _db.from('profiles').select('id,username,display_name,bio,avatar_url,public_id,vip_level,svip_level,user_level,coins,diamonds,golden_frame,special_frame,aristocracy_level,aristocracy_expires_at').eq('id', id).maybeSingle();
    if (row == null) throw Exception('لم يتم العثور على الملف الشخصي');
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, int>> _stats(String id) async {
    final visitors = await _db.from('visitors').select('visitor_id').eq('profile_id', id);
    final following = await _db.from('follows').select('following_id').eq('follower_id', id);
    final followers = await _db.from('follows').select('follower_id').eq('following_id', id);
    return {'visitors': visitors.length, 'following': following.length, 'followers': followers.length};
  }

  Future<void> _copyId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الـID')));
  }

  Widget _stat(String title, int value, IconData icon) {
    return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)), child: Column(children: [Icon(icon, color: _gold), const SizedBox(height: 5), Text('$value', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)), Text(title, style: const TextStyle(fontSize: 10, color: Colors.white60))])));
  }

  Widget _quick(String title, IconData icon, VoidCallback tap) {
    return Expanded(child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(14), child: Container(height: 74, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _goldDark)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: _gold, size: 25), const SizedBox(height: 5), Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70))])));
  }

  Widget _menu(String title, IconData icon, VoidCallback tap) {
    return ListTile(onTap: tap, leading: Icon(icon, color: _gold), title: Text(title), trailing: const Icon(Icons.chevron_left, color: Colors.white38));
  }

  Widget _aristocracyCard(int level, String expires) {
    return Card(color: _card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: _goldDark)), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AristocracyPage())), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [const CircleAvatar(radius: 25, backgroundColor: Color(0xFF3A210A), child: Icon(Icons.workspace_premium, color: _gold, size: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('أرستقراطية', style: TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.w900)), Text(level > 0 ? 'المستوى $level • $expires' : 'اختر مستوى الأرستقراطية', style: const TextStyle(color: Colors.white60, fontSize: 12))])), const Icon(Icons.chevron_left, color: _gold)]))));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: _bg, appBar: AppBar(backgroundColor: _bg, title: const Text('أنا', style: TextStyle(fontWeight: FontWeight.w900))), body: FutureBuilder<Map<String, dynamic>>(future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: _gold));
      if (snapshot.hasError || snapshot.data == null) return Center(child: Text('تعذر تحميل الملف: ${snapshot.error ?? ''}'));
      final p = snapshot.data!;
      final uid = p['id'].toString();
      final publicId = p['public_id']?.toString() ?? '---';
      final name = p['display_name']?.toString().isNotEmpty == true ? p['display_name'].toString() : p['username']?.toString() ?? 'مستخدم';
      final avatar = p['avatar_url']?.toString() ?? '';
      final vip = p['vip_level']?.toString() ?? '';
      final level = (p['user_level'] as num?)?.toInt() ?? 1;
      final aristocracy = (p['aristocracy_level'] as num?)?.toInt() ?? 0;
      final expires = p['aristocracy_expires_at']?.toString() ?? '';
      return RefreshIndicator(color: _gold, onRefresh: () async { setState(() => _future = _loadProfile()); await _future; }, child: ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 28), children: [
        InkWell(borderRadius: BorderRadius.circular(24), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3A1C08), Color(0xFF160B06)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: _goldDark)), child: Row(children: [SecretAdminAvatarTrigger(publicId: publicId, child: RankFrame(role: 'USER', vipLevel: vip.isEmpty ? null : vip, size: 96, child: CircleAvatar(radius: 34, backgroundColor: const Color(0xFF100804), backgroundImage: avatar.isEmpty ? null : NetworkImage(avatar), child: avatar.isEmpty ? const Icon(Icons.person, color: _gold, size: 34) : null))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Row(children: [Text('ID: $publicId', style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)), IconButton(onPressed: () => _copyId(publicId), icon: const Icon(Icons.copy, size: 18, color: _gold))]), Text(p['bio']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12))]))])),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, int>>(future: _stats(uid), builder: (context, s) { final st = s.data ?? const {'visitors': 0, 'following': 0, 'followers': 0}; return Row(children: [_stat('الزوار', st['visitors']!, Icons.visibility_outlined), _stat('المتابَعون', st['following']!, Icons.person_add_alt_1_outlined), _stat('المتابعون', st['followers']!, Icons.people_outline)]); }),
        const SizedBox(height: 12),
        _aristocracyCard(aristocracy, expires),
        const SizedBox(height: 12),
        Row(children: [_quick('المحفظة', Icons.account_balance_wallet_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage()))), _quick('المتجر', Icons.storefront_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorePage())))]),
        const SizedBox(height: 12),
        Card(color: _card, child: Column(children: [_menu('المحفظة', Icons.account_balance_wallet_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage()))), _menu('المتجر', Icons.storefront_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorePage())))])),
        const SizedBox(height: 12),
        Text('مستوى المستخدم $level', style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        FutureBuilder<Map<String, dynamic>?>(future: _db.from('user_exp').select().eq('user_id', uid).maybeSingle(), builder: (_, e) { final exp = (e.data?['user_exp'] as num?)?.toInt() ?? 0; return LinearProgressIndicator(value: (exp % 1000) / 1000, color: _gold, backgroundColor: Colors.white12); }),
      ]));
    }));
  }
}
