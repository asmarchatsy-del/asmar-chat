import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:livekit_client/livekit_client.dart';

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
  StreamSubscription<List<Map<String, dynamic>>>? _messageSub;
  Room? _voiceRoom;
  bool microphoneOn = false;
  bool joiningVoice = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
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
    if (mounted) setState(() => messages..clear()..addAll(List<Map<String, dynamic>>.from(rows)));
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _voiceRoom?.disconnect();
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
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
        body: Column(
          children: [
            _roomHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _message(messages[index]['message'].toString());
                },
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMicrophone() async {
    if (_voiceRoom == null) {
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
          ),
        ],
      ),
    );
  }

  Widget _message(String text) {
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
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF422511),
            child: Icon(
              Icons.person,
              color: gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
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
            IconButton(onPressed: _toggleMicrophone, icon: Icon(microphoneOn ? Icons.mic : Icons.mic_off, color: gold)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.card_giftcard, color: gold)),
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
