import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_runtime.dart';

class LiveKitRoomService {
  LiveKitRoomService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  Room? _room;

  Room? get room => _room;
  bool get isConnected => _room != null;
  bool get isMicrophoneEnabled =>
      _room?.localParticipant.isMicrophoneEnabled() ?? false;

  SupabaseClient? get client => _client ?? SupabaseRuntime.client;

  Future<Room> join({required String roomName}) async {
    final db = client;
    if (db == null) {
      throw StateError('Supabase is not configured.');
    }

    final response = await db.functions.invoke(
      'livekit-token',
      body: {'room': roomName},
    );

    final data = response.data;
    if (data is! Map || data['token'] is! String || data['url'] is! String) {
      throw StateError('LiveKit token endpoint returned an invalid response.');
    }

    final token = data['token'] as String;
    final url = data['url'] as String;

    final nextRoom = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );
    await nextRoom.connect(url, token);

    _room = nextRoom;
    return nextRoom;
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    final current = _room;
    if (current == null) return;
    await current.localParticipant.setMicrophoneEnabled(enabled);
  }

  Future<void> disconnect() async {
    final current = _room;
    _room = null;
    if (current == null) return;
    await current.disconnect();
    await current.dispose();
  }
}
