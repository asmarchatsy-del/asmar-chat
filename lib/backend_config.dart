import 'package:flutter/foundation.dart';

class BackendConfig {
  // Publishable values are safe to ship in a mobile client. CI can still
  // override them with dart-define, while released APKs keep a working
  // backend configuration when no build-time define is supplied.
  static const _defaultSupabaseUrl = 'https://jojxsqsgmpaggfnnyuyy.supabase.co';
  static const _defaultSupabasePublishableKey = 'sb_publishable_mC6rnw-HAwJzNu_2d-0A2g_SrEBWyjL';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultSupabasePublishableKey,
  );
  static const agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  static bool get isConfigured =>
      supabaseUrl.trim().startsWith('https://') &&
      supabasePublishableKey.trim().isNotEmpty;

  static void validate() {
    if (!isConfigured) {
      debugPrint('Asmar Chat: missing SUPABASE_URL / SUPABASE_ANON_KEY');
    }
  }
}
