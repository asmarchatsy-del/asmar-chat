import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_runtime.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get client => _client ?? SupabaseRuntime.client;

  Stream<AuthState> get authStateChanges {
    final db = client;
    if (db == null) return const Stream.empty();
    return db.auth.onAuthStateChange;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');
    return db.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');
    return db.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
  }

  Future<void> signOut() async {
    final db = client;
    if (db == null) return;
    await db.auth.signOut();
  }
}
