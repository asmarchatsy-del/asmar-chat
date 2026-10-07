import 'package:flutter/material.dart';

abstract final class AsmarPremiumTheme {
  static const bg = Color(0xFF090604);
  static const bg2 = Color(0xFF120B08);
  static const surface = Color(0xFF1A100B);
  static const surface2 = Color(0xFF24150D);
  static const gold = Color(0xFFFFD36A);
  static const goldBright = Color(0xFFFFE8A8);
  static const goldDeep = Color(0xFF9A641F);
  static const copper = Color(0xFFB77921);
  static const wine = Color(0xFF3A1808);
  static const muted = Color(0xFFB9A995);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldBright, gold, copper],
  );

  static const luxuryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3A1808), surface, bg],
  );

  static BoxDecoration panel({double radius = 20, bool glow = false}) => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A1609), Color(0xFF100805)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: goldDeep.withOpacity(.48)),
    boxShadow: glow
        ? const [BoxShadow(color: Color(0x554A2608), blurRadius: 24, spreadRadius: 1)]
        : const [],
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      onPrimary: Color(0xFF201200),
      secondary: goldDeep,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: Colors.white,
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF100906),
      indicatorColor: const Color(0x332D0A0A),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? goldBright : muted,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? gold : muted, size: 23);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      hintStyle: const TextStyle(color: muted),
      labelStyle: const TextStyle(color: muted),
      prefixIconColor: gold,
      suffixIconColor: gold,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: goldDeep.withOpacity(.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: goldDeep.withOpacity(.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: gold, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: const Color(0xFF1C1004),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface2,
      selectedColor: const Color(0xFF4A1515),
      side: BorderSide(color: goldDeep.withOpacity(.35)),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      secondaryLabelStyle: const TextStyle(color: gold),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: goldDeep.withOpacity(.18), thickness: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: bg2,
      modalBackgroundColor: bg2,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface2,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
