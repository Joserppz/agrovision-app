import 'package:flutter/material.dart';
import 'constants.dart';

class AgroTheme {
  AgroTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AgroColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AgroColors.green,
      primary: AgroColors.green,
      secondary: AgroColors.yellow,
      surface: AgroColors.cream,
      error: AgroColors.red,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AgroColors.cream,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AgroColors.green),
      titleTextStyle: TextStyle(
        fontFamily: AgroText.fontDisplay,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AgroColors.green,
        letterSpacing: 0.5,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AgroColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: AgroText.fontBody,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AgroColors.green,
        side: const BorderSide(color: AgroColors.green, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: AgroText.fontBody,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: AgroColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AgroColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AgroColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AgroColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AgroColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AgroColors.green, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: AgroColors.textHint,
        fontFamily: AgroText.fontBody,
        fontSize: 14,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AgroColors.surface,
      selectedItemColor: AgroColors.green,
      unselectedItemColor: AgroColors.textHint,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: AgroText.fontBody,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: AgroText.fontBody,
        fontSize: 10,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: AgroText.fontDisplay,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AgroColors.green,
      ),
      displayMedium: TextStyle(
        fontFamily: AgroText.fontDisplay,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AgroColors.green,
      ),
      titleLarge: TextStyle(
        fontFamily: AgroText.fontDisplay,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AgroColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: AgroText.fontBody,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AgroColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: AgroText.fontBody,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AgroColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: AgroText.fontBody,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AgroColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: AgroText.fontBody,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        color: AgroColors.textHint,
      ),
    ),
  );
}
