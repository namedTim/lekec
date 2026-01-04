import 'package:drift/drift.dart' show ComparableExpr, OrderingTerm;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:developer' as developer;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart' show MedicationType;
import '../../ui/screens/medication_frequency_selection.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Ljubljana'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
    developer.log('Notification service initialized', name: 'NotificationService');
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}', name: 'NotificationService');
    // TODO: Navigate to specific medication or mark as taken
  }

  /// Schedule notification for a medication intake
  Future<void> scheduleIntakeNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    String? dosage,
  }) async {
    if (!_initialized) await initialize();

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    // Don't schedule if time is in the past
    if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      developer.log('Skipping past notification for $medicationName at $scheduledTime', 
        name: 'NotificationService');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
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

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = dosage != null 
        ? 'Vzemite $dosage'
        : 'Čas za jemanje zdravila';

    await _notifications.zonedSchedule(
      id,
      'Vzemite zdravilo $medicationName',
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: id.toString(),
    );

    developer.log(
      'Scheduled notification for $medicationName at $scheduledTime (ID: $id)',
      name: 'NotificationService',
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    developer.log('Cancelled notification $id', name: 'NotificationService');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    developer.log('Cancelled all notifications', name: 'NotificationService');
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Schedule notifications for all upcoming intakes
  Future<void> scheduleAllUpcomingNotifications(AppDatabase db) async {
    if (!_initialized) await initialize();

    // Cancel existing notifications first
    await cancelAllNotifications();

    // Get all upcoming intake entries (next 7 days to avoid scheduling too many)
    final now = DateTime.now();
    final weekAhead = now.add(const Duration(days: 7));

    final upcomingIntakes = await (db.select(db.medicationIntakeLogs)
      ..where((log) => log.scheduledTime.isBiggerThanValue(now))
      ..where((log) => log.scheduledTime.isSmallerThanValue(weekAhead))
      ..where((log) => log.wasTaken.equals(false))
      ..orderBy([(log) => OrderingTerm(expression: log.scheduledTime)]))
      .get();

    developer.log('Scheduling ${upcomingIntakes.length} notifications', 
      name: 'NotificationService');

    for (final intake in upcomingIntakes) {
      // Get medication details
      final medication = await (db.select(db.medications)
        ..where((m) => m.id.equals(intake.medicationId)))
        .getSingle();

      // Get plan details for dosage
      final plan = await (db.select(db.medicationPlans)
        ..where((p) => p.id.equals(intake.planId)))
        .getSingle();

      final dosage = plan.dosageAmount != null
          ? '${plan.dosageAmount!.toStringAsFixed(0)} ${_getMedicationTypeUnit(medication.medType)}'
          : null;

      await scheduleIntakeNotification(
        id: intake.id,
        medicationName: medication.name,
        scheduledTime: intake.scheduledTime,
        dosage: dosage,
      );
    }

    final count = await getPendingNotificationsCount();
    developer.log('Scheduled $count notifications successfully', 
      name: 'NotificationService');
  }

  String _getMedicationTypeUnit(MedicationType type) {
    switch (type) {
      case MedicationType.pills:
        return 'tableto/e';
      case MedicationType.capsules:
        return 'kapsulo/e';
      case MedicationType.drops:
        return 'kapljic/o';
      case MedicationType.milliliters:
        return 'ml';
      case MedicationType.grams:
        return 'g';
      case MedicationType.milligrams:
        return 'mg';
      case MedicationType.micrograms:
        return 'µg';
      case MedicationType.units:
        return 'enot/o';
      case MedicationType.puffs:
        return 'vpih/ov';
      case MedicationType.patches:
        return 'obliž/ev';
      case MedicationType.injections:
        return 'injekcijo/e';
      case MedicationType.ampules:
        return 'ampulo/e';
      case MedicationType.portions:
        return 'porcijo/e';
      case MedicationType.pieces:
        return 'kos/ov';
      case MedicationType.sprays:
        return 'pršil/o';
      case MedicationType.tablespoons:
        return 'žlico/e';
      case MedicationType.applications:
        return 'aplikacijo/e';
    }
  }
}
