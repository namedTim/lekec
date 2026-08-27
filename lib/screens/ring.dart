import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

class ExampleAlarmRingScreen extends StatefulWidget {
  const ExampleAlarmRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  @override
  State<ExampleAlarmRingScreen> createState() => _ExampleAlarmRingScreenState();
}

class _ExampleAlarmRingScreenState extends State<ExampleAlarmRingScreen> {
  static final _log = Logger('ExampleAlarmRingScreenState');

  StreamSubscription<AlarmSet>? _ringingSubscription;

  @override
  void initState() {
    super.initState();
    _ringingSubscription = Alarm.ringing.listen((alarms) {
      if (alarms.containsId(widget.alarmSettings.id)) return;
      _log.info('Alarm ${widget.alarmSettings.id} stopped ringing.');
      _ringingSubscription?.cancel();
      if (mounted) context.pop();
    });
  }

  @override
  void dispose() {
    _ringingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Your alarm is ringing!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Alarm ID: ${widget.alarmSettings.id}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
              const Text('🔔', style: TextStyle(fontSize: 120)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await Alarm.set(
                        alarmSettings: widget.alarmSettings.copyWith(
                          dateTime: DateTime.now().add(const Duration(minutes: 1)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.snooze, size: 32),
                        SizedBox(height: 8),
                        Text('Snooze', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await Alarm.stop(widget.alarmSettings.id);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop_circle, size: 32),
                        SizedBox(height: 8),
                        Text('Stop', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
