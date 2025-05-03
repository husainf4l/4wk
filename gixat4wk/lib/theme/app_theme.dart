import 'package:flutter/material.dart';

class AppTheme {
  // App colors
  static const Color primaryColor = Color(0xFF4A67F7);
  static const Color secondaryColor = Color(0xFF03DAC5);
  static const Color lightBackground = Color(0xFFF2F3F8);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF303030);
  static const Color darkCardColor = Color(0xFF242424);
  static const Color lightTextColor = Color(0xFF303030);
  static const Color darkTextColor = Colors.white;
  static const Color lightBodyTextColor = Color(0xFF424242);
  static const Color darkBodyTextColor = Color(0xFFE0E0E0);

  // Light Theme
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        // Replacing deprecated 'background' with appropriate property
        surfaceContainerLowest: lightBackground,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: lightTextColor,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: lightTextColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: lightBodyTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
  }

  // Dark Theme
  static ThemeData darkTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        // Replacing deprecated 'background' with appropriate property
        surfaceContainerLowest: darkBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkTextColor,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: darkTextColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: darkBodyTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: darkCardColor,
        elevation: 2,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
  }
}
