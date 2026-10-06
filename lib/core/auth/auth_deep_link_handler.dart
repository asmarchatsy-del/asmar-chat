import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDeepLinkHandler {
  AuthDeepLinkHandler._();

  static final AuthDeepLinkHandler instance = AuthDeepLinkHandler._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _subscription = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object error, StackTrace stack) {
        debugPrint('Asmar Chat OAuth deep-link error: $error');
        debugPrintStack(stackTrace: stack);
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handle(initialUri);
      }
    } catch (error, stack) {
      debugPrint('Asmar Chat OAuth initial deep-link error: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'io.supabase.flutter' ||
        uri.host != 'login-callback') {
      return;
    }

    final hasAuthPayload = uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('access_token') ||
        uri.queryParameters.containsKey('error') ||
        uri.queryParameters.containsKey('error_code') ||
        uri.fragment.contains('access_token=');

    if (!hasAuthPayload) return;

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } on AuthException catch (error, stack) {
      debugPrint('Asmar Chat Google OAuth callback failed: ${error.message}');
      debugPrintStack(stackTrace: stack);
    } catch (error, stack) {
      debugPrint('Asmar Chat Google OAuth callback failed: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
