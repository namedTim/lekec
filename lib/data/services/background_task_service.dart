import 'package:workmanager/workmanager.dart';
import 'dart:developer' as developer;
import '../../database/drift_database.dart';
import 'intake_schedule_generator.dart';
import 'notification_service.dart';

/// Background task names
const String scheduleGenerationTask = 'scheduleGenerationTask';
const String notificationScheduleTask = 'notificationScheduleTask';

/// Background callback - runs in isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      developer.log('Background task started: $task', name: 'BackgroundTask');

      // Initialize database
      final db = AppDatabase();

      switch (task) {
        case scheduleGenerationTask:
          // Generate new schedule entries
          final generator = IntakeScheduleGenerator(db);
          final count = await generator.generateScheduledIntakes();
          developer.log('Generated $count schedule entries in background', 
            name: 'BackgroundTask');
          break;

        case notificationScheduleTask:
          // Reschedule notifications
          final notificationService = NotificationService();
          await notificationService.scheduleAllUpcomingNotifications(db);
          developer.log('Rescheduled notifications in background', 
            name: 'BackgroundTask');
          break;
      }

      return Future.value(true);
    } catch (e, st) {
      developer.log('Background task failed: $task', 
        error: e, stackTrace: st, name: 'BackgroundTask');
      return Future.value(false);
    }
  });
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );

    _initialized = true;
    developer.log('Background task service initialized', name: 'BackgroundTask');
  }

  /// Schedule daily background task to generate intake schedules
  Future<void> scheduleScheduleGeneration() async {
    if (!_initialized) await initialize();

    await Workmanager().registerPeriodicTask(
      'schedule-generation',
      scheduleGenerationTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      initialDelay: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    developer.log('Scheduled daily schedule generation task', name: 'BackgroundTask');
  }

  /// Schedule periodic notification rescheduling
  Future<void> scheduleNotificationRefresh() async {
    if (!_initialized) await initialize();

    await Workmanager().registerPeriodicTask(
      'notification-refresh',
      notificationScheduleTask,
      frequency: const Duration(hours: 6), // Every 6 hours
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      initialDelay: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    developer.log('Scheduled periodic notification refresh task', name: 'BackgroundTask');
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    developer.log('Cancelled all background tasks', name: 'BackgroundTask');
  }
}
