import 'dart:async';
import 'package:drift/drift.dart' show ComparableExpr, OrderingTerm;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:developer' as developer;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart' show MedicationStatus;
import '../../helpers/medication_unit_helper.dart';
import '../../main.dart' show homePageKey, rootNavigatorKey;
import 'package:go_router/go_router.dart';
import 'package:alarm/alarm.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> initialize() async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture!;
    final completer = Completer<void>();
    _initFuture = completer.future;
    try {
      await _doInitialize();
      completer.complete();
    } catch (e, st) {
      _initFuture = null;
      completer.completeError(e, st);
      rethrow;
    }
  }

  Future<void> _doInitialize() async {
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

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Create the notification channel
      await androidPlugin.createNotificationChannel(androidChannel);
      developer.log(
        'Created Android notification channel',
        name: 'NotificationService',
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
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

    // Permissions (notification, exact alarm, full-screen intent, battery
    // optimisation) are requested by the onboarding `PermissionsScreen` via
    // `AlarmPermissions`, so the user sees a primer first. Don't fire the
    // system dialogs here at app start.

    _initialized = true;
    developer.log(
      'Notification service initialized',
      name: 'NotificationService',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    developer.log(
      'Notification tapped: ${response.payload}',
      name: 'NotificationService',
    );

    // Parse intake ID from payload
    final intakeId = int.tryParse(response.payload ?? '');
    if (intakeId != null) {
      // Retry navigation with a delay in case the router isn't built yet
      // (e.g., cold-start from notification)
      _navigateToIntake(intakeId, retries: 5);
    }
  }

  void _navigateToIntake(int intakeId, {int retries = 5}) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      context.go('/');
      Future.delayed(const Duration(milliseconds: 300), () {
        homePageKey.currentState?.scrollToIntake(intakeId);
      });
      developer.log(
        'Navigated to home and scrolling to intake $intakeId',
        name: 'NotificationService',
      );
    } else if (retries > 0) {
      // Router not ready yet, retry after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToIntake(intakeId, retries: retries - 1);
      });
    }
  }

  /// Get medication details for an intake (used by alarm screen)
  Future<Map<String, dynamic>?> getMedicationDetailsForIntake(
    int intakeId,
    AppDatabase db,
  ) async {
    final intake = await (db.select(
      db.medicationIntakeLogs,
    )..where((log) => log.id.equals(intakeId))).getSingleOrNull();

    if (intake == null) return null;

    final medication = await (db.select(
      db.medications,
    )..where((m) => m.id.equals(intake.medicationId))).getSingleOrNull();

    if (medication == null) return null;

    final plan = await (db.select(
      db.medicationPlans,
    )..where((p) => p.id.equals(intake.planId))).getSingleOrNull();

    String dosageText = '';
    if (plan != null) {
      final dosageCount = plan.dosageAmount.toInt();
      dosageText =
          '$dosageCount ${getMedicationUnit(medication.medType, dosageCount)}';
    }

    // Only include user name when multiple active users exist
    String? userName;
    if (plan != null) {
      final allUsers = await (db.select(db.users)
            ..where((u) => u.isActive.equals(true)))
          .get();
      if (allUsers.length > 1) {
        final user = allUsers.firstWhere(
          (u) => u.id == plan.userId,
          orElse: () => allUsers.first,
        );
        userName = user.name;
      }
    }

    return {
      'intakeId': intake.id,
      'medicationName': medication.name,
      'dosage': dosageText,
      'scheduledTime': intake.scheduledTime,
      'medicationId': medication.id,
      'userName': userName,
    };
  }

  /// Schedule notification for a medication intake
  Future<void> scheduleIntakeNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    String? dosage,
    bool criticalReminder = false,
    AppDatabase? database,
  }) async {
    if (!_initialized) await initialize();

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final tzNow = tz.TZDateTime.now(tz.local);

    developer.log(
      'Scheduling notification ID $id for $medicationName',
      name: 'NotificationService',
    );
    developer.log(
      '  Scheduled time: $tzScheduledTime',
      name: 'NotificationService',
    );
    developer.log('  Current time: $tzNow', name: 'NotificationService');
    developer.log(
      '  Is future: ${tzScheduledTime.isAfter(tzNow)}',
      name: 'NotificationService',
    );

    // Don't schedule if time is in the past
    if (tzScheduledTime.isBefore(tzNow)) {
      developer.log(
        'Skipping past notification for $medicationName at $scheduledTime',
        name: 'NotificationService',
      );
      return;
    }

    // Use alarm for critical reminders
    if (criticalReminder) {
      developer.log(
        'Scheduling CRITICAL ALARM for $medicationName at $scheduledTime (ID: $id)',
        name: 'NotificationService',
      );

      // Get alarm settings from database
      final settingsQuery = database != null
          ? await (database.select(
              database.appSettings,
            )..limit(1)).getSingleOrNull()
          : null;

      final alarmVolume = settingsQuery?.alarmVolume ?? 0.8;
      final alarmSound = settingsQuery?.alarmSound ?? '8bit_arcade.mp3';
      final alarmVibration = settingsQuery?.alarmVibration ?? true;
      final notificationOnKill = settingsQuery?.showKillWarning ?? true;

      final alarmSettings = AlarmSettings(
        id: id,
        dateTime: scheduledTime,
        assetAudioPath: 'assets/alarms/$alarmSound',
        loopAudio: true,
        vibrate: alarmVibration,
        androidFullScreenIntent: true,
        warningNotificationOnKill: notificationOnKill,
        volumeSettings: VolumeSettings.fixed(volume: alarmVolume),
        notificationSettings: NotificationSettings(
          title: 'Kritičen opomnik: Vzemite $medicationName',
          body: dosage != null ? 'Vzemite $dosage' : 'Čas za jemanje zdravila',
          stopButton: 'Zaustavi',
          icon: 'notification_icon',
        ),
      );

      try {
        await Alarm.set(alarmSettings: alarmSettings);
        developer.log(
          'Successfully scheduled critical alarm for $medicationName at $scheduledTime (ID: $id)',
          name: 'NotificationService',
        );
      } catch (e, st) {
        developer.log(
          'Failed to schedule critical alarm for $medicationName',
          error: e,
          stackTrace: st,
          name: 'NotificationService',
        );
      }
      return;
    }

    // Regular notification for non-critical reminders
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
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

    final body = dosage != null ? 'Vzemite $dosage' : 'Čas za jemanje zdravila';

    try {
      await _notifications.zonedSchedule(
        id,
        'Vzemite $medicationName',
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
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

  /// Cancel a specific notification AND any matching alarm for the same id.
  /// Safe to call even if neither was scheduled — both calls are no-ops then.
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    try {
      await Alarm.stop(id);
    } catch (_) {
      // No alarm with this id — ignore.
    }
    developer.log('Cancelled notification/alarm $id', name: 'NotificationService');
  }

  /// Cancel all medication-related notifications and alarms.
  /// Appointment notifications and alarms (IDs >= 900000) are preserved so a
  /// medication refresh doesn't wipe scheduled appointment reminders.
  Future<void> cancelAllNotifications() async {
    // Cancel pending FLN notifications with id < 900000 only.
    final pending = await _notifications.pendingNotificationRequests();
    int cancelledNotifs = 0;
    for (final notif in pending) {
      if (notif.id < 900000) {
        await _notifications.cancel(notif.id);
        cancelledNotifs++;
      }
    }

    // Stop medication-related Alarm alarms (IDs < 900000), but never an
    // alarm that is currently ringing.
    final activeAlarms = await Alarm.getAlarms();
    final ringingIds = Alarm.ringing.value.alarms.map((a) => a.id).toSet();
    int stoppedCount = 0;
    for (final alarm in activeAlarms) {
      if (alarm.id < 900000 && !ringingIds.contains(alarm.id)) {
        await Alarm.stop(alarm.id);
        stoppedCount++;
      }
    }

    developer.log(
      'Cancelled $cancelledNotifs medication notifications and $stoppedCount alarms '
      '(skipped ${ringingIds.length} ringing, preserved appointments)',
      name: 'NotificationService',
    );
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Log all pending notifications to debug console
  Future<void> logPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();

    developer.log(
      '=== PENDING NOTIFICATIONS (${pending.length}) ===',
      name: 'NotificationService',
    );

    for (final notification in pending) {
      developer.log(
        'ID: ${notification.id}, '
        'Title: ${notification.title}, '
        'Body: ${notification.body}, '
        'Payload: ${notification.payload}',
        name: 'NotificationService',
      );
    }

    developer.log(
      '=== END PENDING NOTIFICATIONS ===',
      name: 'NotificationService',
    );
  }

  /// Check if exact alarm permission is granted (Android 12+)
  Future<bool> checkExactAlarmPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final canSchedule = await androidPlugin.canScheduleExactNotifications();
      developer.log(
        'Can schedule exact alarms: $canSchedule',
        name: 'NotificationService',
      );
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

    final upcomingIntakes =
        await (db.select(db.medicationIntakeLogs)
              ..where((log) => log.scheduledTime.isBiggerThanValue(now))
              ..where((log) => log.scheduledTime.isSmallerThanValue(weekAhead))
              ..where((log) => log.wasTaken.equals(false))
              ..orderBy([(log) => OrderingTerm(expression: log.scheduledTime)]))
            .get();

    developer.log(
      'Scheduling ${upcomingIntakes.length} notifications',
      name: 'NotificationService',
    );

    for (final intake in upcomingIntakes) {
      // Get medication details
      final medication = await (db.select(
        db.medications,
      )..where((m) => m.id.equals(intake.medicationId))).getSingleOrNull();

      // Skip if medication was deleted or not found
      if (medication == null || medication.status == MedicationStatus.deleted) {
        developer.log(
          'Skipping intake ${intake.id}: medication ${intake.medicationId} ${medication == null ? "not found" : "deleted"}',
          name: 'NotificationService',
        );
        continue;
      }

      // Get plan details for dosage
      final plan = await (db.select(
        db.medicationPlans,
      )..where((p) => p.id.equals(intake.planId))).getSingleOrNull();

      // Skip if plan was deleted
      if (plan == null) {
        developer.log(
          'Skipping intake ${intake.id}: plan ${intake.planId} not found',
          name: 'NotificationService',
        );
        continue;
      }

      final dosageCount = plan.dosageAmount.toInt();
      final dosage =
          '$dosageCount ${getMedicationUnit(medication.medType, dosageCount)}';

      await scheduleIntakeNotification(
        id: intake.id,
        medicationName: medication.name,
        scheduledTime: intake.scheduledTime,
        dosage: dosage,
        criticalReminder: medication.criticalReminder,
        database: db,
      );
    }

    final count = await getPendingNotificationsCount();
    developer.log(
      'Scheduled $count notifications successfully',
      name: 'NotificationService',
    );
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
      icon: '@mipmap/launcher_icon',
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
    developer.log(
      'Scheduling test notification for: $testTime',
      name: 'NotificationService',
    );

    final tzNow = tz.TZDateTime.now(tz.local);
    final tzTestTime = tz.TZDateTime.from(testTime, tz.local);

    developer.log('TZ Current time: $tzNow', name: 'NotificationService');
    developer.log('TZ Test time: $tzTestTime', name: 'NotificationService');
    developer.log(
      'Is test time in future? ${tzTestTime.isAfter(tzNow)}',
      name: 'NotificationService',
    );
    developer.log(
      'Difference in seconds: ${tzTestTime.difference(tzNow).inSeconds}',
      name: 'NotificationService',
    );

    // Try direct scheduling without going through scheduleIntakeNotification
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
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
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      developer.log(
        '✓ zonedSchedule call completed successfully',
        name: 'NotificationService',
      );

      // Verify it was scheduled
      final pending = await _notifications.pendingNotificationRequests();
      final found = pending.any((n) => n.id == 999998);
      developer.log(
        'Notification in pending list: $found',
        name: 'NotificationService',
      );
    } catch (e, st) {
      developer.log(
        '✗ Failed to schedule notification',
        error: e,
        stackTrace: st,
        name: 'NotificationService',
      );
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

    developer.log(
      '=== BASIC TEST NOTIFICATION (30s) ===',
      name: 'NotificationService',
    );
    developer.log('Local time now: $now', name: 'NotificationService');
    developer.log('Will fire at: $testTime', name: 'NotificationService');
    developer.log('TZ time: $tzTestTime', name: 'NotificationService');
    developer.log(
      'Seconds until fire: ${testTime.difference(now).inSeconds}',
      name: 'NotificationService',
    );

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
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
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      developer.log(
        '✓ Scheduled 30s test notification (ID: 999997)',
        name: 'NotificationService',
      );

      // Check if it's in the queue
      final pending = await _notifications.pendingNotificationRequests();
      final found = pending.where((n) => n.id == 999997).toList();
      developer.log(
        'Found in pending: ${found.isNotEmpty}',
        name: 'NotificationService',
      );
      if (found.isNotEmpty) {
        developer.log(
          'Pending notification: ${found.first}',
          name: 'NotificationService',
        );
      }
    } catch (e, st) {
      developer.log(
        '✗ Failed to schedule 30s test',
        error: e,
        stackTrace: st,
        name: 'NotificationService',
      );
    }
  }

  /// Check all notification settings and permissions
  Future<Map<String, dynamic>> checkNotificationStatus() async {
    final status = <String, dynamic>{};

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      status['canScheduleExact'] =
          await androidPlugin.canScheduleExactNotifications() ?? false;
      status['notificationPermission'] =
          await androidPlugin.areNotificationsEnabled() ?? false;

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

    final intervals = [1, 2, 5, 7, 10, 20, 30, 60];

    developer.log(
      '=== SCHEDULING MULTIPLE TEST NOTIFICATIONS ===',
      name: 'NotificationService',
    );

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

      final timeLabel = minutes < 60 ? '$minutes min' : '${minutes ~/ 60} h';

      const androidDetails = AndroidNotificationDetails(
        'medication_reminders',
        'Opomniki za zdravila',
        channelDescription: 'Opomniki za jemanje zdravil',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/launcher_icon',
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
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        developer.log(
          '✓ Scheduled notification for $timeLabel (ID: $notificationId) at $testTime',
          name: 'NotificationService',
        );
      } catch (e, st) {
        developer.log(
          '✗ Failed to schedule $timeLabel notification',
          error: e,
          stackTrace: st,
          name: 'NotificationService',
        );
      }
    }

    final pending = await _notifications.pendingNotificationRequests();
    developer.log(
      'Total pending notifications after scheduling: ${pending.length}',
      name: 'NotificationService',
    );
    developer.log(
      '=== END MULTIPLE TEST SCHEDULING ===',
      name: 'NotificationService',
    );
  }

  /// Schedule a test notification for the next medication intake in 30 seconds
  /// This is for testing the scroll-to-intake functionality
  Future<void> scheduleTestMedicationNotification(AppDatabase db) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 30));

    // Get the next upcoming intake
    final upcomingIntakes =
        await (db.select(db.medicationIntakeLogs)
              ..where((log) => log.scheduledTime.isBiggerThanValue(now))
              ..where((log) => log.wasTaken.equals(false))
              ..orderBy([(log) => OrderingTerm(expression: log.scheduledTime)])
              ..limit(1))
            .get();

    if (upcomingIntakes.isEmpty) {
      developer.log(
        'No upcoming intakes found for test notification',
        name: 'NotificationService',
      );
      return;
    }

    final intake = upcomingIntakes.first;

    // Get medication details
    final medication = await (db.select(
      db.medications,
    )..where((m) => m.id.equals(intake.medicationId))).getSingleOrNull();

    if (medication == null) {
      developer.log(
        'Medication not found for test notification',
        name: 'NotificationService',
      );
      return;
    }

    // Get plan details for dosage
    final plan = await (db.select(
      db.medicationPlans,
    )..where((p) => p.id.equals(intake.planId))).getSingleOrNull();

    String dosageText = '';
    if (plan != null) {
      final dosageCount = plan.dosageAmount.toInt();
      dosageText =
          '$dosageCount ${getMedicationUnit(medication.medType, dosageCount)}';
    }

    final tzTestTime = tz.TZDateTime(
      tz.local,
      testTime.year,
      testTime.month,
      testTime.day,
      testTime.hour,
      testTime.minute,
      testTime.second,
    );

    developer.log(
      '=== TEST MEDICATION NOTIFICATION (30s) ===',
      name: 'NotificationService',
    );
    developer.log(
      'Medication: ${medication.name}',
      name: 'NotificationService',
    );
    developer.log('Dosage: $dosageText', name: 'NotificationService');
    developer.log('Intake ID: ${intake.id}', name: 'NotificationService');
    developer.log('Will fire at: $testTime', name: 'NotificationService');

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      ticker: 'Test medication reminder',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.zonedSchedule(
        999990, // Special ID for test
        'Vzemite ${medication.name}',
        dosageText.isNotEmpty
            ? 'Vzemite $dosageText'
            : 'Čas za jemanje zdravila',
        tzTestTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: intake.id
            .toString(), // Use actual intake ID so tap navigation works
      );

      developer.log(
        '✓ Scheduled test medication notification (ID: 999990)',
        name: 'NotificationService',
      );

      final pending = await _notifications.pendingNotificationRequests();
      final found = pending.any((n) => n.id == 999990);
      developer.log('Found in pending: $found', name: 'NotificationService');
    } catch (e, st) {
      developer.log(
        '✗ Failed to schedule test medication notification',
        error: e,
        stackTrace: st,
        name: 'NotificationService',
      );
    }

    developer.log(
      '=== END TEST MEDICATION NOTIFICATION ===',
      name: 'NotificationService',
    );
  }

  /// Trigger a test alarm in 1 minute
  Future<void> triggerAlarm() async {
    final now = DateTime.now();
    final alarmTime = now.add(const Duration(minutes: 1));

    final alarmSettings = AlarmSettings(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      dateTime: alarmTime,
      assetAudioPath: 'assets/alarms/marimba.mp3',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: const VolumeSettings.fixed(volume: 0.5),
      notificationSettings: const NotificationSettings(
        title: 'Test Alarm',
        body: 'Dev test alarm - rings in 1 minute',
        stopButton: 'Stop',
        icon: 'notification_icon',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    print('Test alarm set for $alarmTime (1 minute from now)');
  }
}
