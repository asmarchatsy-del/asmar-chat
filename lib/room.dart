import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'country_flag.dart';
import 'rank_frame.dart';
import 'gifts.dart';
import 'profile_badges.dart';

const gold = Color(0xFFFFD36A);
const gold2 = Color(0xFFB77921);
const bg = Color(0xFF090604);
const card = Color(0xFF1B0E08);

class Room extends StatefulWidget {
  final String name;
  final String roomId;
  const Room({super.key, required this.name, required this.roomId});
  @override State<Room> createState() => _RoomState();
}

class _RoomState extends State<Room> {
  final controller = TextEditingController();
  final messages = <Map<String, dynamic>>[];
  final profiles = <String, Map<String, dynamic>>{};
  StreamSubscription<List<Map<String, dynamic>>>? messageSub;
  StreamSubscription<List<Map<String, dynamic>>>? giftSub;
  final seenGifts = <String>{};
  lk.Room? voiceRoom;
  bool microphoneOn = false;
  bool joiningVoice = false;
  Map<String, dynamic>? giftOverlay;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    messageSub = Supabase.instance.client
        .from('room_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at')
        .listen((rows) {
          if (!mounted) return;
          setState(() {
            messages
              ..clear()
              ..addAll(rows.length > 100 ? rows.sublist(rows.length - 100) : rows);
          });
        });
    giftSub = Supabase.instance.client
        .from('gift_transactions')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at')
        .listen(_handleGifts);
  }

  Future<void> _loadMessages() async {
    try {
      final rows = await Supabase.instance.client
          .from('room_messages')
          .select('id,user_id,message,created_at')
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: false)
          .limit(100);
      final list = List<Map<String, dynamic>>.from(rows).reversed.toList();
      final ids = list.map((m) => m['user_id'].toString()).toSet().toList();
      if (ids.isNotEmpty) {
        final ps = await Supabase.instance.client
            .from('profiles')
            .select('id,username,role,country_code,vip_level,avatar_url,avatar_is_animated,activity_admin_badge,customer_service_badge,is_verified')
            .inFilter('id', ids);
        profiles.addEntries(List<Map<String, dynamic>>.from(ps).map((p) => MapEntry(p['id'].toString(), p)));
      }
      if (mounted) setState(() { messages..clear()..addAll(list); });
    } catch (_) {}
  }

  Future<void> _handleGifts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || seenGifts.contains(id)) continue;
      seenGifts.add(id);
      try {
        final gift = await Supabase.instance.client
            .from('gifts')
            .select('name,emoji')
            .eq('id', row['gift_id'])
            .maybeSingle();
        if (gift == null || !mounted) continue;
        setState(() => giftOverlay = {
          'emoji': gift['emoji'],
          'name': gift['name'],
          'amount': row['amount'],
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => giftOverlay = null);
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    messageSub?.cancel();
    giftSub?.cancel();
    voiceRoom?.disconnect();
    controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();
    final user = Supabase.instance.client.auth.currentUser;
    if (text.isEmpty || user == null) return;
    try {
      await Supabase.instance.client.from('room_messages').insert({
        'room_id': widget.roomId,
        'user_id': user.id,
        'message': text,
      });
      controller.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إرسال الرسالة: $e')));
    }
  }

  Future<void> _joinVoice() async {
    if (joiningVoice || voiceRoom != null) return;
    setState(() => joiningVoice = true);
    try {
      final roomData = await Supabase.instance.client.from('rooms').select('livekit_room_name').eq('id', widget.roomId).single();
      final livekitName = (roomData['livekit_room_name'] ?? widget.roomId).toString();
      final response = await Supabase.instance.client.functions.invoke('livekit-token', body: {'room': livekitName});
      final data = Map<String, dynamic>.from(response.data as Map);
      final room = lk.Room();
      await room.connect(data['url'].toString(), data['token'].toString());
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (!mounted) {
        await room.disconnect();
        return;
      }
      setState(() {
        voiceRoom = room;
        microphoneOn = true;
        joiningVoice = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => joiningVoice = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر دخول الصوت: $e')));
      }
    }
  }

  Future<void> _toggleMicrophone() async {
    if (voiceRoom == null) {
      await _joinVoice();
      return;
    }
    try {
      await voiceRoom!.localParticipant?.setMicrophoneEnabled(!microphoneOn);
      if (mounted) setState(() => microphoneOn = !microphoneOn);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تشغيل الميكروفون: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF100805),
          foregroundColor: Colors.white,
          title: Text(widget.name, style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: [Color(0xFF6B2C0B), Color(0xFF160A06)]),
                    border: Border.all(color: gold2),
                  ),
                  child: const Row(children: [
                    CircleAvatar(radius: 25, backgroundColor: Color(0xFF422511), child: Icon(Icons.mic, color: gold)),
                    SizedBox(width: 12),
                    Expanded(child: Text('غرفة صوتية • دردشة • هدايا', style: TextStyle(color: gold, fontWeight: FontWeight.w900))),
                    Icon(Icons.people, color: Colors.white70),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final row = messages[index];
                      return _message(row['message']?.toString() ?? '', profiles[row['user_id']?.toString()]);
                    },
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    color: const Color(0xFF100805),
                    child: Row(children: [
                      IconButton(
                        onPressed: joiningVoice ? null : _toggleMicrophone,
                        icon: Icon(joiningVoice ? Icons.hourglass_top : (microphoneOn ? Icons.mic : Icons.mic_off), color: gold),
                      ),
                      IconButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => GiftSheet(roomId: widget.roomId),
                        ),
                        icon: const Icon(Icons.card_giftcard, color: gold),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onSubmitted: (_) => _sendMessage(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالة...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: card,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CircleAvatar(
                        backgroundColor: gold2,
                        child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white, size: 20)),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            if (giftOverlay != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 45),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xF0150905),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: gold, width: 2),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(giftOverlay!['emoji']?.toString() ?? '🎁', style: const TextStyle(fontSize: 72)),
                    Text('هدية ' + (giftOverlay!['name']?.toString() ?? ''), style: const TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
                    Text((giftOverlay!['amount']?.toString() ?? '0') + ' 🪙', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text, Map<String, dynamic>? profile) {
    final avatar = profile?['avatar_url']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF4C3019))),
      child: Row(children: [
        RankFrame(
          role: profile?['role']?.toString() ?? 'USER',
          vipLevel: profile?['vip_level']?.toString(),
          size: 40,
          showLabel: false,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF422511),
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? const Icon(Icons.person, color: gold, size: 20) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CountryFlag(code: profile?['country_code']?.toString(), size: 18),
              const SizedBox(width: 5),
              Flexible(child: Text(profile?['username']?.toString() ?? 'مستخدم', overflow: TextOverflow.ellipsis, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w800))),
              const SizedBox(width: 5),
              ProfileBadges(
                activityAdmin: profile?['activity_admin_badge'] == true,
                customerService: profile?['customer_service_badge'] == true,
                verified: profile?['is_verified'] == true,
              ),
            ]),
            const SizedBox(height: 3),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }
}
