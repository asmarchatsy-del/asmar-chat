import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_runtime.dart';

class WalletRepository {
  WalletRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get client => _client ?? SupabaseRuntime.client;

  Future<int> getBalance() async {
    final db = client;
    final user = SupabaseRuntime.currentUser;
    if (db == null || user == null) {
      throw StateError('Authentication is required to read the wallet.');
    }

    final row = await db
        .from('wallets')
        .select('balance')
        .eq('user_id', user.id)
        .maybeSingle();

    return (row?['balance'] as num?)?.toInt() ?? 0;
  }

  Future<void> transferCoins({
    required String toUserId,
    required int amount,
    String reason = 'transfer',
  }) async {
    final db = client;
    if (db == null || SupabaseRuntime.currentUser == null) {
      throw StateError('Authentication is required to transfer coins.');
    }
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be greater than zero.');
    }

    await db.rpc('transfer_coins', params: {
      'p_to_user_id': toUserId,
      'p_amount': amount,
      'p_reason': reason,
    });
  }

  Stream<List<Map<String, dynamic>>> watchTransactions() {
    final db = client;
    final user = SupabaseRuntime.currentUser;
    if (db == null || user == null) return const Stream.empty();

    return db
        .from('coin_transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }
}
