import 'package:flutter/material.dart';

const _userPalette = <Color>[
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFFF59E0B), // Amber
  Color(0xFF06B6D4), // Cyan
  Color(0xFF22C55E), // Green
  Color(0xFF0EA5E9), // Sky
  Color(0xFFA855F7), // Purple
  Color(0xFF14B8A6), // Teal
  Color(0xFFF97316), // Orange
  Color(0xFF10B981), // Emerald
  Color(0xFFEAB308), // Yellow
];

Color getUserColor({int? userId, String? name}) {
  if (userId != null) {
    return _userPalette[userId.abs() % _userPalette.length];
  }
  if (name != null && name.isNotEmpty) {
    var hash = 0;
    for (final code in name.codeUnits) {
      hash = (hash * 31 + code) & 0x7FFFFFFF;
    }
    return _userPalette[hash % _userPalette.length];
  }
  return _userPalette[0];
}
