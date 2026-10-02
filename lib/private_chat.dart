import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'country_flag.dart';
import 'rank_frame.dart';
import 'profile_badges.dart';

class PrivateChatPage extends StatefulWidget {
  final String friendId;
  const PrivateChatPage({super.key, required this.friendId});
  @override State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final input = TextEditingController();
  final client = Supabase.instance.client;

  Future<Map<String, dynamic>> _profile() async {
    final row = await client.from('profiles').select('username,role,country_code,vip_level,avatar_url,activity_admin_badge,customer_service_badge,is_verified').eq('id', widget.friendId).maybeSingle();
    return Map<String, dynamic>.from(row ?? {});
  }

  String _time(dynamic value) {
    final dt = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _send() async {
    final message = input.text.trim();
    if (message.isEmpty) return;
    try {
      await client.rpc('send_private_message', params: {'p_receiver': widget.friendId, 'p_message': message});
      input.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الرسالة: $e')));
    }
  }

  @override
  void dispose() { input.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final uid = client.auth.currentUser?.id;
    return Scaffold(
      backgroundColor: const Color(0xFF090604),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100805),
        foregroundColor: Colors.white,
        elevation: 2,
        title: FutureBuilder<Map<String, dynamic>>(
          future: _profile(),
          builder: (context, snap) {
            final p = snap.data ?? {};
            final avatar = p['avatar_url']?.toString() ?? '';
            return Row(children: [
              RankFrame(role: p['role']?.toString() ?? 'USER', vipLevel: p['vip_level']?.toString(), size: 34, showLabel: false,
                child: CircleAvatar(backgroundColor: const Color(0xFF120A06), backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null, child: avatar.isEmpty ? const Icon(Icons.person, color: Color(0xFFFFD36A), size: 18) : null)),
              const SizedBox(width: 7),
              CountryFlag(code: p['country_code']?.toString(), size: 18),
              const SizedBox(width: 6),
              Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['username']?.toString() ?? 'مستخدم', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFD36A), fontWeight: FontWeight.w900)),
                ProfileBadges(activityAdmin: p['activity_admin_badge'] == true, customerService: p['customer_service_badge'] == true, verified: p['is_verified'] == true),
              ])),
            ]);
          },
        ),
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: client.from('private_messages').stream(primaryKey: ['id']).limit(200),
            builder: (context, snap) {
              final rows = (snap.data ?? []).where((x) =>
                (x['sender_id'] == uid && x['receiver_id'] == widget.friendId) ||
                (x['sender_id'] == widget.friendId && x['receiver_id'] == uid)
              ).toList()..sort((a,b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final x = rows[i];
                  final mine = x['sender_id'] == uid;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(top: 4, bottom: 4, left: mine ? 48 : 8, right: mine ? 8 : 48),
                      padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFF4A2C08) : const Color(0xFF1B0E08),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(mine ? 18 : 5), bottomRight: Radius.circular(mine ? 5 : 18),
                        ),
                        border: Border.all(color: mine ? const Color(0x66FFD36A) : const Color(0x334C3019)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Flexible(child: Text(x['message']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.25))),
                        const SizedBox(width: 7),
                        Text(_time(x['created_at']), style: const TextStyle(color: Colors.white38, fontSize: 9)),
                        if (mine) const Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.done_all, size: 14, color: Color(0xFFFFD36A))),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            child: Row(children: [
              Expanded(child: Container(
                decoration: BoxDecoration(color: const Color(0xFF1B0E08), borderRadius: BorderRadius.circular(25), border: Border.all(color: const Color(0x334C3019))),
                child: TextField(controller: input, minLines: 1, maxLines: 5, textInputAction: TextInputAction.newline, style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11), hintText: 'اكتب رسالة...', hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none)),
              )),
              const SizedBox(width: 7),
              CircleAvatar(radius: 22, backgroundColor: const Color(0xFFFFD36A), child: IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20))),
            ]),
          ),
        ),
      ]),
    );
  }
}
