import 'package:flutter/material.dart';

class AppColors {
  // Brand greens — aligned with Tailwind green palette so accents
  // (next-medication border, take-button, appointment chips, etc.) match.
  static const Color primary = Color(0xFF22C55E); // green-500
  static const Color primaryDark = Color(0xFF15803D); // green-700
  static const Color primaryLight = Color(0xFFBBF7D0); // green-200

  // Neutral surfaces (no blue tint)
  static const Color backgroundLight = Color(0xFFFAFAF8);
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
