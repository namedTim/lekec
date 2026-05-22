import 'dart:developer' as developer;
import 'package:alarm/alarm.dart';
import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../database/drift_database.dart';

class AppointmentService {
  final AppDatabase db;

  AppointmentService(this.db);

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification ID offset to avoid collisions with medication notifications.
  // Medication intake IDs are typically small (auto-increment from 1).
  // We offset appointment notification IDs by 900000 to avoid any overlap.
  static const int notifIdOffset = 900000;

  /// Check if an alarm ID belongs to an appointment (2h-before alarm).
  static bool isAppointmentAlarm(int alarmId) {
    return alarmId >= notifIdOffset;
  }

  /// Extract the appointment ID from an alarm ID.
  static int appointmentIdFromAlarm(int alarmId) {
    return (alarmId - notifIdOffset - 1) ~/ 2;
  }

  /// Create a new appointment and schedule its notifications.
  Future<int> createAppointment({
    required int userId,
    required String title,
    String? note,
    required DateTime appointmentTime,
    bool criticalReminder = false,
    int reminderMinutesBefore = 120,
  }) async {
    final id = await db.into(db.appointments).insert(
      AppointmentsCompanion(
        userId: Value(userId),
        title: Value(title),
        note: Value(note),
        appointmentTime: Value(appointmentTime),
        criticalReminder: Value(criticalReminder),
        reminderMinutesBefore: Value(reminderMinutesBefore),
      ),
    );

    developer.log(
      'Created appointment $id: "$title" at $appointmentTime '
      '(critical: $criticalReminder, reminder: ${reminderMinutesBefore}m before)',
      name: 'AppointmentService',
    );

    await _scheduleNotifications(
      id,
      title,
      appointmentTime,
      criticalReminder,
      reminderMinutesBefore,
    );
    return id;
  }

  /// Update an existing appointment and reschedule its notifications.
  Future<void> updateAppointment({
    required int id,
    required String title,
    String? note,
    required DateTime appointmentTime,
    bool criticalReminder = false,
    int reminderMinutesBefore = 120,
  }) async {
    await (db.update(db.appointments)..where((t) => t.id.equals(id))).write(
      AppointmentsCompanion(
        title: Value(title),
        note: Value(note),
        appointmentTime: Value(appointmentTime),
        criticalReminder: Value(criticalReminder),
        reminderMinutesBefore: Value(reminderMinutesBefore),
      ),
    );

    developer.log(
      'Updated appointment $id: "$title" at $appointmentTime '
      '(critical: $criticalReminder, reminder: ${reminderMinutesBefore}m before)',
      name: 'AppointmentService',
    );

    // Cancel old notifications and schedule new ones
    await _cancelNotifications(id);
    await _scheduleNotifications(
      id,
      title,
      appointmentTime,
      criticalReminder,
      reminderMinutesBefore,
    );
  }

  /// Delete an appointment and cancel its notifications.
  Future<void> deleteAppointment(int id) async {
    await _cancelNotifications(id);
    await (db.delete(db.appointments)..where((t) => t.id.equals(id))).go();

    developer.log('Deleted appointment $id', name: 'AppointmentService');
  }

  /// Get all future appointments ordered by time.
  Future<List<Appointment>> getUpcomingAppointments() async {
    return (db.select(db.appointments)
          ..where((t) => t.appointmentTime.isBiggerThanValue(DateTime.now()))
          ..orderBy([
            (t) => OrderingTerm.asc(t.appointmentTime),
          ]))
        .get();
  }

