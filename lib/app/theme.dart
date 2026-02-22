import 'package:flutter/material.dart';

class AppTheme {
  static const Color cardinalRed = Color(0xFFC8102E);

  static ThemeData light() {
    return ThemeData(
      primaryColor: cardinalRed,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cardinalRed,
        primary: cardinalRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardinalRed,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardinalRed,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
