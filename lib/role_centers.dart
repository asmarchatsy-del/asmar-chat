import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_panel.dart';

const _gold = Color(0xFFFFD36A);
const _gold2 = Color(0xFFB77921);
const _bg = Color(0xFF090604);
const _card = Color(0xFF1B0E08);

class RoleCenterPage extends StatefulWidget {
  final String role;
  const RoleCenterPage({super.key, required this.role});

  @override
  State<RoleCenterPage> createState() => _RoleCenterPageState();
}

class _RoleCenterPageState extends State<RoleCenterPage> {
  String get role => widget.role.toUpperCase();

  String get title {
    switch (role) {
      case 'CEO': return 'لوحة Chat الرئيسية';
      case 'SUPER_ADMIN': return 'مركز Super Admin';
      case 'MANAGER': return 'مركز Manager';
      case 'BD': return 'مركز BD';
      case 'ADMIN': return 'مركز Admin';
      case 'AGENT': return 'مركز الوكيل';
      case 'HOST': return 'مركز المضيف';
      default: return 'المركز';
    }
  }

  List<String> get permissions {
    switch (role) {
      case 'SUPER_ADMIN': return ['المستخدمون', 'الغرف', 'المضيفون', 'الوكالات', 'VIP 1 → VIP 6'];
      case 'MANAGER': return ['المضيفون', 'الوكالات', 'BD', 'Admin'];
      case 'BD': return ['الوكالات', 'متابعة الوكالات'];
      case 'ADMIN': return ['المستخدمون', 'الغرف', 'المضيفون'];
      case 'AGENT': return ['وكالتي', 'المضيفون', 'الإحصائيات'];
      case 'HOST': return ['أرباحي', 'ساعات البث', 'المهام', 'المستوى'];
      default: return [];
    }
  }

  Future<void> _action(String name) async {
    final client = Supabase.instance.client;
    try {
      if (name == 'VIP 1 → VIP 6' && role == 'SUPER_ADMIN') {
        final target = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final id = TextEditingController();
            final vip = TextEditingController(text: 'VIP6');
            return AlertDialog(
              title: const Text('منح VIP'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: id, decoration: const InputDecoration(labelText: 'ID المستخدم (UUID)')),
                TextField(controller: vip, decoration: const InputDecoration(labelText: 'VIP 1 إلى VIP 6')),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                FilledButton(onPressed: () => Navigator.pop(ctx, id.text.trim() + '|' + vip.text.trim()), child: const Text('منح')),
              ],
            );
          },
        );
        if (target == null) return;
        final parts = target.split('|');
        if (parts.length != 2) throw Exception('بيانات غير صحيحة');
        await client.rpc('admin_grant_vip', params: {
          'p_user_id': parts[0],
          'p_vip_level': parts[1].toUpperCase(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم منح VIP بنجاح')));
        return;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name — صلاحية $role جاهزة للربط بالعملية الخاصة بها.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تنفيذ العملية: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (role == 'CEO') return const AdminPanel();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF100805),
          foregroundColor: Colors.white,
          title: Text(title, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6B2C0B), Color(0xFF160A06)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _gold2),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF422511),
                    child: Icon(Icons.shield, color: _gold, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(color: _gold, fontSize: 21, fontWeight: FontWeight.w900))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (role == 'SUPER_ADMIN')
              _infoCard('صلاحية VIP', 'يمكن منح VIP من 1 إلى 6 فقط. لا يمكن تجاوز هذا الحد.'),
            if (role == 'MANAGER')
              _infoCard('التفويض', 'يمكن إدارة BD وAdmin والوكالات حسب الصلاحيات الممنوحة. لا توجد صلاحية VIP.'),
            if (role == 'BD')
              _infoCard('BD', 'إدارة ومتابعة الوكالات ضمن نطاقك. لا توجد صلاحية VIP.'),
            if (role == 'ADMIN')
              _infoCard('Admin', 'إدارة الأدوات المسموحة لك فقط. لا توجد صلاحية VIP.'),
            if (role == 'AGENT')
              _infoCard('الوكيل', 'إدارة وكالتك ومضيفيك. لا توجد صلاحية منح VIP.'),
            if (role == 'HOST')
              _infoCard('المضيف', 'مركزك الشخصي للأرباح والبث والمهام والمستوى.'),
            const SizedBox(height: 10),
            ...permissions.map((p) => Card(
              color: _card,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: _gold),
                title: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_left, color: Colors.white38),
                onTap: () => _action(p),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(text, style: const TextStyle(color: Colors.white70, height: 1.45)),
        ],
      ),
    );
  }
}
