import 'package:flutter/material.dart';

import 'backend_config.dart';
import 'core/auth/auth_deep_link_handler.dart';
import 'core/backend/supabase_runtime.dart';
import 'app_shell.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC94A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF070817),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF070817),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF151936),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(17)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AsmarAuthGate(),
    );
  }
}
