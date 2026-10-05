import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_runtime.dart';

class RoomSocialRepository {
  RoomSocialRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get client => _client ?? SupabaseRuntime.client;

  Stream<List<Map<String, dynamic>>> watchSeats(String roomId) {
    final db = client;
    if (db == null) return const Stream.empty();
    return db.from('room_seats').stream(primaryKey: ['room_id', 'seat_index']).eq('room_id', roomId);
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String roomId) {
    final db = client;
    if (db == null) return const Stream.empty();
    return db
        .from('room_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
  }

  Future<void> claimSeat(String roomId, int seatIndex) async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');
    await db.rpc('claim_room_seat', params: {
      'p_room_id': roomId,
      'p_seat_index': seatIndex,
    });
  }

  Future<void> leaveSeat(String roomId) async {
    final db = client;
    if (db == null) return;
    await db.rpc('leave_room_seat', params: {'p_room_id': roomId});
  }

  Future<void> setMuted(String roomId, bool muted) async {
    final db = client;
    if (db == null) return;
    await db.rpc('set_room_seat_mute', params: {
      'p_room_id': roomId,
      'p_muted': muted,
    });
  }

  Future<void> sendMessage(String roomId, String body) async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');
    await db.rpc('send_room_message', params: {
      'p_room_id': roomId,
      'p_body': body,
    });
  }
}
