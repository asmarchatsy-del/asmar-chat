import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const gold = Color(0xFFFFD700);
  static const goldLight = Color(0xFFFFF176);
  static const goldDark = Color(0xFF8B6914);
  static const purple1 = Color(0xFF3A1A7A);
  static const purple2 = Color(0xFF2D0B5A);
  static const room1 = Color(0xFF2A2340);
  static const room2 = Color(0xFF3B2F5E);
  static const page = Color(0xFF15121D);

  static const goldGradient = LinearGradient(
    colors: [goldDark, gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bottomGradient = LinearGradient(
    colors: [purple1, purple2],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const roomGradient = LinearGradient(
    colors: [room1, room2],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}
