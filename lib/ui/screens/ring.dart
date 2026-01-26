import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../data/services/notification_service.dart';
import '../../main.dart' show db;

class ExampleAlarmRingScreen extends StatefulWidget {
  const ExampleAlarmRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  @override
  State<ExampleAlarmRingScreen> createState() => _ExampleAlarmRingScreenState();
}

class _ExampleAlarmRingScreenState extends State<ExampleAlarmRingScreen> {
  static final _log = Logger('ExampleAlarmRingScreenState');

  StreamSubscription<AlarmSet>? _ringingSubscription;
  Map<String, dynamic>? _medicationDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicationDetails();
    _ringingSubscription = Alarm.ringing.listen((alarms) {
      if (alarms.containsId(widget.alarmSettings.id)) return;
      _log.info('Alarm ${widget.alarmSettings.id} stopped ringing.');
      _ringingSubscription?.cancel();
      if (mounted) Navigator.pop(context);
    });
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
    _ringingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.errorContainer,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final medicationName = _medicationDetails?['medicationName'] ?? 'Zdravilo';
    final dosage = _medicationDetails?['dosage'] ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.errorContainer,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Kritično opozorilo',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vzemite $medicationName',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (dosage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        dosage,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.medication_rounded,
                size: 120,
                color: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await Alarm.stop(widget.alarmSettings.id);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Vzel/a sem',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Alarm.set(
                            alarmSettings: widget.alarmSettings.copyWith(
                              dateTime: DateTime.now().add(
                                const Duration(minutes: 5),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.snooze),
                        label: const Text(
                          'Opomni me čez 5 minut',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onErrorContainer,
                          side: BorderSide(
                            color: colorScheme.onErrorContainer,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
