import 'package:flutter/foundation.dart';

class BackendConfig {
  static const supabaseUrl = 'https://jojxsq...'; // خليه نفس يلي عندك
  static const supabasePublishableKey = 'sb_publishable_mC6...'; // خليه نفس يلي عندك

  // هاد السطر الجديد تبع الصوت - ضيفو
  static const agoraAppId = 'YOUR_AGORA_APP_ID';

  static bool get isConfigured => 
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static void validate() {
    if (!isConfigured) {
      debugPrint('Asmar Chat: Supabase backend not configured');
    }
  }
}
