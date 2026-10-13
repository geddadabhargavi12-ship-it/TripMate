import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color deepTeal = Color(0xFF0F766E);
  static const Color turquoise = Color(0xFF14B8A6);
  static const Color ivory = Color(0xFFF5F1EB);
  static const Color darkBackground = Color(0xFF0F172A);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: deepTeal,
      brightness: Brightness.light,
      primary: deepTeal,
      secondary: turquoise,
      surface: ivory,
    ),
    scaffoldBackgroundColor: ivory,
    textTheme: GoogleFonts.manropeTextTheme().copyWith(
      headlineLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800),
      titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.manrope(fontWeight: FontWeight.w500),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: deepTeal,
      brightness: Brightness.dark,
      primary: turquoise,
      secondary: deepTeal,
    ),
    scaffoldBackgroundColor: darkBackground,
    textTheme: GoogleFonts.manropeTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
  );
}