  /// Get all appointments for a specific user.
  Future<List<Appointment>> getAppointmentsForUser(int userId) async {
    return (db.select(db.appointments)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.appointmentTime),
          ]))
        .get();
  }

  /// Get a single appointment by ID.
  Future<Appointment?> getAppointment(int id) async {
    return (db.select(db.appointments)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // Notification scheduling
  // ---------------------------------------------------------------------------

  /// Schedules two notifications for an appointment:
  ///   1. A regular push notification **1 day before**.
  ///   2. A full-screen alarm **[reminderMinutesBefore] minutes before**.
  ///      When [criticalReminder] is true the alarm uses the critical alarm
  ///      settings (sound + vibration); otherwise it is silent.
  ///
  /// If [reminderMinutesBefore] is ≥ 1440 (24h) the second alarm is suppressed
  /// to avoid colliding with the day-before push notification.
  Future<void> _scheduleNotifications(
    int appointmentId,
    String title,
    DateTime appointmentTime,
    bool criticalReminder,
    int reminderMinutesBefore,
  ) async {
    final now = DateTime.now();

    // --- 1 day before: regular push notification ---
    final oneDayBefore = appointmentTime.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await _scheduleRegularNotification(
        id: notifIdOffset + appointmentId * 2,
        title: 'Termin jutri: $title',
        body: _formatBody(appointmentTime),
        scheduledTime: oneDayBefore,
        payload: 'appointment_$appointmentId',
      );
    }

    // --- [reminderMinutesBefore] before: full-screen alarm ---
    final alarmTime =
        appointmentTime.subtract(Duration(minutes: reminderMinutesBefore));
    if (alarmTime.isAfter(now) && reminderMinutesBefore < 1440) {
      await _scheduleFullScreenAlarm(
        appointmentId: appointmentId,
        title: title,
        appointmentTime: appointmentTime,
        scheduledTime: alarmTime,
        criticalReminder: criticalReminder,
        reminderMinutesBefore: reminderMinutesBefore,
      );
    }
  }

  /// Standard push notification (day-before reminder).
  Future<void> _scheduleRegularNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Opomniki za termine',
      channelDescription: 'Opomniki za prihajajoče termine',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      developer.log(
        'Scheduled day-before notification $id at $scheduledTime',
        name: 'AppointmentService',
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule day-before notification',
        error: e,
        stackTrace: st,
        name: 'AppointmentService',
      );
    }
  }

  /// Full-screen alarm using the Alarm package.
  /// When [criticalReminder] is true, the alarm uses the same sound / vibration
  /// / volume settings as medication critical alarms. Otherwise it is silent.
  Future<void> _scheduleFullScreenAlarm({
    required int appointmentId,
    required String title,
    required DateTime appointmentTime,
    required DateTime scheduledTime,
    required bool criticalReminder,
    required int reminderMinutesBefore,
  }) async {
    final alarmId = notifIdOffset + appointmentId * 2 + 1;

    String sound = '8bit_arcade.mp3';
    double volume = 0.0;
    bool vibrate = true;
    bool loop = false;

    if (criticalReminder) {
      // Use the shared critical alarm settings
      final settings = await (db.select(db.appSettings)..limit(1)).getSingleOrNull();
      sound = settings?.alarmSound ?? '8bit_arcade.mp3';
      volume = settings?.alarmVolume ?? 0.8;
      vibrate = settings?.alarmVibration ?? true;
      loop = true;
    }

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledTime,
      assetAudioPath: 'assets/alarms/$sound',
      loopAudio: loop,
      vibrate: vibrate,
      androidFullScreenIntent: true,
      warningNotificationOnKill: false,
      volumeSettings: VolumeSettings.fixed(volume: volume),
      notificationSettings: NotificationSettings(
        title: 'Termin ${formatRelativeOffset(reminderMinutesBefore)}: $title',
        body: _formatBody(appointmentTime),
        // iOS fallback — on Android the actionButton below takes over.
        stopButton: 'Ustavi alarm',
        icon: 'notification_icon',
        // A single acknowledge button for appointment reminders.
        actionButtons: const [
          NotificationActionButton(id: 'ack', text: 'Razumem'),
        ],
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
      developer.log(
        'Scheduled full-screen alarm $alarmId for appointment $appointmentId at $scheduledTime',
        name: 'AppointmentService',
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule full-screen alarm for appointment',
        error: e,
        stackTrace: st,
        name: 'AppointmentService',
      );
    }
  }

  /// Cancel both notifications for a given appointment.
  Future<void> _cancelNotifications(int appointmentId) async {
    // Cancel the day-before push notification
    await _notifications.cancel(notifIdOffset + appointmentId * 2);

    // Cancel the 2h-before full-screen alarm
    final alarmId = notifIdOffset + appointmentId * 2 + 1;
    try {
      await Alarm.stop(alarmId);
    } catch (_) {
      // Alarm may not exist if it already fired or wasn't scheduled
    }

    developer.log(
      'Cancelled notifications for appointment $appointmentId',
      name: 'AppointmentService',
    );
  }

  /// Reschedule notifications for **all** upcoming appointments.
  /// Useful after app restart / background service refresh.
  Future<void> rescheduleAll() async {
    final upcoming = await getUpcomingAppointments();
    for (final appt in upcoming) {
      await _cancelNotifications(appt.id);
      await _scheduleNotifications(
        appt.id,
        appt.title,
        appt.appointmentTime,
        appt.criticalReminder,
        appt.reminderMinutesBefore,
      );
    }
    developer.log(
      'Rescheduled notifications for ${upcoming.length} appointments',
      name: 'AppointmentService',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatBody(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.${dt.year} ob $hour:$minute';
  }
}

/// Slovenian "čez X" / "X prej" phrase for the alarm offset.
/// E.g., 30 → "čez 30 minut", 120 → "čez 2 uri", 1440 → "čez 1 dan".
String formatRelativeOffset(int minutes) {
  if (minutes < 60) {
    return 'čez $minutes ${_minutesWord(minutes)}';
  }
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    if (hours >= 24 && hours % 24 == 0) {
      final days = hours ~/ 24;
      return 'čez $days ${_daysWord(days)}';
    }
    return 'čez $hours ${_hoursWord(hours)}';
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return 'čez $hours ${_hoursWord(hours)} $mins ${_minutesWord(mins)}';
}

String _minutesWord(int n) {
  if (n == 1) return 'minuto';
  if (n == 2) return 'minuti';
  if (n == 3 || n == 4) return 'minute';
  return 'minut';
}

String _hoursWord(int n) {
  if (n == 1) return 'uro';
  if (n == 2) return 'uri';
  if (n == 3 || n == 4) return 'ure';
  return 'ur';
}

String _daysWord(int n) {
  if (n == 1) return 'dan';
  if (n == 2) return 'dneva';
  if (n == 3 || n == 4) return 'dni';
  return 'dni';
}
