import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'private_chat.dart';
import 'country_flag.dart';
import 'rank_frame.dart';
import 'profile_badges.dart';

class PrivateConversationsPage extends StatelessWidget {
  const PrivateConversationsPage({super.key});
  Future<Map<String, dynamic>> _profile(String id) async {
    final row = await Supabase.instance.client.from('profiles').select('username,role,country_code,vip_level,avatar_url,activity_admin_badge,customer_service_badge,is_verified').eq('id', id).maybeSingle();
    return Map<String, dynamic>.from(row ?? {});
  }
  @override Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return Scaffold(
      backgroundColor: const Color(0xFF090604),
      appBar: AppBar(backgroundColor: const Color(0xFF100805), foregroundColor: Colors.white, title: const Text('المحادثات 💬', style: TextStyle(color: Color(0xFFFFD36A), fontWeight: FontWeight.w900))),
      body: FutureBuilder<List<dynamic>>(
        future: client.rpc('private_conversations'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('خطأ: ' + snapshot.error.toString(), style: const TextStyle(color: Colors.white)));
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) return const Center(child: Text('لا توجد محادثات بعد', style: TextStyle(color: Colors.white54)));
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final x = Map<String, dynamic>.from(rows[i]);
              final friendId = x['friend_id'].toString();
              final unread = (x['unread_count'] as num?)?.toInt() ?? 0;
              return FutureBuilder<Map<String, dynamic>>(
                future: _profile(friendId),
                builder: (context, pSnap) {
                  final p = pSnap.data ?? {};
                  final avatar = p['avatar_url']?.toString() ?? '';
                  return ListTile(
                    leading: RankFrame(role: p['role']?.toString() ?? 'USER', vipLevel: p['vip_level']?.toString(), size: 42, showLabel: false, child: CircleAvatar(backgroundColor: const Color(0xFF120A06), backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null, child: avatar.isEmpty ? const Icon(Icons.person, color: Color(0xFFFFD36A), size: 22) : null)),
                    title: Row(children: [
                      CountryFlag(code: p['country_code']?.toString(), size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['username']?.toString() ?? friendId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ProfileBadges(activityAdmin: p['activity_admin_badge'] == true, customerService: p['customer_service_badge'] == true, verified: p['is_verified'] == true),
                      ])),
                      if ((p['vip_level']?.toString() ?? '').isNotEmpty) Text(p['vip_level'].toString(), style: const TextStyle(color: Color(0xFFFFD36A), fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                    subtitle: Text(x['last_message']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                    trailing: unread > 0 ? CircleAvatar(radius: 13, backgroundColor: const Color(0xFFFFC107), child: Text(unread > 99 ? '99+' : unread.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))) : null,
                    onTap: () async {
                      await client.rpc('mark_private_messages_read', params: {'p_friend': friendId});
                      if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatPage(friendId: friendId)));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}