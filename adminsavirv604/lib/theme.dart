import 'package:flutter/material.dart';

const Color kBackground = Color(0xFFFFF8F3);
const Color kSurface = Color(0xFFFFFFFF);
const Color kSurfaceElevated = Color(0xFFFFF0E6);
const Color kGlass = Color(0xCCFFFFFF);
const Color kPrimary = Color(0xFFFF6500);
const Color kSecondary = Color(0xFFE34F00);
const Color kAccent = Color(0xFFFF8A3D);
const Color kGlow = Color(0xFFFFDCC7);
const Color kTextPrimary = Color(0xFF111827);
const Color kTextSecondary = Color(0xFF60707A);
const Color kStroke = Color(0xFFF0D8CA);
const double kBorderRadius = 22.0;
const double kGlassBlur = 16.0;

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
    primary: kPrimary,
    secondary: kSecondary,
    surface: kSurface,
    error: const Color(0xFFDC2626),
  );
  final baseTextTheme = ThemeData.light().textTheme.apply(fontFamily: 'Cairo');

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: kBackground,
    canvasColor: kSurface,
    cardColor: kSurface,
    dividerColor: kStroke,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: kTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 56,
    ),
    iconTheme: const IconThemeData(color: kTextPrimary),
    textTheme: baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: kTextPrimary,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.08,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: kTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: kTextPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: kTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: kTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: kTextSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: kTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        side: const BorderSide(color: kStroke),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        side: const BorderSide(color: kStroke),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurfaceElevated,
      isDense: true,
      hintStyle: const TextStyle(
        color: kTextSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: const TextStyle(
        color: kTextSecondary,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: kPrimary,
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: kTextSecondary,
      suffixIconColor: kTextSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kStroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kStroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFFFF8F3),
      selectedColor: kPrimary.withValues(alpha: 0.12),
      disabledColor: const Color(0xFFF5EAE3),
      side: const BorderSide(color: kStroke),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelStyle: const TextStyle(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF111827),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kStroke),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: kStroke, width: 1.2),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kPrimary : null,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? kPrimary
            : const Color(0xFFD1D5DB),
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
