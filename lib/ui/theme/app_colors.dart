import 'package:flutter/material.dart';

class AppColors {
  // Brand greens
  static const Color primary = Color.fromARGB(255, 31, 191, 31);       // main brand green
  static const Color primaryDark = Color.fromARGB(255, 23, 158, 46);   // dark container
  static const Color primaryLight = Color.fromARGB(255, 110, 231, 126);  // light container

  // Neutral surfaces (no blue tint)
  static const Color backgroundLight = Color(0xFFF6F7F6);
  static const Color surfaceLight = Color(0xFFE3E5E3);

  static const Color backgroundDark = Color(0xFF141414);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimaryLight = Color(0xFF1F2933);
  static const Color textPrimaryDark = Color(0xFFE5E7EB);

  // Outline / dividers
  static const Color outlineLight = Color(0xFFB0B6B2);
  static const Color outlineDark = Color(0xFF3A3A3A);

  // Error
  static const Color error = Color(0xFFD32F2F);
}
