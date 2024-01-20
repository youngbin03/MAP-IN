import 'package:flutter/material.dart';

class ThemeProvider {
  static ThemeData _createTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color primaryBackgroundColor,
    required Color secondaryBackgroundColor,
    required Color primary,
    required Color secondary,
    required Color splashColor,
  }) {
    final baseTheme = ThemeData(
      fontFamily: 'Pretendard',
      useMaterial3: true,
    );

    return baseTheme.copyWith(
      brightness: brightness,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: backgroundColor, // License Page Background
      textTheme: TextTheme(
        labelSmall: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        displayLarge: TextStyle(color: primary),
        displayMedium: TextStyle(color: primary),
        displaySmall: TextStyle(color: primary),
        headlineMedium: TextStyle(color: primary),
        headlineSmall: TextStyle(color: primary),
        titleLarge: TextStyle(color: primary),
        titleMedium: TextStyle(color: primary),
        bodyLarge: TextStyle(color: primary),
        bodyMedium: TextStyle(color: primary),
        bodySmall: TextStyle(color: primary),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryBackgroundColor,
        onPrimary: primary,
        secondary: secondaryBackgroundColor,
        onSecondary: secondary,
        error: primary,
        onError: primary,
        background: backgroundColor,
        onBackground: primary,
        surface: backgroundColor,
        onSurface: secondary,
      ),
      highlightColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: secondary.withOpacity(0.6),
        thickness: 1,
      ),
      splashColor: splashColor,
    );
  }

  static ThemeData get lightTheme => _createTheme(
        brightness: Brightness.light,
        backgroundColor: const Color(0xfff3f3f3),
        primaryBackgroundColor: const Color(0xffffffff),
        secondaryBackgroundColor: const Color(0xFFDDDDDD),
        primary: const Color(0xff000000),
        secondary: const Color(0xFF525252),
        splashColor: Colors.transparent,
      );

  static ThemeData get darkTheme => _createTheme(
        brightness: Brightness.dark,
        backgroundColor: const Color(0xFF16151A),
        primaryBackgroundColor: const Color(0xff1d1e26),
        secondaryBackgroundColor: const Color(0xff2f3138),
        primary: Colors.white,
        secondary: const Color(0xFF98989F),
        splashColor: Colors.transparent,
      );
}
