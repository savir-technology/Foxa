import 'package:flutter/material.dart';

class AppTheme {
  static const Color _brandOrange = Color(0xFFFF6500);
  static const Color _brandOrangeDeep = Color(0xFFE34F00);
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceAlt = Color(0xFFFFF3EC);
  static const Color _darkBackground = Color(0xFF0B0B0B);
  static const Color _darkSurface = Color(0xFF151515);
  static const Color _darkSurfaceAlt = Color(0xFF222222);
  static const Color _lightPrimary = _brandOrange;
  static const Color _darkPrimary = Color(0xFFFF761A);
  static const Color _accentRed = Color(0xFFD34D4D);

  static ThemeData lightTheme({bool isArabic = false}) {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _lightPrimary,
      onPrimary: Colors.white,
      secondary: _brandOrangeDeep,
      onSecondary: Colors.white,
      error: _accentRed,
      onError: Colors.white,
      surface: _lightSurface,
      onSurface: Color(0xFF171717),
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: _lightBackground,
      cardColor: _lightSurface,
      dividerColor: const Color(0xFFF0D8CA),
      shadowColor: const Color(0x12000000),
      inputFillColor: _lightSurfaceAlt,
      tintColor: _lightSurfaceAlt,
      isArabic: isArabic,
    );
  }

  static ThemeData darkTheme({bool isArabic = false}) {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: Colors.black,
      secondary: _brandOrange,
      onSecondary: Colors.white,
      error: _accentRed,
      onError: Colors.white,
      surface: _darkSurface,
      onSurface: Color(0xFFF7F7F7),
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: _darkBackground,
      cardColor: _darkSurface,
      dividerColor: const Color(0xFF343434),
      shadowColor: const Color(0x66000000),
      inputFillColor: _darkSurfaceAlt,
      tintColor: _darkSurfaceAlt,
      isArabic: isArabic,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color dividerColor,
    required Color shadowColor,
    required Color inputFillColor,
    required Color tintColor,
    required bool isArabic,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final bodyFont = isArabic ? 'jeebArabic' : 'catfont';
    final headingFont = isArabic ? 'jeebArabic' : 'myfont';
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardColor,
      shadowColor: shadowColor,
      dividerColor: dividerColor,
      fontFamily: bodyFont,
    );

    final textTheme =
        ThemeData(brightness: colorScheme.brightness).textTheme.copyWith(
              displayLarge: TextStyle(
                fontFamily: headingFont,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                height: 1.05,
              ),
              displayMedium: TextStyle(
                fontFamily: headingFont,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                height: 1.08,
              ),
              headlineLarge: TextStyle(
                fontFamily: headingFont,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              headlineMedium: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              headlineSmall: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              titleLarge: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              titleMedium: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              bodyLarge: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface.withValues(alpha: 0.90),
                height: 1.55,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.5,
              ),
              bodySmall: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.62),
                height: 1.35,
              ),
              labelLarge: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
              ),
            );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colorScheme.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: dividerColor.withValues(alpha: 0.72)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: dividerColor),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? tintColor : const Color(0xFFFFF3EC),
        selectedColor: isDark
            ? const Color(0xFF3A2419)
            : colorScheme.primary.withValues(alpha: 0.12),
        side: BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: textTheme.bodyMedium,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        modalBackgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.56),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      splashColor:
          colorScheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.05),
      highlightColor:
          colorScheme.onSurface.withValues(alpha: isDark ? 0.06 : 0.03),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.secondary,
        selectionColor: colorScheme.secondary.withValues(alpha: 0.18),
        selectionHandleColor: colorScheme.secondary,
      ),
    );
  }
}
