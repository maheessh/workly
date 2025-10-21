import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORS ---
  static const Color primaryColor = Color(0xFF3A86FF); // A vibrant, modern blue
  static const Color secondaryColor = Color(0xFF50C878); // A friendly green
  static const Color backgroundColor = Color(0xFFF9F9F9); // A slightly off-white, clean background
  static const Color textColor = Color(0xFF1A1A1A); // Dark, readable text
  static const Color subTextColor = Color(0xFF6E6E6E); // For subheadings and descriptions

  // --- TEXT STYLES ---
  static const TextTheme _textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, color: textColor),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: textColor),
    titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: textColor),
    bodyLarge: TextStyle(fontSize: 16.0, color: subTextColor, height: 1.4),
    bodyMedium: TextStyle(fontSize: 14.0, color: subTextColor),
    labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
  );

  // --- MAIN THEME ---
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Roboto',
    textTheme: _textTheme,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
        .copyWith(
          primary: primaryColor,
          secondary: secondaryColor,
          background: backgroundColor
        ),
    
    // --- AppBar Theme ---
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textColor),
      titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Roboto'),
    ),

    // --- Input Field Theme ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),

    // --- Button Themes ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill shape
        textStyle: _textTheme.labelLarge,
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.3),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill shape
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    
    // --- Card Theme ---
    
  );
}