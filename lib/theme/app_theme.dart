import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF9B3F2C);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: Color(0xFFE47B4D),
      surface: Color(0xFFFFFCF8),
      onSurface: Color(0xFF30201B),
      surfaceContainerHighest: Color(0xFFF6E8DD),
    ),

    scaffoldBackgroundColor: const Color(0xFFFFF7F0),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFF7F0),
      foregroundColor: Color(0xFF30201B),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      color: Color(0xFFFFFCF8),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF0DCCE), width: 1),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFB59B),
      onPrimary: Color(0xFF42190F),
      secondary: Color(0xFFFFC972),
      surface: Color(0xFF241916),
      onSurface: Color(0xFFFFEDE4),
      surfaceContainerHighest: Color(0xFF382724),
    ),

    scaffoldBackgroundColor: const Color(0xFF1D1513),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1D1513),
      foregroundColor: Color(0xFFFFEDE4),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF241916),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF503A34), width: 1),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFFB59B),
        foregroundColor: Color(0xFF42190F),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
