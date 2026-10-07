import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_runtime.dart';

class VoiceRoomRecord {
  const VoiceRoomRecord({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.liveKitRoomName,
    required this.isActive,
    required this.seatCount,
    this.countryCode,
    this.tags = const [],
    this.coverUrl,
    this.isPrivate = false,
    this.chatEnabled = true,
  });

  final String id;
  final String name;
  final String? ownerId;
  final String? liveKitRoomName;
  final bool isActive;
  final int seatCount;
  final String? countryCode;
  final List<String> tags;
  final String? coverUrl;
  final bool isPrivate;
  final bool chatEnabled;

  factory VoiceRoomRecord.fromMap(Map<String, dynamic> map) {
    return VoiceRoomRecord(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      ownerId: map['owner_id'] as String?,
      liveKitRoomName: map['livekit_room_name'] as String?,
      isActive: (map['is_active'] as bool?) ?? false,
      seatCount: (map['seat_count'] as num?)?.toInt() ?? 15,
      countryCode: map['country_code'] as String?,
      tags: (map['tags'] is List) ? List<String>.from(map['tags']) : const [],
      coverUrl: map['cover_url'] as String?,
      isPrivate: (map['is_private'] as bool?) ?? false,
      chatEnabled: (map['chat_enabled'] as bool?) ?? true,
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
        .select('id,name,owner_id,livekit_room_name,is_active,seat_count,country_code,tags,cover_url,is_private,chat_enabled')
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
    List<String> tags = const [],
    String roomType = 'party',
    int? seatCount,
  }) async {
    final db = client;
    final user = SupabaseRuntime.currentUser;
    if (db == null || user == null) {
      throw StateError('Supabase authentication is required to create a room.');
    }
    final row = await db.rpc('create_room_full', params: {
      'p_name': name.trim(),
      'p_seat_count': seatCount ?? 8,
      'p_room_type': roomType,
      'p_tags': tags,
      'p_country_code': 'JO',
      'p_cover_url': null,
    });
    final map = Map<String, dynamic>.from(row as Map);
    return VoiceRoomRecord.fromMap(map);
  }

  Future<void> joinRoom(String roomId) async {
    final db = client;
    if (db == null || SupabaseRuntime.currentUser == null) {
      throw StateError('Supabase authentication is required to join a room.');
    }
    await db.rpc('asmar_join_room', params: {'p_room_id': roomId});
  }

  Future<void> requestMic(String roomId) async { final db = client; if (db == null) return; await db.rpc('request_room_mic', params: {'p_room_id': roomId}); }

  Future<void> inviteUser(String roomId, String userId) async { final db = client; if (db == null) return; await db.rpc('invite_user_to_room', params: {'p_room_id': roomId, 'p_user_id': userId}); }

  Future<void> setChatEnabled(String roomId, bool enabled) async { final db = client; if (db == null) return; await db.rpc('set_room_chat_enabled', params: {'p_room_id': roomId, 'p_enabled': enabled}); }

  Future<void> setPrivate(String roomId, bool value) async { final db = client; if (db == null) return; await db.rpc('set_room_private', params: {'p_room_id': roomId, 'p_private': value}); }

  Future<void> muteAll(String roomId) async { final db = client; if (db == null) return; await db.rpc('mute_all_room_speakers', params: {'p_room_id': roomId}); }

  Future<void> leaveRoom(String roomId) async {
    final db = client;
    if (db == null || SupabaseRuntime.currentUser == null) return;
    await db.rpc('asmar_exit_room', params: {'p_room_id': roomId});
  }
}
