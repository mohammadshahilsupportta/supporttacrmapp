import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors from website
  static const Color primaryColor = Color(0xFF0F172A); // Dark slate blue
  static const Color lightBackground = Color(0xFFF8FAFC); // Very light gray
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  static const Color darkBackground = Color(0xFF0F172A); // Dark slate blue
  static const Color darkSurface = Color(0xFF1E293B); // Slightly lighter slate for dark theme surfaces

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: primaryColor.withOpacity(0.8),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: lightSurface,
      onSurface: primaryColor,
      onSurfaceVariant: primaryColor.withOpacity(0.7),
      background: lightBackground,
      onBackground: primaryColor,
      outline: primaryColor.withOpacity(0.2),
      shadow: primaryColor.withOpacity(0.1),
      // Surface container colors
      surfaceContainerHighest: lightSurface,
      surfaceContainerHigh: lightSurface,
      surfaceContainer: lightSurface,
      surfaceContainerLow: lightBackground,
      surfaceContainerLowest: lightBackground,
    ),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: lightSurface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: primaryColor,
      iconTheme: const IconThemeData(color: primaryColor),
      titleTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: lightSurface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.1)),
      ),
      fillColor: lightSurface,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    dividerTheme: DividerThemeData(
      color: primaryColor.withOpacity(0.1),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightBackground,
      selectedColor: primaryColor,
      labelStyle: TextStyle(color: primaryColor),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: primaryColor.withOpacity(0.2)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: lightBackground,
      onPrimary: primaryColor,
      secondary: lightBackground.withOpacity(0.8),
      onSecondary: primaryColor,
      error: Colors.red.shade300,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: lightBackground,
      onSurfaceVariant: lightBackground.withOpacity(0.7),
      background: darkBackground,
      onBackground: lightBackground,
      outline: lightBackground.withOpacity(0.3),
      shadow: Colors.black.withOpacity(0.3),
      // Surface container colors
      surfaceContainerHighest: darkSurface,
      surfaceContainerHigh: darkSurface,
      surfaceContainer: Color(0xFF1E293B),
      surfaceContainerLow: Color(0xFF0F172A),
      surfaceContainerLowest: Color(0xFF0A0F1A),
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: lightBackground,
      iconTheme: const IconThemeData(color: lightBackground),
      titleTextStyle: const TextStyle(
        color: lightBackground,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightBackground.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightBackground.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightBackground, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightBackground.withOpacity(0.1)),
      ),
      fillColor: darkSurface,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightBackground,
        foregroundColor: primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightBackground,
        side: BorderSide(color: lightBackground),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightBackground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightBackground,
      foregroundColor: primaryColor,
      elevation: 2,
    ),
    dividerTheme: DividerThemeData(
      color: lightBackground.withOpacity(0.1),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurface,
      selectedColor: lightBackground,
      labelStyle: TextStyle(color: lightBackground),
      secondaryLabelStyle: TextStyle(color: primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: lightBackground.withOpacity(0.3)),
      ),
    ),
  );
}
