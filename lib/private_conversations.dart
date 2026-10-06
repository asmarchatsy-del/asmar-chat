import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'private_chat.dart';
import 'country_flag.dart';
import 'rank_frame.dart';

class PrivateConversationsPage extends StatefulWidget {
  const PrivateConversationsPage({super.key});
  @override State<PrivateConversationsPage> createState() => _PrivateConversationsPageState();
}

class _PrivateConversationsPageState extends State<PrivateConversationsPage> {
  final client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadConversations();
  }

  Future<List<Map<String, dynamic>>> _loadConversations() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = List<Map<String, dynamic>>.from(
      await client.from('messages')
          .select('id,sender_id,receiver_id,body,message_type,created_at,read_at')
          .or('sender_id.eq.$uid,receiver_id.eq.$uid')
          .order('created_at', ascending: false)
          .limit(500),
    );
    final byFriend = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final friendId = row['sender_id'] == uid ? row['receiver_id'].toString() : row['sender_id'].toString();
      final existing = byFriend[friendId];
      final unread = row['receiver_id'] == uid && row['read_at'] == null;
      if (existing == null) {
        byFriend[friendId] = {
          'friend_id': friendId,
          'last_message': row['body']?.toString() ?? '',
          'created_at': row['created_at'],
          'unread_count': unread ? 1 : 0,
        };
      } else if (unread) {
        existing['unread_count'] = (existing['unread_count'] as int) + 1;
      }
    }
    return byFriend.values.toList();
  }

  Future<Map<String, dynamic>> _profile(String id) async {
    final row = await client.from('profiles')
        .select('username,display_name,role,country_code,vip_level,avatar_url,activity_admin_badge,customer_service_badge,is_verified')
        .eq('id', id).maybeSingle();
    return Map<String, dynamic>.from(row ?? {});
  }

  Future<void> _open(String friendId) async {
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      await client.from('messages').update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('receiver_id', uid).eq('sender_id', friendId).isFilter('read_at', null);
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatPage(friendId: friendId)));
    if (mounted) setState(() => _future = _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090604),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100805),
        foregroundColor: Colors.white,
        title: const Text('المحادثات 💬', style: TextStyle(color: Color(0xFFFFD36A), fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: () => setState(() => _future = _loadConversations()), icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المحادثات: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) return const Center(child: Text('لا توجد محادثات بعد', style: TextStyle(color: Colors.white54)));
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x223C2815)),
            itemBuilder: (context, i) {
              final x = rows[i];
              final friendId = x['friend_id'].toString();
              final unread = (x['unread_count'] as int?) ?? 0;
              return FutureBuilder<Map<String, dynamic>>(
                future: _profile(friendId),
                builder: (context, pSnap) {
                  final p = pSnap.data ?? {};
                  final avatar = p['avatar_url']?.toString() ?? '';
                  final display = p['display_name']?.toString().trim();
                  final username = (display?.isNotEmpty == true ? display : p['username']?.toString()) ?? friendId;
                  return ListTile(
                    tileColor: const Color(0xFF0E0704),
                    leading: RankFrame(
                      role: p['role']?.toString() ?? 'USER',
                      vipLevel: p['vip_level']?.toString(),
                      size: 42,
                      showLabel: false,
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF120A06),
                        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                        child: avatar.isEmpty ? const Icon(Icons.person, color: Color(0xFFFFD36A), size: 22) : null,
                      ),
                    ),
                    title: Row(children: [
                      CountryFlag(code: p['country_code']?.toString(), size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                      if (p['is_verified'] == true) const Icon(Icons.verified, color: Color(0xFFFFD36A), size: 16),
                    ]),
                    subtitle: Text(x['last_message']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                    trailing: unread > 0
                        ? CircleAvatar(radius: 13, backgroundColor: const Color(0xFFFFC107), child: Text(unread > 99 ? '99+' : unread.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))
                        : null,
                    onTap: () => _open(friendId),
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
