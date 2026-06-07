import 'dart:developer' as developer;

import 'package:alarm/alarm.dart';

import '../../database/drift_database.dart';
import '../../main.dart' show homePageKey;
import 'appointment_service.dart';
import 'intake_log_service.dart';
import 'notification_service.dart';
import 'pending_action_queue.dart';
import 'water_service.dart';

/// Applies notification action button taps the user made on reminders:
/// "Sem vzel" / "Bom preskočil" for medication reminders and "Razumem" for
/// appointment reminders.
///
/// Taps come from two sources, both of which survive the app being killed:
///  * **Critical (alarm) reminders** — recorded natively by the forked
///    `alarm` package, read via [Alarm.consumePendingNotificationActions].
///  * **Non-critical reminders** — `flutter_local_notifications` action
///    buttons, parked in [PendingActionQueue].
///
/// Draining is triggered from several places (app start, app resume, whenever
/// an alarm stops, and right after a foreground action tap) — the re-entrancy
/// guard keeps that safe, and both queues hand back each tap exactly once.
class NotificationActionService {
  NotificationActionService(this.db);

  final AppDatabase db;

  static bool _draining = false;

  /// Drains every pending notification action and applies it to the database.
  Future<void> drainPendingActions() async {
    if (_draining) return;
    _draining = true;
    try {
      var touchedMedication = false;

      // Critical reminders: taps recorded natively by the alarm fork.
      for (final event in await Alarm.consumePendingNotificationActions()) {
        developer.log('Applying $event', name: 'NotificationActionService');
        // Clear the alarm in Dart land too. The native side already stopped
        // it, but the Dart-side ringing state can be stale after an app
        // restart — this closes any open ring screen and stops
        // checkInitialRingingAlarms from re-showing it.
        await Alarm.stop(event.alarmId);
        // Appointment reminder ("Razumem"): appointments keep no
        // per-occurrence state, so there is nothing else to persist.
        if (AppointmentService.isAppointmentAlarm(event.alarmId)) continue;
        // Medication reminder: the alarm id is the intake log id.
        if (await _applyMedicationAction(event.alarmId, event.actionId)) {
          touchedMedication = true;
        }
      }

      // Non-critical reminders: taps from flutter_local_notifications.
      for (final action in await PendingActionQueue.drain()) {
        developer.log(
          'Applying FLN action "${action.actionId}" for intake '
          '${action.intakeId}',
          name: 'NotificationActionService',
        );
        if (await _applyMedicationAction(action.intakeId, action.actionId)) {
          touchedMedication = true;
        }
      }

      // Water-reminder action button taps live on a sibling queue keyed by
      // userId (water reminders are recurring per-user notifications, not
      // per-intake events).
      var touchedWater = false;
      for (final action in await WaterPendingActionQueue.drain()) {
        developer.log(
          'Applying water action "${action.actionId}" for user '
          '${action.userId}',
          name: 'NotificationActionService',
        );
        if (await _applyWaterAction(action.userId, action.actionId)) {
          touchedWater = true;
        }
      }

      // Re-arm upcoming reminders so the next dose is scheduled immediately.
      if (touchedMedication) {
        await NotificationService().scheduleAllUpcomingNotifications(db);
        // Refresh the dashboard if it is currently on screen.
        homePageKey.currentState?.loadTodaysIntakes();
      }
      // The dashboard time-island shows the prime user's hydration, so refresh
      // it after a water action. The user-medications (Voda) page reloads on
      // resume on its own.
      if (touchedWater) {
        homePageKey.currentState?.refreshWaterIsland();
        developer.log(
          'Applied water actions; refreshed dashboard island',
          name: 'NotificationActionService',
        );
      }
    } catch (e, st) {
      developer.log(
        'Failed to drain notification actions',
        error: e,
        stackTrace: st,
        name: 'NotificationActionService',
      );
    } finally {
      _draining = false;
    }
  }

  /// Applies a single water-reminder action. "water_taken" logs the user's
  /// previous intake amount again (or 200 ml if they have no history yet);
  /// "water_skip" is just an acknowledged dismiss. Returns whether the
  /// database changed.
  Future<bool> _applyWaterAction(int userId, String actionId) async {
    switch (actionId) {
      case 'water_taken':
        final water = WaterService(db);
        final amount = await water.getLastIntakeAmount(userId);
        await water.logIntake(userId: userId, amountMl: amount);
        // Stop nagging for the rest of today if this push met the goal.
        final user = await (db.select(db.users)
              ..where((u) => u.id.equals(userId)))
            .getSingleOrNull();
        if (user != null) {
          await NotificationService().refreshWaterRemindersForGoal(user);
        }
        return true;
      case 'water_skip':
        return false;
      default:
        developer.log(
          'Unknown water action "$actionId" for user $userId',
          name: 'NotificationActionService',
        );
        return false;
    }
  }

  /// Applies a single medication action. Returns whether the database changed.
  Future<bool> _applyMedicationAction(int intakeId, String actionId) async {
    switch (actionId) {
      case 'taken':
        await IntakeLogService(db).updateIntakeStatus(intakeId, true);
        return true;
      case 'skip':
        await IntakeLogService(db).updateIntakeStatus(intakeId, false);
        return true;
      default:
        developer.log(
          'Unknown action "$actionId" for intake $intakeId',
          name: 'NotificationActionService',
        );
        return false;
    }
  }
}
