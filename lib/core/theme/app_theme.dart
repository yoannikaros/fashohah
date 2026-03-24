import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  // Primary — teal-green modern
  static const primary = Color(0xFF1DB589);
  static const primaryDim = Color(0xFF0F9A72);

  // Accent
  static const gold = Color(0xFFE8A020);

  // Light surfaces
  static const bgLight = Color(0xFFF5F5F7);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceElevatedLight = Color(0xFFFFFFFF);
  static const outlineLight = Color(0xFFE5E5EA);
  static const labelSecondaryLight = Color(0xFF8E8E93);

  // Dark surfaces
  static const bgDark = Color(0xFF0D0D0F);
  static const surfaceDark = Color(0xFF1C1C1E);
  static const surfaceElevatedDark = Color(0xFF2C2C2E);
  static const outlineDark = Color(0xFF38383A);
  static const labelSecondaryDark = Color(0xFF8E8E93);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD4F5EC),
      onPrimaryContainer: Color(0xFF00382A),
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFEDD5),
      onSecondaryContainer: Color(0xFF3A2000),
      surface: AppColors.surfaceLight,
      onSurface: Color(0xFF1C1C1E),
      surfaceContainerLow: AppColors.bgLight,
      surfaceContainerHigh: Color(0xFFEBEBED),
      outline: AppColors.outlineLight,
      outlineVariant: Color(0xFFD1D1D6),
      error: Color(0xFFFF3B30),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgLight,
        foregroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineLight,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: Color(0xFF1C1C1E),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1C1C1E),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF1C1C1E),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF1C1C1E),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: Color(0xFF1C1C1E)),
        bodyMedium: TextStyle(color: AppColors.labelSecondaryLight),
        bodySmall: TextStyle(color: AppColors.labelSecondaryLight),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF005140),
      onPrimaryContainer: Color(0xFF9CF5DA),
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF4A2E00),
      onSecondaryContainer: Color(0xFFFFDDAD),
      surface: AppColors.surfaceDark,
      onSurface: Colors.white,
      surfaceContainerLow: AppColors.bgDark,
      surfaceContainerHigh: AppColors.surfaceElevatedDark,
      outline: AppColors.outlineDark,
      outlineVariant: Color(0xFF48484A),
      error: Color(0xFFFF453A),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineDark,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: AppColors.labelSecondaryDark),
        bodySmall: TextStyle(color: AppColors.labelSecondaryDark),
      ),
    );
  }
}
