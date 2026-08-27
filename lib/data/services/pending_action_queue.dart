import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// An isolate-safe queue of medication notification action taps made on the
/// regular (non-critical) `flutter_local_notifications` reminders.
///
/// When the app is killed, `flutter_local_notifications` delivers an action
/// button tap on a short-lived background isolate. That isolate cannot safely
/// touch the app database, so the tap is parked here (in `SharedPreferences`)
/// and applied later by [NotificationActionService] from the main isolate.
///
/// Critical (alarm) reminders use a separate, native queue inside the forked
/// `alarm` package — see `Alarm.consumePendingNotificationActions()`.
class PendingActionQueue {
  PendingActionQueue._();

  static const _key = 'pending_med_notification_actions';

  /// Appends a tap to the queue.
  static Future<void> enqueue(int intakeId, String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    // Re-read from disk — the background isolate has its own in-memory cache.
    await prefs.reload();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.add(jsonEncode({'intakeId': intakeId, 'actionId': actionId}));
    await prefs.setStringList(_key, list);
  }

  /// Returns every queued tap and clears the queue.
  static Future<List<({int intakeId, String actionId})>> drain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = prefs.getStringList(_key) ?? <String>[];
    if (list.isEmpty) return const [];
    await prefs.remove(_key);

    final result = <({int intakeId, String actionId})>[];
    for (final raw in list) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        result.add((
          intakeId: (map['intakeId'] as num).toInt(),
          actionId: map['actionId'] as String,
        ));
      } catch (_) {
        // Skip malformed entries rather than losing the whole queue.
      }
    }
    return result;
  }
}

/// Sibling queue for water-reminder action button taps. Mirrors
/// [PendingActionQueue] but keyed by [userId] (water reminders are per-user
/// recurring notifications, not per-intake).
class WaterPendingActionQueue {
  WaterPendingActionQueue._();

  static const _key = 'pending_water_notification_actions';

  static Future<void> enqueue(int userId, String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.add(jsonEncode({'userId': userId, 'actionId': actionId}));
    await prefs.setStringList(_key, list);
  }

  static Future<List<({int userId, String actionId})>> drain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = prefs.getStringList(_key) ?? <String>[];
    if (list.isEmpty) return const [];
    await prefs.remove(_key);

    final result = <({int userId, String actionId})>[];
    for (final raw in list) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        result.add((
          userId: (map['userId'] as num).toInt(),
          actionId: map['actionId'] as String,
        ));
      } catch (_) {
        // Skip malformed entries rather than losing the whole queue.
      }
    }
    return result;
  }
}
