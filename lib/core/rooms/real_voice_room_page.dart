import 'package:flutter/material.dart';

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
      await _socialRepository.claimSeat(widget.room.id, seatIndex);
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
        await _socialRepository.leaveSeat(widget.room.id, _mySeat!);
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.room.name)),
      body: Column(
        children: [
          if (_joining) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _socialRepository.watchSeats(widget.room.id),
              builder: (context, snapshot) {
                final seats = snapshot.data ?? const <Map<String, dynamic>>[];
                final byIndex = <int, Map<String, dynamic>>{
                  for (final seat in seats) (seat['seat_index'] as num).toInt() - 1: seat,
                };
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: widget.room.seatCount,
                  itemBuilder: (_, index) {
                    final seat = byIndex[index];
                    final occupied = seat?['user_id'] != null;
                    final mine = _mySeat == index;
                    return InkWell(
                      onTap: occupied ? null : () => _claimSeat(index),
                      child: Card(
                        color: mine ? Theme.of(context).colorScheme.primary : null,
                        child: Center(
                          child: Text(occupied ? (mine ? '🎤\nأنت' : '🎤') : '➕', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _socialRepository.watchMessages(widget.room.id),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? const <Map<String, dynamic>>[];
              return SizedBox(
                height: 140,
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (_, index) => ListTile(
                    dense: true,
                    title: Text(messages[index]['body']?.toString() ?? ''),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: _mySeat == null ? null : _toggleMute,
                  icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'اكتب رسالة...'),
                    onSubmitted: (value) async {
                      if (value.trim().isEmpty) return;
                      try {
                        await _socialRepository.sendMessage(widget.room.id, value);
                        _messageController.clear();
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                  ),
                ),
                IconButton(onPressed: _leave, icon: const Icon(Icons.exit_to_app)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
