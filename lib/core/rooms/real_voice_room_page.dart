import 'package:flutter/material.dart';
import '../../gifts.dart';

import '../voice/livekit_room_service.dart';
import 'room_repository.dart';
import 'room_social_repository.dart';

class RealVoiceRoomPage extends StatefulWidget {
  const RealVoiceRoomPage({super.key, required this.room});

  final VoiceRoomRecord room;

  @override
  State<RealVoiceRoomPage> createState() => _RealVoiceRoomPageState();
}

class _RealVoiceRoomPageState extends State<RealVoiceRoomPage> {
  final _roomRepository = RoomRepository();
  final _socialRepository = RoomSocialRepository();
  final _voice = LiveKitRoomService();
  final _messageController = TextEditingController();
  bool _joining = true;
  bool _muted = true;
  int? _mySeat;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _roomRepository.joinRoom(widget.room.id);
      final liveKitRoom = widget.room.liveKitRoomName;
      if (liveKitRoom == null || liveKitRoom.isEmpty) {
        throw StateError('LiveKit room name is missing.');
      }
      await _voice.join(roomName: liveKitRoom);
      await _voice.setMicrophoneEnabled(false);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _claimSeat(int seatIndex) async {
    if (_mySeat != null) return;
    try {
      await _socialRepository.claimSeat(widget.room.id, seatIndex + 1);
      if (mounted) setState(() => _mySeat = seatIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_mySeat == null) return;
    final nextMuted = !_muted;
    try {
      await _voice.setMicrophoneEnabled(!nextMuted);
      await _socialRepository.setMuted(widget.room.id, nextMuted);
      if (mounted) setState(() => _muted = nextMuted);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _leave() async {
    try {
      if (_mySeat != null) {
        await _socialRepository.leaveSeat(widget.room.id, _mySeat! + 1);
      }
      await _roomRepository.leaveRoom(widget.room.id);
      await _voice.disconnect();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _voice.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF060716);
    const panel2 = Color(0xFF171A3A);
    const purple = Color(0xFF8B4DFF);
    const pink = Color(0xFFE33DFF);
    const cyan = Color(0xFF4EDCFF);
    const muted = Color(0xFF9CA2C5);

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF17104A), bg, bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    IconButton(onPressed: _leave, icon: const Icon(Icons.close_rounded)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.room.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(_joining ? 'جاري الاتصال...' : 'غرفة مباشرة',
                              style: const TextStyle(color: muted, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openPeopleSheet(context),
                      icon: const Icon(Icons.people_alt_rounded, color: cyan),
                    ),
                    IconButton(
                      onPressed: () => _openRoomInfoSheet(context),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  ],
                ),
              ),
              if (_joining) const LinearProgressIndicator(minHeight: 2),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Text(_error!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _socialRepository.watchSeats(widget.room.id),
                  builder: (context, snapshot) {
                    final seats = snapshot.data ?? const <Map<String, dynamic>>[];
                    final byIndex = <int, Map<String, dynamic>>{
                      for (final seat in seats)
                        if (seat['seat_index'] is num)
                          (seat['seat_index'] as num).toInt() - 1: seat,
                    };
                    final occupiedCount = seats.where((x) => x['occupant_id'] != null).length;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 7),
                          child: Row(
                            children: [
                              const Icon(Icons.mic_rounded, size: 17, color: cyan),
                              const SizedBox(width: 5),
                              Text(occupiedCount.toString() + '/' + widget.room.seatCount.toString(),
                                  style: const TextStyle(color: Colors.white70)),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () => _openGiftSheet(context),
                                icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                                label: const Text('هدايا'),
                                style: FilledButton.styleFrom(backgroundColor: purple),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 16, childAspectRatio: .82,
                            ),
                            itemCount: widget.room.seatCount,
                            itemBuilder: (_, index) {
                              final seat = byIndex[index];
                              final occupied = seat?['occupant_id'] != null;
                              final mine = _mySeat == index;
                              return InkWell(
                                onTap: occupied ? null : () => _claimSeat(index),
                                borderRadius: BorderRadius.circular(18),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 62, height: 62,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: occupied || mine
                                            ? const LinearGradient(colors: [pink, purple])
                                            : const LinearGradient(colors: [panel2, Color(0xFF0D1027)]),
                                        border: Border.all(
                                          color: mine ? cyan : Colors.white.withOpacity(.08),
                                          width: mine ? 2 : 1,
                                        ),
                                      ),
                                      child: Icon(
                                        occupied ? Icons.person_rounded : Icons.add_rounded,
                                        color: occupied || mine ? Colors.white : muted,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      occupied ? (mine ? 'أنت' : 'مستخدم ' + (index + 1).toString()) : (index + 1).toString(),
                                      style: TextStyle(color: mine ? cyan : Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _socialRepository.watchMessages(widget.room.id),
                          builder: (context, msgSnapshot) {
                            final messages = msgSnapshot.data ?? const <Map<String, dynamic>>[];
                            return Container(
                              height: 92,
                              margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.18),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: messages.isEmpty
                                  ? const Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('ابدأ المحادثة داخل الغرفة 👋', style: TextStyle(color: muted)),
                                    )
                                  : ListView.builder(
                                      reverse: true,
                                      itemCount: messages.length > 8 ? 8 : messages.length,
                                      itemBuilder: (_, i) {
                                        final row = messages[messages.length - 1 - i];
                                        return Text(
                                          '• ' + (row['message']?.toString() ?? ''),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        );
                                      },
                                    ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: _mySeat == null ? null : _toggleMute,
                        icon: Icon(_muted ? Icons.mic_off_rounded : Icons.mic_rounded),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالة...',
                            filled: true,
                            fillColor: panel2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onSubmitted: (_) => _sendRoomMessage(),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openGiftSheet(context),
                        icon: const Icon(Icons.card_giftcard_rounded, color: pink),
                      ),
                      IconButton(onPressed: _leave, icon: const Icon(Icons.logout_rounded)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendRoomMessage() async {
    final value = _messageController.text.trim();
    if (value.isEmpty) return;
    try {
      await _socialRepository.sendMessage(widget.room.id, value);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openGiftSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftSheet(roomId: widget.room.id),
    );
  }

  void _openPeopleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10132B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _socialRepository.watchSeats(widget.room.id),
        builder: (context, snapshot) {
          final seats = (snapshot.data ?? const <Map<String, dynamic>>[]).where((x) => x['occupant_id'] != null).toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .58,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('الأشخاص في الغرفة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    child: seats.isEmpty
                        ? const Center(child: Text('لا يوجد أحد على المقاعد حالياً', style: TextStyle(color: Color(0xFF9CA2C5))))
                        : ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: seats.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => ListTile(
                              tileColor: const Color(0xFF171A3A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              leading: const CircleAvatar(backgroundColor: Color(0xFF8B4DFF), child: Icon(Icons.person_rounded)),
                              title: Text('مستخدم ' + (i + 1).toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('المقعد ' + (seats[i]['seat_index'] ?? i + 1).toString(),
                                  style: const TextStyle(color: Color(0xFF9CA2C5))),
                              trailing: const Icon(Icons.mic_none_rounded, color: Color(0xFF4EDCFF)),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openRoomInfoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10132B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF4EDCFF), size: 32),
              const SizedBox(height: 8),
              Text(widget.room.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('ID: ' + widget.room.id, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF9CA2C5))),
              const SizedBox(height: 12),
              Text('المقاعد: ' + widget.room.seatCount.toString(), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
