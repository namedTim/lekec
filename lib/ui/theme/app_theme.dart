import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: const Color(0xFF064E3B),

        secondary: AppColors.primaryDark,
        onSecondary: Colors.white,

        background: AppColors.backgroundLight,
        onBackground: AppColors.textPrimaryLight,

        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,

        surfaceVariant: const Color(0xFFD0D4D0),
        onSurfaceVariant: const Color(0xFF374151),

        error: AppColors.error,
        onError: Colors.white,

        outline: AppColors.outlineLight,
      ),

      scaffoldBackgroundColor: AppColors.backgroundLight,

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundLight,
        height: 64,

        // 🔥 STRONG active indicator
        indicatorColor: const Color.fromARGB(87, 8, 211, 35),

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color.fromARGB(255, 12, 160, 56),
            );
          }
          return const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Color(0xFF6B7280),
          );
        }),

        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 26);
          }
          return const IconThemeData(color: Color(0xFF6B7280));
        }),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryLight, // brighter green pops on dark
        onPrimary: Colors.black,

        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: Colors.white,

        secondary: AppColors.primary,
        onSecondary: Colors.black,

        background: AppColors.backgroundDark,
        onBackground: AppColors.textPrimaryDark,

        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,

        surfaceVariant: const Color(0xFF2A2A2A),
        onSurfaceVariant: const Color(0xFF9CA3AF),

        error: AppColors.error,
        onError: Colors.black,

        outline: AppColors.outlineDark,
      ),

      scaffoldBackgroundColor: AppColors.backgroundDark,

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        height: 64,
        indicatorColor: AppColors.primary.withOpacity(0.35),

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: AppColors.primaryLight,
            );
          }
          return const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Color(0xFF9CA3AF),
          );
        }),

        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: AppColors.primaryLight),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
