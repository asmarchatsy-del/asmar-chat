import 'package:supabase_flutter/supabase_flutter.dart';
import '../../backend_config.dart';

class SupabaseRuntime {
  SupabaseRuntime._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static bool get hasUsableConfig {
    final url = BackendConfig.supabaseUrl.trim();
    final key = BackendConfig.supabasePublishableKey.trim();
    return url.startsWith('https://') &&
        !url.contains('...') &&
        key.isNotEmpty &&
        !key.contains('...') &&
        !key.startsWith('YOUR_');
  }

  static Future<bool> initialize() async {
    if (_initialized) return true;
    if (!hasUsableConfig) return false;

    try {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl,
        publishableKey: BackendConfig.supabasePublishableKey,
      );
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  static User? get currentUser => client?.auth.currentUser;
}
