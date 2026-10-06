import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class AsmarProfilePage extends StatefulWidget {
  const AsmarProfilePage({super.key});
  @override State<AsmarProfilePage> createState() => _AsmarProfilePageState();
}
class _AsmarProfilePageState extends State<AsmarProfilePage> {
  Map<String, dynamic>? profile; bool loading = true;
  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser; if (user == null) return;
    setState(() => loading = true);
    try {
      final row = await Supabase.instance.client.from('profiles').select('display_name,username,public_id,coins,svip_level,user_level,role,is_verified').eq('id', user.id).maybeSingle();
      if (mounted) setState(() => profile = row);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل الملف الشخصي: ' + e.toString()))); }
    finally { if (mounted) setState(() => loading = false); }
  }
  Future<void> _logout() => Supabase.instance.client.auth.signOut();
  @override void initState() { super.initState(); _load(); }
  @override Widget build(BuildContext context) {
    final p = profile ?? const <String, dynamic>{};
    final display = (p['display_name'] ?? p['username'] ?? 'A').toString();
    return Scaffold(
      appBar: AppBar(title: const Text('ملفي الشخصي'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          CircleAvatar(radius: 42, child: Text(display.characters.first.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12), Center(child: Text(display, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
          Center(child: Text('@' + (p['username'] ?? 'user').toString())), const SizedBox(height: 20),
          _info('ID', p['public_id'] ?? '—', Icons.badge_outlined), _info('Coins', p['coins'] ?? 0, Icons.monetization_on_outlined),
          _info('المستوى', p['user_level'] ?? 1, Icons.trending_up), _info('SVIP', p['svip_level'] ?? 0, Icons.workspace_premium_outlined),
          _info('الدور', p['role'] ?? 'USER', Icons.admin_panel_settings_outlined),
          if (p['is_verified'] == true) const ListTile(leading: Icon(Icons.verified), title: Text('الحساب موثق')),
          const SizedBox(height: 16), FilledButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج'))
        ]),
      ),
    );
  }
  Widget _info(String title, dynamic value, IconData icon) => Card(child: ListTile(leading: Icon(icon), title: Text(title), trailing: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold))));
}