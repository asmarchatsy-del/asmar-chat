import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_runtime.dart';

class RoomSocialRepository {
  RoomSocialRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient? get client => _client ?? SupabaseRuntime.client;

  Stream<List<Map<String, dynamic>>> watchSeats(String roomId) {
    final db = client;
    if (db == null) return const Stream.empty();
    return db
        .from('room_seats')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId);
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
    await db.rpc('join_room_seat', params: {
      'p_room_id': roomId,
      'p_seat_index': seatIndex,
    });
  }

  Future<void> leaveSeat(String roomId, int seatIndex) async {
    final db = client;
    if (db == null) return;
    await db.rpc('leave_room_seat', params: {
      'p_room_id': roomId,
      'p_seat_index': seatIndex,
    });
  }

  Future<void> setMuted(String roomId, bool muted) async {
    final db = client;
    if (db == null) return;
    await db.rpc('set_room_mute', params: {
      'p_room_id': roomId,
      'p_muted': muted,
    });
  }

  Future<void> setSeatLocked(String roomId, int seatIndex, bool locked) async {
    final db = client;
    if (db == null) return;
    await db.rpc('set_room_seat_locked', params: {
      'p_room_id': roomId,
      'p_seat_index': seatIndex,
      'p_locked': locked,
    });
  }

  Future<void> removeSeat(String roomId, int seatIndex) async {
    final db = client;
    if (db == null) return;
    await db.rpc('remove_room_seat', params: {
      'p_room_id': roomId,
      'p_seat_index': seatIndex,
    });
  }

  Future<void> sendMessage(String roomId, String body) async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');
    await db.rpc('send_room_message', params: {
      'p_room_id': roomId,
      'p_message': body.trim(),
    });
  }
}
