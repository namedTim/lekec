import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmPermissions {
  static final _log = Logger('AlarmPermissions');
  static const _platform = MethodChannel('com.lekec/lockscreen');

  static Future<void> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      _log.info('Requesting notification permission...');
      final res = await Permission.notification.request();
      _log.info(
        'Notification permission ${res.isGranted ? '' : 'not '}granted',
      );
    }
  }

  static Future<void> checkAndroidExternalStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      _log.info('Requesting external storage permission...');
      final res = await Permission.storage.request();
      _log.info(
        'External storage permission ${res.isGranted ? '' : 'not'} granted',
      );
    }
  }

  static Future<void> checkAndroidScheduleExactAlarmPermission() async {
    if (!Alarm.android) return;
    final status = await Permission.scheduleExactAlarm.status;
    _log.info('Schedule exact alarm permission: $status.');
    if (status.isDenied) {
      _log.info('Requesting schedule exact alarm permission...');
      final res = await Permission.scheduleExactAlarm.request();
      _log.info(
        'Schedule exact alarm permission ${res.isGranted ? '' : 'not'} granted',
      );
    }
  }

  /// On Android 14+ (API 34) `USE_FULL_SCREEN_INTENT` was demoted to an
  /// app-op the user has to grant manually. Without it, the alarm plugin's
  /// notification with `setFullScreenIntent(...)` silently degrades to a
  /// regular heads-up: the alarm rings but the ring screen never launches
  /// over the lock screen.
  ///
  /// This permission also resets if the `applicationId` changes — which is
  /// what bit us when the package was renamed to `si.lekec.app`. Detect the
  /// missing grant and route the user to the right settings page.
  static Future<void> checkFullScreenIntentPermission() async {
    if (!Alarm.android) return;
    try {
      final allowed =
          await _platform.invokeMethod<bool>('canUseFullScreenIntent') ?? true;
      _log.info('Full-screen intent allowed: $allowed.');
      if (!allowed) {
        _log.info('Opening full-screen intent settings…');
        await _platform.invokeMethod('openFullScreenIntentSettings');
      }
    } catch (e) {
      _log.warning('Full-screen intent check failed: $e');
    }
  }

  /// Asks the OS to whitelist the app from battery optimisation / Doze.
  /// Without this, OEMs (Samsung, Xiaomi, Huawei, Oppo, OnePlus) frequently
  /// drop scheduled alarms after a reboot or kill the app's BootReceiver
  /// before it can reschedule them.
  ///
  /// This handles the standard Android side. It does NOT cover OEM-specific
  /// "autostart" toggles (e.g. MIUI Security → Autostart) — those have no
  /// public API and the user has to enable them manually.
  static Future<void> checkIgnoreBatteryOptimizations() async {
    if (!Alarm.android) return;
    final status = await Permission.ignoreBatteryOptimizations.status;
    _log.info('Ignore battery optimizations: $status.');
    if (status.isDenied) {
      _log.info('Requesting ignore battery optimizations…');
      final res = await Permission.ignoreBatteryOptimizations.request();
      _log.info(
        'Ignore battery optimizations ${res.isGranted ? '' : 'not '}granted',
      );
    }
  }
}
