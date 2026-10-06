import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsmarBadgesPage extends StatefulWidget {
  const AsmarBadgesPage({super.key});
  @override
  State<AsmarBadgesPage> createState() => _AsmarBadgesPageState();
}

class _AsmarBadgesPageState extends State<AsmarBadgesPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await Supabase.instance.client
        .from('user_badges')
        .select('granted_at,is_equipped,badges(id,name,code,icon_key,description,role,is_official)')
        .eq('user_id', uid)
        .order('granted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  IconData _icon(String key) => switch (key) {
        'crown' => Icons.workspace_premium_rounded,
        'verified_user' => Icons.verified_user_rounded,
        'manage_accounts' => Icons.manage_accounts_rounded,
        'campaign' => Icons.campaign_rounded,
        'handshake' => Icons.handshake_rounded,
        'mic' => Icons.mic_rounded,
        'paid' => Icons.paid_rounded,
        _ => Icons.military_tech_rounded,
      };

  Future<void> _equip(String badgeId) async {
    try {
      await Supabase.instance.client.rpc('asmar_equip_badge', params: {'p_badge_id': badgeId});
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تفعيل الشارة بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تفعيل الشارة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('معرض الشارات', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('تعذر تحميل الشارات: ${snapshot.error}'));
            }
            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) {
              return const Center(child: Text('لا توجد شارات ممنوحة لهذا الحساب بعد.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .82,
              ),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final row = rows[i];
                final b = row['badges'] is Map
                    ? Map<String, dynamic>.from(row['badges'])
                    : <String, dynamic>{};
                final equipped = row['is_equipped'] == true;
                final official = b['is_official'] == true;
                final role = b['role']?.toString() ?? '';
                return InkWell(
                  onTap: () {
                    final id = b['id']?.toString();
                    if (id != null && id.isNotEmpty && !equipped) _equip(id);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11152D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: equipped
                            ? const Color(0xFFFFC94A)
                            : const Color(0xFF2B315A),
                        width: equipped ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFF252B50),
                          child: Icon(_icon(b['icon_key']?.toString() ?? ''), size: 38, color: const Color(0xFFFFC94A)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          b['name']?.toString() ?? 'شارة',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b['description']?.toString() ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFA9B0D0), fontSize: 10),
                        ),
                        if (official)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('رسمية من Asmar', style: TextStyle(color: Color(0xFFFFC94A), fontWeight: FontWeight.w800, fontSize: 10)),
                          ),
                        if (role.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(role, style: const TextStyle(color: Color(0xFFA9B0D0), fontSize: 9)),
                          ),
                        if (equipped)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('مفعّلة', style: TextStyle(color: Color(0xFFFFC94A), fontWeight: FontWeight.w800)),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('اضغط للتفعيل', style: TextStyle(color: Color(0xFFA9B0D0), fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
