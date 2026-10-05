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
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _roomRepository.joinRoom(widget.room.id);
      if (widget.room.liveKitRoomName == null || widget.room.liveKitRoomName!.isEmpty) {
        throw StateError('LiveKit room name is missing.');
      }
      await _voice.join(roomName: widget.room.liveKitRoomName!);
      await _voice.setMicrophoneEnabled(false);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    try {
      await _voice.setMicrophoneEnabled(!next);
      await _socialRepository.setMuted(widget.room.id, next);
      if (mounted) setState(() => _muted = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _leave() async {
    await _socialRepository.leaveSeat(widget.room.id);
    await _roomRepository.leaveRoom(widget.room.id);
    await _voice.disconnect();
    if (mounted) Navigator.of(context).pop();
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
                  for (final seat in seats) (seat['seat_index'] as num).toInt(): seat,
                };
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 30,
                  itemBuilder: (_, index) {
                    final seat = byIndex[index];
                    final occupied = seat?['user_id'] != null;
                    return Card(
                      child: Center(
                        child: Text(occupied ? '🎤' : '➕', style: const TextStyle(fontSize: 28)),
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
                IconButton(onPressed: _toggleMute, icon: Icon(_muted ? Icons.mic_off : Icons.mic)),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'اكتب رسالة...'),
                    onSubmitted: (value) async {
                      if (value.trim().isEmpty) return;
                      await _socialRepository.sendMessage(widget.room.id, value);
                      _messageController.clear();
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
