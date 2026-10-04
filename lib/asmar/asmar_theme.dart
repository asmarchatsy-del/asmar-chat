import 'package:flutter/material.dart';

abstract final class AsmarTheme {
  static const background = Color(0xFF080604);
  static const surface = Color(0xFF15100B);
  static const surface2 = Color(0xFF21170D);
  static const gold = Color(0xFFFFD36A);
  static const goldDark = Color(0xFFB77921);
  static const muted = Color(0xFF9B9288);

  static ThemeData theme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(backgroundColor: background, foregroundColor: gold, elevation: 0),
      );

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF4B321A)),
      );

  static BoxDecoration goldCard({double radius = 16}) => BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3A250F), Color(0xFF120B06)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: goldDark),
      );
}
