import 'package:flutter/foundation.dart';

/// Runtime configuration for the real Asmar Chat backend.
///
/// Pass these at build/run time; never commit service-role secrets.
/// Example:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
class BackendConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static void validate() {
    if (!isConfigured) {
      debugPrint(
        'Asmar Chat: Supabase is not configured. '
        'Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
      );
    }
  }
}
