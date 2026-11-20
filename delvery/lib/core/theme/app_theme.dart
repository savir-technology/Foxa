import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _background = Color(0xFFFFFFFF);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFFFF8F3);
  static const Color _line = Color(0xFFEEEEEE);
  static const Color _accent = Color(0xFFFF6500);
  static const Color _warning = Color(0xFFE8A83C);
  static const Color _danger = Color(0xFFD64545);
  static const Color _text = Color(0xFF171717);
  static const Color _textMuted = Color(0xFF6D6D6D);

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
      surface: _surface,
    ).copyWith(primary: _accent, secondary: _accent, error: _danger);

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldColor: _background,
      surfaceColor: _surface,
      surfaceAltColor: _surfaceAlt,
      lineColor: _line,
      textColor: _text,
      mutedTextColor: _textMuted,
    );
  }

  static ThemeData darkTheme() {
    const darkBackground = Color(0xFF0F1110);
    const darkSurface = Color(0xFF171A18);
    const darkSurfaceAlt = Color(0xFF211C19);
    const darkLine = Color(0xFF2A2F2B);
    const darkText = Color(0xFFF5F5F5);
    const darkMuted = Color(0xFFB2B2B2);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.dark,
          surface: darkSurface,
        ).copyWith(
          primary: _accent,
          secondary: _warning,
          error: _danger,
          surface: darkSurface,
          onSurface: darkText,
        );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldColor: darkBackground,
      surfaceColor: darkSurface,
      surfaceAltColor: darkSurfaceAlt,
      lineColor: darkLine,
      textColor: darkText,
      mutedTextColor: darkMuted,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldColor,
    required Color surfaceColor,
    required Color surfaceAltColor,
    required Color lineColor,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    final textTheme = GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.08,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.08,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 12,
        color: textColor.withValues(alpha: 0.9),
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 11,
        color: mutedTextColor,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.cairo(fontSize: 10, color: mutedTextColor),
      labelLarge: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: colorScheme.onPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,
      cardColor: surfaceColor,
      dividerColor: lineColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAltColor,
        hintStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: lineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: lineColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: lineColor),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAltColor,
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.bodyMedium,
        side: BorderSide(color: lineColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        modalBackgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.20),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
