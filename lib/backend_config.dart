import 'package:flutter/foundation.dart';

/// Production configuration for the Asmar Chat Supabase backend.
/// The publishable key is intended for client apps; never put a Supabase
/// secret/service-role key in this file.
class BackendConfig {
  static const supabaseUrl = 'https://jojxsqsgmpaggfnnyuyy.supabase.co';
  static const supabasePublishableKey =
      'sb_publishable_mC6rnw-HAwJzNu_2d-0A2g_SrEBWyjL';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static void validate() {
    if (!isConfigured) {
      debugPrint('Asmar Chat: Supabase backend is not configured.');
    }
  }
}
