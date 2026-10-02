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

  const Room({
    super.key,
    required this.name,
    required this.roomId,
  });

  @override
  State<Room> createState() => _RoomState();
}

class _RoomState extends State<Room> {
  final TextEditingController messageController =
      TextEditingController();

  final List<Map<String, dynamic>> messages = [];
  final Map<String, Map<String,dynamic>> profiles = {};
  StreamSubscription<List<Map<String, dynamic>>>? _messageSub;
  StreamSubscription<List<Map<String, dynamic>>>? _giftSub;
  final Set<String> _seenGiftIds = {};
  lk.Room? _voiceRoom;
  bool microphoneOn = false;
  bool joiningVoice = false;
  Map<String, dynamic>? _giftOverlay;

  void _showGiftAnimation(Map<String, dynamic> gift) {
    if (!mounted) return;
    setState(() => _giftOverlay = gift);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _giftOverlay = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _giftSub = Supabase.instance.client
        .from('gift_transactions')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at')
        .listen((rows) async {
          for (final row in rows) {
            final id = row['id']?.toString();
            if (id == null || _seenGiftIds.contains(id)) continue;
            _seenGiftIds.add(id);
            try {
              final gift = await Supabase.instance.client.from('gifts').select('name,emoji,price').eq('id', row['gift_id']).single();
              if (mounted) _showGiftAnimation({'emoji': gift['emoji'], 'name': gift['name'], 'amount': row['amount']});
            } catch (_) {}
          }
        });
    _messageSub = Supabase.instance.client
        .from('room_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at')
        .listen((rows) {
          if (mounted) setState(() => messages..clear()..addAll(rows));
        });
  }

  Future<void> _loadMessages() async {
    final rows = await Supabase.instance.client.from('room_messages').select('id,user_id,message,created_at').eq('room_id', widget.roomId).order('created_at');
    final list=List<Map<String,dynamic>>.from(rows); final ids=list.map((m)=>m['user_id'].toString()).toSet().toList();
    if(ids.isNotEmpty){final ps=await Supabase.instance.client.from('profiles').select('id,username,role,country_code,vip_level,avatar_url,avatar_is_animated,activity_admin_badge,customer_service_badge,is_verified').inFilter('id',ids); profiles.addEntries(List<Map<String,dynamic>>.from(ps).map((p)=>MapEntry(p['id'].toString(),p)));}
    if (mounted) setState(() => messages..clear()..addAll(list));
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _giftSub?.cancel();
    _voiceRoom?.disconnect();
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('room_messages').insert({
        'room_id': widget.roomId, 'user_id': user.id, 'message': text,
      });
      messageController.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إرسال الرسالة: $e')));
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
          title: Text(
            widget.name,
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
            _roomHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m=messages[index]; return _message(m['message'].toString(),profiles[m['user_id'].toString()]);
                },
              ),
            ),
            _bottomBar(),
              ],
            ),
            if (_giftOverlay != null)
              Center(
                child: AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 350),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 45),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xF0150905),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: gold, width: 2),
                      boxShadow: const [BoxShadow(color: Color(0x99FFD36A), blurRadius: 30)],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_giftOverlay!['emoji']?.toString() ?? '🎁', style: const TextStyle(fontSize: 72)),
                      Text('هدية ' + (_giftOverlay!['name']?.toString() ?? ''), style: const TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
                      Text((_giftOverlay!['amount']?.toString() ?? '0') + ' 🪙', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinVoice() async {
    if (joiningVoice || _voiceRoom != null) return;
    setState(() => joiningVoice = true);
    try {
      final roomData = await Supabase.instance.client
          .from('rooms').select('livekit_room_name').eq('id', widget.roomId).single();
      final livekitRoom = (roomData['livekit_room_name'] ?? widget.roomId).toString();
      final response = await Supabase.instance.client.functions.invoke(
        'livekit-token', body: {'room': livekitRoom});
      final data = Map<String, dynamic>.from(response.data as Map);
      final url = data['url'].toString();
      final token = data['token'].toString();
      final room = lk.Room();
      await room.connect(url, token);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (!mounted) { await room.disconnect(); return; }
      setState(() { _voiceRoom = room; microphoneOn = true; joiningVoice = false; });
    } catch (e) {
      if (mounted) { setState(() => joiningVoice = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر دخول الصوت: $e'))); }
    }
  }

  Future<void> _toggleMicrophone() async {
    if (_voiceRoom == null) {
      await _joinVoice();
      return;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الصوت الحقيقي يحتاج LiveKit Token من الخادم الآمن. الدردشة النصية تعمل الآن.')));
      return;
    }
    try {
      await _voiceRoom!.localParticipant?.setMicrophoneEnabled(!microphoneOn);
      if (mounted) setState(() => microphoneOn = !microphoneOn);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تشغيل الميكروفون: $e')));
    }
  }

  Widget _roomHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B2C0B),
            Color(0xFF160A06),
          ],
        ),
        border: Border.all(color: gold2),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF422511),
            child: Icon(
              Icons.mic,
              color: gold,
              size: 30,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'غرفة صوتية',
                  style: TextStyle(
                    color: gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'مضيف • دردشة • هدايا',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.people,
            color: Colors.white70,
          ),
          SizedBox(width: 5),
          Text(
            '24',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ])),
        ],
      ),
    );
  }

  Widget _message(String text, Map<String,dynamic>? profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF4C3019),
        ),
      ),
      child: Row(
        children: [
          RankFrame(role: profile?['role']?.toString()??'USER', vipLevel: profile?['vip_level']?.toString(), size: 40, showLabel: false, child: CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF422511),
            backgroundImage: (profile?['avatar_url']?.toString() ?? '').isNotEmpty
                ? NetworkImage(profile!['avatar_url'].toString())
                : null,
            child: (profile?['avatar_url']?.toString() ?? '').isEmpty
                ? const Icon(Icons.person, color: gold, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Row(children:[CountryFlag(code: profile?['country_code']?.toString(),size:18),const SizedBox(width:5),Text(profile?['username']?.toString()??'مستخدم',style:const TextStyle(color:gold,fontSize:11,fontWeight:FontWeight.w800)),const SizedBox(width:5),ProfileBadges(activityAdmin:profile?['activity_admin_badge']==true,customerService:profile?['customer_service_badge']==true,verified:profile?['is_verified']==true), if((profile?['vip_level']?.toString()??'').isNotEmpty) ...[const SizedBox(width:5),Text(profile!['vip_level'].toString(),style:const TextStyle(color:gold,fontSize:9,fontWeight:FontWeight.w900))]]),
            const SizedBox(height:3), Text(text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        color: const Color(0xFF100805),
        child: Row(
          children: [
            IconButton(onPressed: joiningVoice ? null : _toggleMicrophone, icon: Icon(joiningVoice ? Icons.hourglass_top : (microphoneOn ? Icons.mic : Icons.mic_off), color: gold)),
            IconButton(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => GiftSheet(roomId: widget.roomId, onSent: (g) => _showGiftAnimation({'emoji': g.emoji, 'name': g.name, 'amount': g.price})), icon: const Icon(Icons.card_giftcard, color: gold)),
            Expanded(
              child: TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                  ),
                  filled: true,
                  fillColor: card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: gold2,
              child: IconButton(
                onPressed: sendMessage,
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
