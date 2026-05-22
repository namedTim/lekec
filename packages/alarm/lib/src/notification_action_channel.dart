import 'package:alarm/model/notification_action_event.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

/// Plain [MethodChannel] used to drain notification action button taps from
/// the native side.
///
/// **Fork addition.** This is intentionally separate from the Pigeon-generated
/// API so it can be added without regenerating the platform bindings. The
/// matching native handler lives in `AlarmPlugin.kt`.
const MethodChannel _channel =
    MethodChannel('com.gdelataillade.alarm/notification_action');

final Logger _log = Logger('Alarm.NotificationAction');

/// Returns every pending notification action tap and clears the native queue.
///
/// Pending taps are persisted natively, so this returns taps that happened
/// while the app was killed too. Safe to call repeatedly — each tap is
/// returned exactly once.
Future<List<NotificationActionEvent>> consumePendingNotificationActions() async {
  try {
    final raw = await _channel
        .invokeListMethod<Map<Object?, Object?>>('consumePendingActions');
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .map(
          (m) => NotificationActionEvent(
            alarmId: (m['alarmId'] as num).toInt(),
            actionId: (m['actionId'] as String?) ?? '',
          ),
        )
        .toList(growable: false);
  } catch (e, st) {
    _log.warning('Failed to consume pending notification actions', e, st);
    return const [];
  }
}
