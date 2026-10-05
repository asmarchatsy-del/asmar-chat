import 'package:flutter/foundation.dart';

class BackendConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');
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
