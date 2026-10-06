import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> signInWithGoogle() async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');

    final started = await db.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );

    if (!started) {
      throw const AuthException('تعذر بدء تسجيل الدخول باستخدام Google.');
    }

  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');
    return db.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> resendSignupConfirmation(String email) async {
    final db = client;
    if (db == null) throw StateError('Supabase is not configured.');
    await db.auth.resend(type: OtpType.signup, email: email.trim());
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
