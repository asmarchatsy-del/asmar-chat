import 'package:flutter/material.dart';

import 'core/rooms/real_rooms_home_page.dart';

void main() => runApp(const AsmarChatApp());

class AsmarChatApp extends StatelessWidget {
  const AsmarChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asmar Chat',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
      ),
      home: const RealRoomsHomePage(),
    );
  }
}
