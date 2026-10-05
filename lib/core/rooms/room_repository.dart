import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_runtime.dart';

class VoiceRoomRecord {
  const VoiceRoomRecord({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.liveKitRoomName,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? ownerId;
  final String? liveKitRoomName;
  final bool isActive;

  factory VoiceRoomRecord.fromMap(Map<String, dynamic> map) {
    return VoiceRoomRecord(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      ownerId: map['owner_id'] as String?,
      liveKitRoomName: map['livekit_room_name'] as String?,
      isActive: (map['is_active'] as bool?) ?? false,
    );
  }
}

class RoomRepository {
  RoomRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient? get client => _client ?? SupabaseRuntime.client;

  Future<List<VoiceRoomRecord>> fetchActiveRooms() async {
    final db = client;
    if (db == null) return const [];
    final rows = await db
        .from('rooms')
        .select('id,name,owner_id,livekit_room_name,is_active')
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(VoiceRoomRecord.fromMap)
        .toList(growable: false);
  }

  Stream<List<Map<String, dynamic>>> watchActiveRooms() {
    final db = client;
    if (db == null) return const Stream.empty();
    return db
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false);
  }

  Future<VoiceRoomRecord> createRoom({
    required String name,
    required String liveKitRoomName,
  }) async {
    final db = client;
    final user = SupabaseRuntime.currentUser;
    if (db == null || user == null) {
      throw StateError('Supabase authentication is required to create a room.');
    }

    final row = await db.rpc('create_room', params: {
      'p_name': name.trim(),
      'p_livekit_room_name': liveKitRoomName.trim(),
    });

    if (row is Map<String, dynamic>) return VoiceRoomRecord.fromMap(row);
    if (row is List && row.isNotEmpty) {
      return VoiceRoomRecord.fromMap(
        Map<String, dynamic>.from(row.first as Map),
      );
    }

    final created = await db
        .from('rooms')
        .select('id,name,owner_id,livekit_room_name,is_active')
        .eq('owner_id', user.id)
        .eq('name', name.trim())
        .order('created_at', ascending: false)
        .limit(1)
        .single();
    return VoiceRoomRecord.fromMap(created);
  }

  Future<void> joinRoom(String roomId) async {
    final db = client;
    if (db == null || SupabaseRuntime.currentUser == null) {
      throw StateError('Supabase authentication is required to join a room.');
    }
    await db.rpc('join_room', params: {'p_room_id': roomId});
  }

  Future<void> leaveRoom(String roomId) async {
    final db = client;
    if (db == null || SupabaseRuntime.currentUser == null) return;
    await db.rpc('leave_room', params: {'p_room_id': roomId});
  }
}
