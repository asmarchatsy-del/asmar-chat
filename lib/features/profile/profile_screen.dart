import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../asmar/asmar_theme.dart';
import '../admin/admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const menu = [
    ('خلفية الغرفة', Icons.wallpaper), ('معرض السيارة', Icons.directions_car), ('المتجر', Icons.storefront),
    ('اكسسواراتي', Icons.auto_awesome), ('العائلة', Icons.groups), ('المستوى', Icons.trending_up), ('الإعدادات', Icons.settings),
  ];
  bool admin = false, checking = true;
  @override void initState() { super.initState(); _checkAdmin(); }
  Future<void> _checkAdmin() async {
    try {
      final c = Supabase.instance.client; final u = c.auth.currentUser;
      if (u?.email?.toLowerCase() == 'admin@asmar.com') {
        final r = await c.from('admin_roles').select('enabled,role').eq('user_id', u!.id).maybeSingle();
        admin = r?['enabled'] == true && const ['CEO','SUPER_ADMIN','ADMIN'].contains('${r?['role']}'.toUpperCase());
      }
    } catch (_) {}
    if (mounted) setState(() => checking = false);
  }
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('ملفي', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(padding: const EdgeInsets.all(16), decoration: AsmarTheme.goldCard(radius: 22), child: Column(children: [
          const CircleAvatar(radius: 44, backgroundImage: NetworkImage('https://i.pravatar.cc/180?img=12')),
          const SizedBox(height: 10), const Text('M1', style: TextStyle(color: AsmarTheme.gold, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4), const Text('ID 83429949', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14), const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_Stat('17','متابع'), _Stat('6','متابَعون'), _Stat('9','زوار'), _Stat('10','مستوى')]),
          const SizedBox(height: 15), Row(children: [
            Expanded(child: FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: AsmarTheme.gold, foregroundColor: Colors.black), child: const Text('SVIP', style: TextStyle(fontWeight: FontWeight.w900)))),
            const SizedBox(width: 10), Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AsmarTheme.gold, side: const BorderSide(color: AsmarTheme.goldDark)), child: const Text('Rasid', style: TextStyle(fontWeight: FontWeight.w900)))),
          ]),
        ])),
        const SizedBox(height: 14),
        if (!checking && admin) Card(color: AsmarTheme.surface, margin: const EdgeInsets.only(bottom: 7), child: ListTile(
          leading: const Icon(Icons.admin_panel_settings, color: AsmarTheme.gold), title: const Text('لوحة تحكم الأدمن', style: TextStyle(fontWeight: FontWeight.w900)),
          subtitle: const Text('إدارة المستخدمين والغرف والهدايا والمتجر والإعدادات'), trailing: const Icon(Icons.chevron_left, color: AsmarTheme.muted),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
        )),
        ...menu.map((item) => Card(color: AsmarTheme.surface, margin: const EdgeInsets.only(bottom: 7), child: ListTile(
          leading: Icon(item.$2, color: AsmarTheme.gold), title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.chevron_left, color: AsmarTheme.muted), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(item.$1))),
        ))),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  final String value, label; const _Stat(this.value, this.label);
  @override Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: AsmarTheme.muted, fontSize: 10))]);
}
