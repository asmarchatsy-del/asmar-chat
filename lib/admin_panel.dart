import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'super_admin_panel.dart';
import 'admin_web_config.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});
  @override State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final db = Supabase.instance.client;
  bool loading = true;
  bool authorized = false;
  Map<String,int> stats = {};

  Future<void> _openExternalAdmin() async {
    final uri = Uri.tryParse(asmarAdminWebUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح لوحة الإدارة الخارجية')));
    }
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final can = await db.rpc('admin_can_manage_dashboard') as bool? ?? false;
      if (!can) {
        if (mounted) setState(() { authorized = false; loading = false; });
        return;
      }
      final results = await Future.wait([
        db.from('profiles').select('id').count(CountOption.exact),
        db.from('rooms').select('id').eq('is_active', true).count(CountOption.exact),
        db.from('wallets').select('user_id').count(CountOption.exact),
      ]);
      if (!mounted) return;
      setState(() {
        authorized = true;
        loading = false;
        stats = {
          'users': results[0].count,
          'rooms': results[1].count,
          'wallets': results[2].count,
        };
      });
    } catch (_) {
      if (mounted) setState(() { authorized = false; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF070817),
        appBar: AppBar(
          title: const Text('لوحة تحكم Asmar'),
          backgroundColor: const Color(0xFF100805),
          foregroundColor: const Color(0xFFFFD36A),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : !authorized
                ? const Center(child: Text('ليس لديك صلاحية للوصول إلى لوحة التحكم', style: TextStyle(color: Colors.white70)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('مركز إدارة Asmar', style: TextStyle(color: Color(0xFFFFD36A), fontSize: 25, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text('بيانات حقيقية من قاعدة البيانات', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 14),
                        Card(color: const Color(0xFF201307), child: ListTile(leading: const Icon(Icons.open_in_new, color: Color(0xFFFFD36A)), title: const Text('لوحة الإدارة عبر الويب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), subtitle: const Text('فتح لوحة CEO في المتصفح — نفس صلاحيات Supabase الآمنة', style: TextStyle(color: Colors.white54)), trailing: const Icon(Icons.chevron_left, color: Color(0xFFFFD36A)), onTap: _openExternalAdmin)),
                        const SizedBox(height: 18),
                        Row(children: [
                          Expanded(child: _stat('المستخدمون', stats['users'] ?? 0, Icons.people)),
                          const SizedBox(width: 10),
                          Expanded(child: _stat('الغرف النشطة', stats['rooms'] ?? 0, Icons.mic)),
                          const SizedBox(width: 10),
                          Expanded(child: _stat('المحافظ', stats['wallets'] ?? 0, Icons.account_balance_wallet)),
                        ]),
                        const SizedBox(height: 18),
                        Card(
                          color: const Color(0xFF1B0E08),
                          child: ListTile(
                            leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFFFD36A)),
                            title: const Text('الإدارة المتقدمة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            subtitle: const Text('المستخدمون، الغرف، الكوينز، الوكالات، الهدايا، الشارات، SVIP والشحن والسحب', style: TextStyle(color: Colors.white54)),
                            trailing: const Icon(Icons.chevron_left, color: Color(0xFFFFD36A)),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminPanel())),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF1B0E08), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4C3019))),
    child: Column(children: [
      Icon(icon, color: const Color(0xFFFFD36A)),
      const SizedBox(height: 6),
      Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ]),
  );
}
