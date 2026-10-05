import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_runtime.dart';

class GiftRepository {
  GiftRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get client => _client ?? SupabaseRuntime.client;

  Future<List<Map<String, dynamic>>> fetchCatalog() async {
    final db = client;
    if (db == null) return const [];
    final rows = await db
        .from('gift_catalog')
        .select('id,code,name,price,animation_url')
        .eq('active', true)
        .order('price');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> sendGift({
    required String roomId,
    required String receiverId,
    required String giftId,
    int quantity = 1,
  }) async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');
    await db.rpc('send_gift', params: {
      'p_room_id': roomId,
      'p_receiver_id': receiverId,
      'p_gift_id': giftId,
      'p_quantity': quantity,
    });
  }

  Stream<List<Map<String, dynamic>>> watchRoomGifts(String roomId) {
    final db = client;
    if (db == null) return const Stream.empty();
    return db
        .from('gift_transactions')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
  }
}
