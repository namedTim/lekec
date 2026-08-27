import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' show DartPluginRegistrant;
import 'package:drift/drift.dart' show ComparableExpr, OrderingTerm;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart' show MedicationStatus;
import '../../helpers/medication_unit_helper.dart';
import '../../main.dart' show db, homePageKey, rootNavigatorKey;
import 'package:go_router/go_router.dart';
import 'package:alarm/alarm.dart';
import 'pending_action_queue.dart';
import 'user_labels.dart';
import 'water_service.dart';

/// Handles notification action button taps that arrive while the app is
/// terminated. Two flavours of reminder route here:
///   * Medication reminders ("Sem vzel" / "Bom preskočil") — payload is the
///     intake id as a plain integer string; parked in [PendingActionQueue].
///   * Water reminders ("Sem spil" / "Preskoči") — payload is `water:<userId>`;
///     parked in [WaterPendingActionQueue].
///
/// `flutter_local_notifications` runs this in a short-lived background
/// isolate, so it only parks the tap — [NotificationActionService] applies it
/// the next time the app runs.
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  final actionId = response.actionId;
  if (actionId == null) return;
  final payload = response.payload ?? '';

  // Water reminder action (payload format "water:<userId>")
  if (payload.startsWith('water:')) {
    if (actionId != 'water_taken' && actionId != 'water_skip') return;
    final userId = int.tryParse(payload.substring('water:'.length));
    if (userId == null) return;
    DartPluginRegistrant.ensureInitialized();
    await WaterPendingActionQueue.enqueue(userId, actionId);
    return;
  }

  // Medication reminder action (payload is the intake id)
  if (actionId != 'taken' && actionId != 'skip') return;
  final intakeId = int.tryParse(payload);
  if (intakeId == null) return;
  // Required before using plugins (SharedPreferences) in a background isolate.
  DartPluginRegistrant.ensureInitialized();
  await PendingActionQueue.enqueue(intakeId, actionId);
}

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

    // Separate channel for "running low on stock" warnings so the user can
    // tune/silence them independently of the (more urgent) dose reminders.
    const lowStockChannel = AndroidNotificationChannel(
      'medication_low_stock',
      'Zaloga zdravil',
      description: 'Opozorila, ko zmanjkuje zdravil',
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
      // Create the notification channels
      await androidPlugin.createNotificationChannel(androidChannel);
      await androidPlugin.createNotificationChannel(lowStockChannel);
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
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
      'Notification tapped: ${response.payload}, action: ${response.actionId}',
      name: 'NotificationService',
    );

    final intakeId = int.tryParse(response.payload ?? '');
    if (intakeId == null) return;

    // Action button taps ("Sem vzel" / "Bom preskočil") are NOT delivered
    // here — flutter_local_notifications always routes them to the background
    // isolate (notificationTapBackground), even when the app is running. So
    // this is always a plain tap on the notification body: open the app at
    // this intake. Retry in case the router isn't built yet (cold start).
    _navigateToIntake(intakeId, retries: 5);
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
      final labels = database != null
          ? await UserLabels.forPrimaryUser(database)
          : UserLabels.fallback;
      // Kill-warning notification disabled for now — re-enable by restoring
      // this line and the `warningNotificationOnKill` arg below.
      // final notificationOnKill = settingsQuery?.showKillWarning ?? true;

      final alarmSettings = AlarmSettings(
        id: id,
        dateTime: scheduledTime,
        assetAudioPath: 'assets/alarms/$alarmSound',
        loopAudio: true,
        vibrate: alarmVibration,
        androidFullScreenIntent: true,
        // Kill-warning notification disabled for now.
        // warningNotificationOnKill: notificationOnKill,
        warningNotificationOnKill: false,
        volumeSettings: VolumeSettings.fixed(volume: alarmVolume),
        notificationSettings: NotificationSettings(
          title: 'Kritičen opomnik: Vzemite $medicationName',
          body: dosage != null ? 'Vzemite $dosage' : 'Čas za jemanje zdravila',
          // iOS fallback — on Android the actionButtons below take over.
          stopButton: 'Zaustavi',
          icon: 'notification_icon',
          // Let the user act straight from the notification without opening
          // the full-screen alarm UI. Handled by NotificationActionService.
          actionButtons: [
            NotificationActionButton(id: 'taken', text: labels.taken),
            NotificationActionButton(id: 'skip', text: labels.skip),
          ],
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
    final nonCriticalLabels = database != null
        ? await UserLabels.forPrimaryUser(database)
        : UserLabels.fallback;
    final androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      // Let the user act straight from the notification. Handled in the
      // foreground by _onNotificationTap and, when the app is killed, by the
      // top-level notificationTapBackground handler.
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'taken',
          nonCriticalLabels.taken,
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'skip',
          nonCriticalLabels.skip,
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
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

    // Stop medication-related Alarm alarms (IDs < 900000), but never one that
    // is currently ringing.
    //
    // The ringing state is re-checked natively (`Alarm.isRinging`) right
    // before each stop — NOT from a snapshot and NOT from `Alarm.ringing`:
    //  * A snapshot taken once before the loop races with an alarm that starts
    //    ringing mid-loop.
    //  * This method also runs in the Workmanager background isolate, whose
    //    Dart-side `Alarm.ringing` is always empty — relying on it there would
    //    stop an alarm that is ringing right now, cutting the reminder off
    //    about a second after it starts. `Alarm.isRinging` reads the
    //    process-wide native state, so it is correct from any isolate.
    // In an isolate where Alarm.init() was never called, AlarmStorage waits
    // forever — a hang here would strand the wipe above with nothing
    // rescheduled, so time out and skip alarm cleanup rather than block.
    List<AlarmSettings> activeAlarms = const [];
    try {
      activeAlarms = await Alarm.getAlarms().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      developer.log(
        'Alarm.getAlarms() timed out — AlarmStorage not initialized in this '
        'isolate? Skipping alarm cleanup so rescheduling can proceed.',
        name: 'NotificationService',
      );
    }
    int stoppedCount = 0;
    int skippedRinging = 0;
    for (final alarm in activeAlarms) {
      if (alarm.id >= 900000) continue;
      if (await Alarm.isRinging(alarm.id)) {
        skippedRinging++;
        continue;
      }
      await Alarm.stop(alarm.id);
      stoppedCount++;
    }

    developer.log(
      'Cancelled $cancelledNotifs medication notifications and $stoppedCount alarms '
      '(skipped $skippedRinging ringing, preserved appointments)',
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
              // Skip intakes the user has already acted on (taken or
              // dismissed/skipped) — takenTime is set for any action — so a
              // cancelled reminder is never re-created here.
              ..where((log) => log.takenTime.isNull())
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

  /// Notification id space for low-stock warnings. Kept well clear of the
  /// intake ids and the water base (950000) so they never collide.
  static const int _lowStockIdBase = 970000;

  /// Shows a "running low / out of stock" notification for a medication.
  ///
  /// Uses a stable per-medication id so a newer warning replaces the older one
  /// rather than stacking. [remainingLabel] should be a ready-to-show quantity
  /// like "2 tableti" or "3 ml"; [isOut] flips the copy to the depleted state.
  Future<void> showLowStockNotification({
    required int medicationId,
    required String medName,
    required String remainingLabel,
    required bool isOut,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'medication_low_stock',
      'Zaloga zdravil',
      channelDescription: 'Opozorila, ko zmanjkuje zdravil',
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

    final title = isOut ? '$medName je zmanjkalo' : '$medName kmalu zmanjka';
    final body = isOut
        ? 'Zaloga je prazna. Dopolnite jo, da opomniki ostanejo točni.'
        : 'Ostane le še $remainingLabel. Razmislite o dopolnitvi zaloge.';

    // Non-numeric payload: _onNotificationTap ignores it (only intake ids
    // navigate), so tapping simply opens the app without mis-routing.
    await _notifications.show(
      _lowStockIdBase + medicationId,
      title,
      body,
      notificationDetails,
      payload: 'lowstock:$medicationId',
    );

    developer.log(
      'Showed low-stock notification for $medName (out=$isOut)',
      name: 'NotificationService',
    );
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

  // ── Water reminders ────────────────────────────────────────────────────
  //
  // Water reminders are recurring (daily) notifications, one per slot in the
  // user's configured window. They live in a dedicated id range so that
  // `cancelAllNotifications()` — which wipes ids < 900000 on every
  // medication refresh — leaves them alone.
  //
  //   id = _waterIdBase + userId * _waterSlotsPerUser + slotIndex
  //
  // _waterSlotsPerUser is a hard cap on slots per user. With a minimum
  // interval of 15 min over a 24 h window that's 96 slots; rounding up to
  // 100 gives us a clean per-user block and headroom for tweaks.

  static const int _waterIdBase = 950000;
  static const int _waterSlotsPerUser = 100;

  int _waterReminderId(int userId, int slot) =>
      _waterIdBase + userId * _waterSlotsPerUser + slot;

  /// (Re)schedule the daily water reminders for [user] based on the
  /// `waterReminder*` columns. Safe to call repeatedly: any previously
  /// scheduled reminders for this user are cancelled first.
  ///
  /// When `waterReminderEnabled` is false this just cancels — call
  /// [cancelWaterReminders] directly if you don't have a user row handy.
  ///
  /// When [skipToday] is true, every slot's first occurrence is pushed to
  /// tomorrow (the daily repeat then continues as normal). Used once the user
  /// has already hit today's goal so they aren't nagged for the rest of the
  /// day — see [refreshWaterRemindersForGoal].
  Future<void> scheduleWaterReminders(User user, {bool skipToday = false}) async {
    if (!_initialized) await initialize();

    await cancelWaterReminders(user.id);

    if (!user.waterReminderEnabled) {
      developer.log(
        'Water reminders disabled for user ${user.id}',
        name: 'NotificationService',
      );
      return;
    }

    final int start = user.waterReminderStartHour.clamp(0, 23).toInt();
    final int end = user.waterReminderEndHour.clamp(0, 23).toInt();
    final int interval =
        user.waterReminderIntervalMinutes.clamp(15, 360).toInt();
    if (end <= start) {
      developer.log(
        'Water reminders skipped: end ($end) ≤ start ($start) for user ${user.id}',
        name: 'NotificationService',
      );
      return;
    }

    final labels = UserLabels.forGender(user.gender);

    // Disambiguate notifications when more than one user is active — otherwise
    // "Spij kozarec vode" gives no clue *which* person should drink.
    final activeUserCount = await (db.select(db.users)
          ..where((u) => u.isActive.equals(true)))
        .get()
        .then((rows) => rows.length);
    final isMultiUser = activeUserCount > 1;
    final title = isMultiUser
        ? '${user.name} — čas za vodo 💧'
        : 'Čas za vodo 💧';
    final body = isMultiUser
        ? '${user.name}, spij kozarec vode'
        : 'Spij kozarec vode';

    final androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Opomniki za zdravila',
      channelDescription: 'Opomniki za jemanje zdravil',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      // Same one-tap log / skip affordance as medication reminders.
      // "Sem spil" re-logs the user's last intake amount (or 200 ml if none
      // yet); "Preskoči" just dismisses. Both handled by
      // NotificationActionService.
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'water_taken',
          labels.drank,
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'water_skip',
          labels.skip,
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzNow = tz.TZDateTime.now(tz.local);
    int slot = 0;
    // Walk slots in minutes-since-midnight so an interval like 90 min still
    // lands within the window between an early start and a late end.
    final startMin = start * 60;
    final endMin = end * 60;
    for (int min = startMin; min < endMin; min += interval) {
      if (slot >= _waterSlotsPerUser) {
        developer.log(
          'Water reminder slot cap hit for user ${user.id} — extra reminders skipped',
          name: 'NotificationService',
        );
        break;
      }
      final hour = min ~/ 60;
      final minute = min % 60;

      // Build today's firing time; if already in the past today, bump to
      // tomorrow so the first occurrence isn't immediate when the user
      // enables reminders mid-day.
      var fireAt = tz.TZDateTime(
        tz.local,
        tzNow.year,
        tzNow.month,
        tzNow.day,
        hour,
        minute,
      );
      if (skipToday || !fireAt.isAfter(tzNow)) {
        fireAt = fireAt.add(const Duration(days: 1));
      }

      final id = _waterReminderId(user.id, slot);
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          fireAt,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          // Repeat daily at the same wall-clock time.
          matchDateTimeComponents: DateTimeComponents.time,
          // "water:<userId>" so notificationTapBackground can route the
          // action buttons through WaterPendingActionQueue rather than the
          // medication queue (intake ids).
          payload: 'water:${user.id}',
        );
      } catch (e, st) {
        developer.log(
          'Failed to schedule water reminder slot $slot for user ${user.id}',
          error: e,
          stackTrace: st,
          name: 'NotificationService',
        );
      }
      slot++;
    }

    developer.log(
      'Scheduled $slot water reminders for user ${user.id}',
      name: 'NotificationService',
    );
  }

  /// Cancel every pending water reminder for [userId], regardless of how
  /// many slots were last scheduled — iterates the full per-user block.
  Future<void> cancelWaterReminders(int userId) async {
    for (int slot = 0; slot < _waterSlotsPerUser; slot++) {
      await _notifications.cancel(_waterReminderId(userId, slot));
    }
  }

  /// (Re)schedule [user]'s water reminders against today's progress: once the
  /// daily goal is met the remaining reminders are pushed to tomorrow so the
  /// user isn't nagged after they're done; otherwise today's normal schedule
  /// is (re)applied. Disabled reminders are just cancelled.
  ///
  /// Call this after any change that can affect today's total or the goal —
  /// logging/deleting an intake, a "Sem spil" tap, or editing the goal — so the
  /// OS schedule tracks the user's actual intake. Idempotent.
  Future<void> refreshWaterRemindersForGoal(User user) async {
    if (!user.waterReminderEnabled) {
      await cancelWaterReminders(user.id);
      return;
    }
    final total = await WaterService(db).getTodayTotal(user.id);
    final goalReached = total >= user.dailyWaterGoalMl;
    await scheduleWaterReminders(user, skipToday: goalReached);
    developer.log(
      'Water reminders for user ${user.id}: total=$total goal=${user.dailyWaterGoalMl} '
      'goalReached=$goalReached (skipToday=$goalReached)',
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
