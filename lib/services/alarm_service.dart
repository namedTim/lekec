import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/services/appointment_service.dart';

/// Provider for the alarm service singleton
final alarmServiceProvider = Provider<AlarmService>((ref) {
  throw UnimplementedError('AlarmService must be overridden in main()');
});

/// Provider for the current list of alarms
final alarmsProvider = NotifierProvider<AlarmNotifier, List<AlarmSettings>>(() {
  return AlarmNotifier();
});

class AlarmNotifier extends Notifier<List<AlarmSettings>> {
  @override
  List<AlarmSettings> build() {
    loadAlarms();
    return [];
  }

  AlarmService get _service => ref.read(alarmServiceProvider);

  Future<void> loadAlarms() async {
    final alarms = await _service.getAlarms();
    state = alarms;
  }

  Future<void> stopAlarm(int id) async {
    await _service.stopAlarm(id);
    await loadAlarms();
  }

  Future<void> stopAllAlarms() async {
    await _service.stopAllAlarms();
    await loadAlarms();
  }
}

/// Service that manages alarm lifecycle and navigation
class AlarmService {
  AlarmService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;

  StreamSubscription<AlarmSet>? _ringSubscription;
  StreamSubscription<AlarmSet>? _updateSubscription;
  int? _currentAlarmId; // Track currently shown alarm to prevent duplicates

  /// Maximum time (in minutes) after scheduled time that an alarm should still ring.
  /// After this, the alarm is considered backlog (e.g. it fired while the
  /// device was asleep / app was killed) and is silently stopped instead of
  /// surprising the user with a stale reminder.
  ///
  /// Keep this small — an alarm "from 30 min ago" should not jolt the user
  /// when they pick up their phone. Two minutes is enough headroom for normal
  /// processing latency without letting genuine backlog through.
  static const int _maxLateMinutes = 2;

  /// Cap how long we'll wait for the navigator to be ready before giving up.
  /// Long enough to outlast a slow cold start (DB query for onboarding state,
  /// theme provider hydration, etc.) but bounded so we don't leak forever.
  static const Duration _maxNavigatorWait = Duration(seconds: 30);
  static const Duration _navigatorPollInterval = Duration(milliseconds: 200);

  /// Initialize alarm listeners - call this once at app startup
  void initialize() {
    _ringSubscription = Alarm.ringing.listen(_onAlarmRinging);
    _updateSubscription = Alarm.scheduled.listen(_onAlarmsUpdated);
  }

  /// Check if an alarm is too old to ring (past the grace period)
  bool _isAlarmTooOld(AlarmSettings alarm) {
    final now = DateTime.now();
    final scheduledTime = alarm.dateTime;
    final difference = now.difference(scheduledTime);
    return difference.inMinutes > _maxLateMinutes;
  }

  /// Check for ringing alarms on cold start and navigate if needed
  Future<void> checkInitialRingingAlarms() async {
    final ringingAlarms = Alarm.ringing.value.alarms;
    if (ringingAlarms.isEmpty) return;

    // Check each ringing alarm
    for (final alarm in ringingAlarms) {
      if (_isAlarmTooOld(alarm)) {
        // Alarm is too old, stop it silently
        await Alarm.stop(alarm.id);
        continue;
      }

      // Alarm is within grace period, try to show it (with retries for cold-start)
      await _showAlarmWithRetry(alarm);
      break; // Only show one alarm at a time
    }
  }

  /// Push the alarm screen as soon as the navigator is ready.
  ///
  /// On cold start the rootNavigatorKey is attached to MaterialApp.router,
  /// which only mounts after onboardingStatusProvider resolves — that DB
  /// query can outlast a small fixed retry budget on slow devices, leaving
  /// the user with a black screen. We instead poll until either:
  ///   - the navigator becomes ready (push and bail), or
  ///   - the alarm stops ringing (no point showing it), or
  ///   - we exceed _maxNavigatorWait (give up).
  Future<void> _showAlarmWithRetry(AlarmSettings alarm) async {
    if (_currentAlarmId == alarm.id) return;

    final deadline = DateTime.now().add(_maxNavigatorWait);

    while (DateTime.now().isBefore(deadline)) {
      // Bail if the alarm stopped ringing while we waited.
      final stillRinging = Alarm.ringing.value.alarms.any((a) => a.id == alarm.id);
      if (!stillRinging) return;

      final context = _navigatorKey.currentContext;
      if (context != null) {
        final route = AppointmentService.isAppointmentAlarm(alarm.id)
            ? '/appointment-ring'
            : '/ring';
        try {
          // Context is fetched fresh on every iteration; no async gap before use.
          // ignore: use_build_context_synchronously
          context.push(route, extra: alarm);
          _currentAlarmId = alarm.id;
          return;
        } catch (_) {
          // Router not yet wired up to this context — keep polling.
        }
      }

      await Future.delayed(_navigatorPollInterval);
    }
  }

  /// Handle when an alarm starts ringing
  void _onAlarmRinging(AlarmSet alarmSet) {
    if (alarmSet.alarms.isEmpty) {
      // No alarms ringing, clear the current alarm
      _currentAlarmId = null;
      return;
    }

    final alarm = alarmSet.alarms.first;

    // Check if alarm is too old to ring
    if (_isAlarmTooOld(alarm)) {
      // Stop the alarm silently - it's too late
      Alarm.stop(alarm.id);
      return;
    }

    if (_currentAlarmId == alarm.id) return;

    // Use the same retry loop as cold-start: navigator may not be ready yet
    // (e.g. listener fires before MaterialApp.router has mounted).
    _showAlarmWithRetry(alarm);
  }

  /// Handle when the alarm schedule is updated
  void _onAlarmsUpdated(AlarmSet alarmSet) {
    // Trigger alarm list refresh in UI
    // The StateNotifier will handle this via its own subscription if needed
  }

  /// Get all scheduled alarms
  Future<List<AlarmSettings>> getAlarms() async {
    final alarms = await Alarm.getAlarms();
    alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    return alarms;
  }

  /// Stop a specific alarm
  Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }

  /// Stop all alarms
  Future<void> stopAllAlarms() async {
    await Alarm.stopAll();
  }

  /// Reload all alarms (recreates them with current settings)
  /// This is needed when global alarm settings change
  Future<void> reloadAllAlarms() async {
    final alarms = await Alarm.getAlarms();

    // Recreate each alarm to pick up new settings
    for (final alarm in alarms) {
      // Stop the alarm first
      await Alarm.stop(alarm.id);

      // Recreate it with the same settings (alarm package will use new global settings)
      await Alarm.set(alarmSettings: alarm);
    }
  }

  /// Clean up subscriptions
  void dispose() {
    _ringSubscription?.cancel();
    _updateSubscription?.cancel();
  }
}
