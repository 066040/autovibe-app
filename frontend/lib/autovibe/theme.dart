import 'package:flutter/material.dart';

ThemeData buildAutoVibeTheme(Brightness b) {
  final isDark = b == Brightness.dark;

  const accent = Color(0xFF2D6BFF);
  const darkBg = Color(0xFF0B1220);
  const lightBg = Color(0xFFF5F7FA);

  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    colorSchemeSeed: accent,
  );

  return base.copyWith(
    scaffoldBackgroundColor: isDark ? darkBg : lightBg,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? darkBg : lightBg,
      foregroundColor: isDark ? Colors.white : Colors.black,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : Colors.black,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF0B1020) : Colors.white,
      indicatorColor: accent.withOpacity(isDark ? 0.18 : 0.10),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
