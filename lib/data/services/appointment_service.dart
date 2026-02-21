import 'dart:developer' as developer;
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
  static const int _notifIdOffset = 900000;

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
        id: _notifIdOffset + appointmentId * 2,
        title: 'Termin jutri: $title',
        body: _formatBody(appointmentTime),
        scheduledTime: oneDayBefore,
        payload: 'appointment_$appointmentId',
      );
    }

    // --- 2 hours before: full-screen / silent notification ---
    final twoHoursBefore = appointmentTime.subtract(const Duration(hours: 2));
    if (twoHoursBefore.isAfter(now)) {
      await _scheduleFullScreenSilentNotification(
        id: _notifIdOffset + appointmentId * 2 + 1,
        title: 'Termin čez 2 uri: $title',
        body: _formatBody(appointmentTime),
        scheduledTime: twoHoursBefore,
        payload: 'appointment_$appointmentId',
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

  /// Full-screen intent notification with **no sound and no vibration**.
  /// The user will see a persistent heads-up card when they unlock / look at
  /// their phone — no noise, no buzz.
  Future<void> _scheduleFullScreenSilentNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'appointment_fullscreen',
      'Termini – tiho opozorilo',
      channelDescription: 'Tiho celozaslonsko opozorilo 2 uri pred terminom',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
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
        'Scheduled full-screen silent notification $id at $scheduledTime',
        name: 'AppointmentService',
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule full-screen notification',
        error: e,
        stackTrace: st,
        name: 'AppointmentService',
      );
    }
  }

  /// Cancel both notifications for a given appointment.
  Future<void> _cancelNotifications(int appointmentId) async {
    await _notifications.cancel(_notifIdOffset + appointmentId * 2);
    await _notifications.cancel(_notifIdOffset + appointmentId * 2 + 1);
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
