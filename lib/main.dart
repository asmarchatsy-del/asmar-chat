import 'package:flutter/material.dart';

import 'backend_config.dart';
import 'core/auth/auth_deep_link_handler.dart';
import 'core/backend/supabase_runtime.dart';
import 'app_shell.dart';
import 'asmar_premium_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BackendConfig.validate();
  final initialized = await SupabaseRuntime.initialize();
  if (initialized) {
    await AuthDeepLinkHandler.instance.start();
  }
  runApp(const AsmarChatApp());
}

class AsmarChatApp extends StatelessWidget {
  const AsmarChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asmar Chat',
      theme: AsmarPremiumTheme.dark,
      home: const AsmarAuthGate(),
    );
  }
}
