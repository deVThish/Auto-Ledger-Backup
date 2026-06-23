import 'package:flutter/material.dart';

class AppTheme {
  static const Color policeBlue = Color(0xFF142C5C);
  static const Color policeBlueLight = Color(0xFF1A3A7A);
  static const Color policeBlueDark = Color(0xFF0D1F3D);

  static const Color primaryBlack = policeBlue;
  static const Color softBlack = Color(0xFF1F1F1F);

  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF4F4F4);
  static const Color borderGray = Color(0xFFD9D9D9);
  static const Color textGray = Color(0xFF666666);
  static const Color errorRed = Color(0xFFB00020);
  static const Color successGreen = Color(0xFF0B7A3B);
  static const Color inactiveColor = Color(0xFFA0AEC0); // Theme color for unselected tabs

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundWhite,
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: const ColorScheme.light(
      primary: policeBlue,
      secondary: policeBlueLight,
      surface: backgroundWhite,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: policeBlue,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundWhite,
      foregroundColor: policeBlue,
      surfaceTintColor: backgroundWhite,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: policeBlue),
    ),
    iconTheme: const IconThemeData(color: policeBlue),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: policeBlue,
      selectionColor: Color(0x22333333),
      selectionHandleColor: policeBlue,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: const TextStyle(color: textGray, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: textGray, fontWeight: FontWeight.w500),
      prefixIconColor: policeBlue,
      suffixIconColor: policeBlue,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: policeBlue, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: errorRed, width: 1.4),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: backgroundWhite,
      surfaceTintColor: backgroundWhite,
      headerBackgroundColor: policeBlue,
      headerForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: backgroundWhite,
      hourMinuteColor: lightGray,
      hourMinuteTextColor: policeBlue,
      dialHandColor: policeBlue,
      dialBackgroundColor: lightGray,
      dayPeriodColor: lightGray,
      dayPeriodTextColor: policeBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    ),
  );
}