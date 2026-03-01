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
  }) async {
    final id = await db.into(db.appointments).insert(
      AppointmentsCompanion(
        userId: Value(userId),
        title: Value(title),
        note: Value(note),
        appointmentTime: Value(appointmentTime),
      ),
    );

    developer.log(
      'Created appointment $id: "$title" at $appointmentTime',
      name: 'AppointmentService',
    );

    await _scheduleNotifications(id, title, appointmentTime);
    return id;
  }

  /// Update an existing appointment and reschedule its notifications.
  Future<void> updateAppointment({
    required int id,
    required String title,
    String? note,
    required DateTime appointmentTime,
  }) async {
    await (db.update(db.appointments)..where((t) => t.id.equals(id))).write(
      AppointmentsCompanion(
        title: Value(title),
        note: Value(note),
        appointmentTime: Value(appointmentTime),
      ),
    );

    developer.log(
      'Updated appointment $id: "$title" at $appointmentTime',
      name: 'AppointmentService',
    );

    // Cancel old notifications and schedule new ones
    await _cancelNotifications(id);
    await _scheduleNotifications(id, title, appointmentTime);
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
  ///   2. A silent full-screen notification **2 hours before** (no sound,
  ///      no vibration — the user sees it when they open the phone).
  Future<void> _scheduleNotifications(
    int appointmentId,
    String title,
    DateTime appointmentTime,
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

    // --- 2 hours before: full-screen alarm (silent, no vibration) ---
    final twoHoursBefore = appointmentTime.subtract(const Duration(hours: 2));
    if (twoHoursBefore.isAfter(now)) {
      await _scheduleFullScreenAlarm(
        appointmentId: appointmentId,
        title: title,
        appointmentTime: appointmentTime,
        scheduledTime: twoHoursBefore,
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
      icon: '@mipmap/ic_launcher',
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

  /// Full-screen alarm using the Alarm package — uses appointment reminder settings.
  /// This shows a full-screen intent (the AppointmentRingScreen) via the
  /// alarm service listener, just like medication critical alarms.
  Future<void> _scheduleFullScreenAlarm({
    required int appointmentId,
    required String title,
    required DateTime appointmentTime,
    required DateTime scheduledTime,
  }) async {
    final alarmId = notifIdOffset + appointmentId * 2 + 1;

    // Load appointment reminder settings from DB
    final settings = await (db.select(db.appSettings)..limit(1)).getSingleOrNull();
    final sound = settings?.appointmentSound ?? 'nokia.mp3';
    final volume = settings?.appointmentVolume ?? 0.5;
    final vibrate = settings?.appointmentVibration ?? true;

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledTime,
      assetAudioPath: 'assets/$sound',
      loopAudio: false,
      vibrate: vibrate,
      androidFullScreenIntent: true,
      warningNotificationOnKill: false,
      volumeSettings: VolumeSettings.fixed(volume: volume),
      notificationSettings: NotificationSettings(
        title: 'Termin čez 2 uri: $title',
        body: _formatBody(appointmentTime),
        stopButton: 'Opusti',
        icon: 'notification_icon',
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
      await _scheduleNotifications(appt.id, appt.title, appt.appointmentTime);
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
