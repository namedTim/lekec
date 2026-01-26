import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  /// Initialize alarm listeners - call this once at app startup
  void initialize() {
    _ringSubscription = Alarm.ringing.listen(_onAlarmRinging);
    _updateSubscription = Alarm.scheduled.listen(_onAlarmsUpdated);
  }

  /// Check for ringing alarms on cold start and navigate if needed
  Future<void> checkInitialRingingAlarms() async {
    final ringingAlarms = Alarm.ringing.value.alarms;
    if (ringingAlarms.isNotEmpty) {
      // Wait a bit for the navigator to be ready
      await Future.delayed(const Duration(milliseconds: 100));
      final context = _navigatorKey.currentContext;
      if (context != null) {
        context.push('/ring', extra: ringingAlarms.first);
      }
    }
  }

  /// Handle when an alarm starts ringing
  void _onAlarmRinging(AlarmSet alarmSet) {
    if (alarmSet.alarms.isEmpty) return;

    final context = _navigatorKey.currentContext;
    if (context != null) {
      context.push('/ring', extra: alarmSet.alarms.first);
    }
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

  /// Clean up subscriptions
  void dispose() {
    _ringSubscription?.cancel();
    _updateSubscription?.cancel();
  }
}
