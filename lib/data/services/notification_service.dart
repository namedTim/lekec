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

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'medication_reminders',
      'Opomniki za zdravila',
      description: 'Opomniki za jemanje zdravil',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Create the notification channel
      await androidPlugin.createNotificationChannel(androidChannel);
      developer.log('Created Android notification channel', name: 'NotificationService');
    }

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
      // Request notification permission
      final granted = await androidPlugin.requestNotificationsPermission();
      developer.log('Notification permission granted: $granted', name: 'NotificationService');
      
      // Request exact alarm permission for Android 12+
      final exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
      developer.log('Exact alarm permission granted: $exactAlarmGranted', name: 'NotificationService');
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
    final tzNow = tz.TZDateTime.now(tz.local);
    
    developer.log('Scheduling notification ID $id for $medicationName', name: 'NotificationService');
    developer.log('  Scheduled time: $tzScheduledTime', name: 'NotificationService');
    developer.log('  Current time: $tzNow', name: 'NotificationService');
    developer.log('  Is future: ${tzScheduledTime.isAfter(tzNow)}', name: 'NotificationService');
    
    // Don't schedule if time is in the past
    if (tzScheduledTime.isBefore(tzNow)) {
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

    try {
      await _notifications.zonedSchedule(
        id,
        'Vzemite $medicationName',
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: id.toString(),
      );

      developer.log(
        'Successfully scheduled notification for $medicationName at $scheduledTime (ID: $id)',
        name: 'NotificationService',
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule notification for $medicationName',
        error: e,
        stackTrace: st,
        name: 'NotificationService',
      );
    }
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

  /// Log all pending notifications to debug console
  Future<void> logPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    
    developer.log('=== PENDING NOTIFICATIONS (${pending.length}) ===', 
      name: 'NotificationService');
    
    for (final notification in pending) {
      developer.log(
        'ID: ${notification.id}, '
        'Title: ${notification.title}, '
        'Body: ${notification.body}, '
        'Payload: ${notification.payload}',
        name: 'NotificationService',
      );
    }
    
    developer.log('=== END PENDING NOTIFICATIONS ===', 
      name: 'NotificationService');
  }

  /// Check if exact alarm permission is granted (Android 12+)
  Future<bool> checkExactAlarmPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final canSchedule = await androidPlugin.canScheduleExactNotifications();
      developer.log('Can schedule exact alarms: $canSchedule', name: 'NotificationService');
      return canSchedule ?? false;
    }
    
    return false;
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
        .getSingleOrNull();

      // Skip if medication was deleted
      if (medication == null) {
        developer.log('Skipping intake ${intake.id}: medication ${intake.medicationId} not found', 
          name: 'NotificationService');
        continue;
      }

      // Get plan details for dosage
      final plan = await (db.select(db.medicationPlans)
        ..where((p) => p.id.equals(intake.planId)))
        .getSingleOrNull();

      // Skip if plan was deleted
      if (plan == null) {
        developer.log('Skipping intake ${intake.id}: plan ${intake.planId} not found', 
          name: 'NotificationService');
        continue;
      }

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

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

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

    await _notifications.show(
      999999,
      'Test obvestilo',
      'To je testno obvestilo za zdravila',
      notificationDetails,
    );

    developer.log('Showed test notification', name: 'NotificationService');
  }

  /// Schedule a test notification 10 seconds from now
  Future<void> scheduleTestNotification() async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 10));
    
    developer.log('Current time: $now', name: 'NotificationService');
    developer.log('Scheduling test notification for: $testTime', name: 'NotificationService');
    
    final tzNow = tz.TZDateTime.now(tz.local);
    final tzTestTime = tz.TZDateTime.from(testTime, tz.local);
    
    developer.log('TZ Current time: $tzNow', name: 'NotificationService');
    developer.log('TZ Test time: $tzTestTime', name: 'NotificationService');
    developer.log('Is test time in future? ${tzTestTime.isAfter(tzNow)}', name: 'NotificationService');
    developer.log('Difference in seconds: ${tzTestTime.difference(tzNow).inSeconds}', name: 'NotificationService');
    
    // Try direct scheduling without going through scheduleIntakeNotification
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      ticker: 'Test notification',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.zonedSchedule(
        999998,
        'Test obvestilo čez 10 sekund',
        'To bi moralo prikazati čez 10 sekund',
        tzTestTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      developer.log('✓ zonedSchedule call completed successfully', name: 'NotificationService');
      
      // Verify it was scheduled
      final pending = await _notifications.pendingNotificationRequests();
      final found = pending.any((n) => n.id == 999998);
      developer.log('Notification in pending list: $found', name: 'NotificationService');
      
    } catch (e, st) {
      developer.log('✗ Failed to schedule notification', error: e, stackTrace: st, name: 'NotificationService');
    }
  }

  /// Alternative test with basic scheduling (30 seconds)
  Future<void> scheduleBasicTestNotification() async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 30));
    
    // Create timezone-aware datetime
    final tzTestTime = tz.TZDateTime(
      tz.local,
      testTime.year,
      testTime.month,
      testTime.day,
      testTime.hour,
      testTime.minute,
      testTime.second,
    );
    
    developer.log('=== BASIC TEST NOTIFICATION (30s) ===', name: 'NotificationService');
    developer.log('Local time now: $now', name: 'NotificationService');
    developer.log('Will fire at: $testTime', name: 'NotificationService');
    developer.log('TZ time: $tzTestTime', name: 'NotificationService');
    developer.log('Seconds until fire: ${testTime.difference(now).inSeconds}', name: 'NotificationService');
    
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      ticker: 'Test after 30 seconds',
      fullScreenIntent: true,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.zonedSchedule(
        999997,
        'Test 30 sekund',
        'To obvestilo bi moralo priti čez 30 sekund',
        tzTestTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      developer.log('✓ Scheduled 30s test notification (ID: 999997)', name: 'NotificationService');
      
      // Check if it's in the queue
      final pending = await _notifications.pendingNotificationRequests();
      final found = pending.where((n) => n.id == 999997).toList();
      developer.log('Found in pending: ${found.isNotEmpty}', name: 'NotificationService');
      if (found.isNotEmpty) {
        developer.log('Pending notification: ${found.first}', name: 'NotificationService');
      }
      
    } catch (e, st) {
      developer.log('✗ Failed to schedule 30s test', error: e, stackTrace: st, name: 'NotificationService');
    }
  }

  /// Check all notification settings and permissions
  Future<Map<String, dynamic>> checkNotificationStatus() async {
    final status = <String, dynamic>{};
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      status['canScheduleExact'] = await androidPlugin.canScheduleExactNotifications() ?? false;
      status['notificationPermission'] = await androidPlugin.areNotificationsEnabled() ?? false;
      
      final pending = await _notifications.pendingNotificationRequests();
      status['pendingCount'] = pending.length;
      
      // Get active notifications
      final active = await _notifications.getActiveNotifications();
      status['activeCount'] = active.length;
    }
    
    status['initialized'] = _initialized;
    
    developer.log('=== NOTIFICATION STATUS ===', name: 'NotificationService');
    status.forEach((key, value) {
      developer.log('$key: $value', name: 'NotificationService');
    });
    developer.log('=== END STATUS ===', name: 'NotificationService');
    
    return status;
  }

  /// Schedule multiple test notifications at various intervals
  Future<void> scheduleMultipleTestNotifications() async {
    if (!_initialized) await initialize();

    final intervals = [
      1,    // 1 minute
      2,    // 2 minutes
      5,    // 5 minutes
      7,    // 7 minutes
      10,   // 10 minutes
      20,   // 20 minutes
      30,   // 30 minutes
      60,   // 1 hour
    ];

    developer.log('=== SCHEDULING MULTIPLE TEST NOTIFICATIONS ===', name: 'NotificationService');
    
    final now = DateTime.now();
    
    for (int i = 0; i < intervals.length; i++) {
      final minutes = intervals[i];
      final testTime = now.add(Duration(minutes: minutes));
      final tzTestTime = tz.TZDateTime(
        tz.local,
        testTime.year,
        testTime.month,
        testTime.day,
        testTime.hour,
        testTime.minute,
        testTime.second,
      );

      final timeLabel = minutes < 60 
          ? '$minutes min'
          : '${minutes ~/ 60} h';

      const androidDetails = AndroidNotificationDetails(
        'medication_reminders',
        'Opomniki za zdravila',
        channelDescription: 'Opomniki za jemanje zdravil',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      try {
        final notificationId = 990000 + i;
        await _notifications.zonedSchedule(
          notificationId,
          'Test obvestilo ($timeLabel)',
          'To obvestilo je bilo načrtovano za $timeLabel od zdaj',
          tzTestTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );

        developer.log('✓ Scheduled notification for $timeLabel (ID: $notificationId) at $testTime', 
          name: 'NotificationService');
      } catch (e, st) {
        developer.log('✗ Failed to schedule $timeLabel notification', 
          error: e, stackTrace: st, name: 'NotificationService');
      }
    }

    final pending = await _notifications.pendingNotificationRequests();
    developer.log('Total pending notifications after scheduling: ${pending.length}', 
      name: 'NotificationService');
    developer.log('=== END MULTIPLE TEST SCHEDULING ===', name: 'NotificationService');
  }
}
