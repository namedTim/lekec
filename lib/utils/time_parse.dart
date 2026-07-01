import 'package:flutter/material.dart';

/// Parses a "HH:MM" (24-hour) string into a [TimeOfDay].
///
/// Returns null for anything that isn't a valid time — malformed strings,
/// out-of-range hours/minutes, or nulls. Used to turn the AI-extracted
/// `suggestedTimes` into pickable times across the planning screens.
TimeOfDay? parseTimeOfDay(String? timeStr) {
  if (timeStr == null) return null;
  final parts = timeStr.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0].trim());
  final minute = int.tryParse(parts[1].trim());
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour >= 24 || minute < 0 || minute >= 60) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
