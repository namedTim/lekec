import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/services/notification_service.dart';
import '../../database/drift_database.dart';
import '../../main.dart' show db, homePageKey;

class ExampleAlarmRingScreen extends StatefulWidget {
  const ExampleAlarmRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  @override
  State<ExampleAlarmRingScreen> createState() => _ExampleAlarmRingScreenState();
}

class _ExampleAlarmRingScreenState extends State<ExampleAlarmRingScreen>
    with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.lekec/lockscreen');
  Map<String, dynamic>? _medicationDetails;
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _showOverLockscreen(true);
    _loadMedicationDetails();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _showOverLockscreen(bool show) async {
    try {
      await platform.invokeMethod('showOverLockscreen', {'show': show});
    } catch (e) {
      // Ignore errors on non-Android platforms
    }
  }

  Future<void> _loadMedicationDetails() async {
    final notificationService = NotificationService();
    final details = await notificationService.getMedicationDetailsForIntake(
      widget.alarmSettings.id,
      db,
    );

    if (mounted) {
      setState(() {
        _medicationDetails = details;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _showOverLockscreen(false);
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    // Stop the alarm
    await Alarm.stop(widget.alarmSettings.id);

    // If this is a demo/test alarm (no medication details), just close the screen
    if (_medicationDetails == null) {
      if (mounted) {
        context.pop();
      }
      return;
    }

    // Mark intake as taken in database
    await (db.update(db.medicationIntakeLogs)
          ..where((t) => t.id.equals(widget.alarmSettings.id)))
        .write(
      MedicationIntakeLogsCompanion(
        wasTaken: const drift.Value(true),
        takenTime: drift.Value(DateTime.now()),
      ),
    );

    // Navigate to home page and scroll to intake
    if (mounted) {
      // Navigate to home page using go_router
      context.go('/');

      // Wait for navigation to complete, then refresh and scroll
      Future.delayed(const Duration(milliseconds: 500), () {
        homePageKey.currentState?.loadTodaysIntakes();
        homePageKey.currentState?.scrollToIntake(widget.alarmSettings.id);
      });
    }
  }

  Future<void> _snoozeAlarm() async {
    final newTime = DateTime.now().add(const Duration(minutes: 10));

    // If this is a demo/test alarm (no medication details), just snooze and close
    if (_medicationDetails == null) {
      await Alarm.set(
        alarmSettings: widget.alarmSettings.copyWith(
          dateTime: newTime,
        ),
      );
      if (mounted) {
        context.pop();
      }
      return;
    }

    // Update the scheduled time in the database
    await (db.update(db.medicationIntakeLogs)
          ..where((t) => t.id.equals(widget.alarmSettings.id)))
        .write(
      MedicationIntakeLogsCompanion(
        scheduledTime: drift.Value(newTime),
      ),
    );

    // Snooze for 10 minutes
    await Alarm.set(
      alarmSettings: widget.alarmSettings.copyWith(
        dateTime: newTime,
      ),
    );

    // Close the alarm screen and refresh dashboard
    if (mounted) {
      context.go('/');
      Future.delayed(const Duration(milliseconds: 300), () {
        homePageKey.currentState?.loadTodaysIntakes();
      });
    }
  }

  Future<void> _dismissAlarm() async {
    // Just stop the alarm
    await Alarm.stop(widget.alarmSettings.id);

    // Close the alarm screen
    if (mounted) {
      // If this is a demo/test alarm (no medication details), just pop
      if (_medicationDetails == null) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _checkDemoAlarm() async{
    if (_medicationDetails?['dosage'] == ''){
      // just pop alarm screen and stop alarm
      await Alarm.stop(widget.alarmSettings.id);
      if (mounted) {
        context.pop();
      }
    }
  }

  String _getTimeText() {
    final scheduledTime =
        _medicationDetails?['scheduledTime'] as DateTime? ?? DateTime.now();
    return '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.error,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final medicationName = _medicationDetails?['medicationName'] ?? 'Zdravilo';
    final dosage = _medicationDetails?['dosage'] ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.error,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.error, colors.error.withOpacity(0.8)],
              ),
            ),
            child: Column(
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OPOMNIK ZA ZDRAVILO',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onError,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Symbols.close, color: colors.onError),
                        onPressed: _stopAlarm,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pulsing alarm icon
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: colors.onError.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Symbols.alarm,
                                size: 64,
                                color: colors.onError,
                                fill: 1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Time indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.onError.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getTimeText(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colors.onError,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Medication name
                          Text(
                            medicationName,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: colors.onError,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Dosage info
                          if (dosage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colors.onError.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Symbols.medication,
                                    color: colors.onError,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    dosage,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: colors.onError,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Main button - I took it
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _stopAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.onError,
                            foregroundColor: colors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Symbols.check_circle, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'SEM VZEL',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Secondary buttons row
                      Row(
                        children: [
                          // Snooze button
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _snoozeAlarm,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.onError,
                                  side: BorderSide(
                                    color: colors.onError.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Symbols.snooze, size: 20),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Čez 10 min',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Dismiss button
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _dismissAlarm,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.onError,
                                  side: BorderSide(
                                    color: colors.onError.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Symbols.close, size: 20),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Opusti',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
