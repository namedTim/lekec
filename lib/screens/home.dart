import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:lekec/screens/edit_alarm.dart';
import 'package:lekec/screens/shortcut_button.dart';
import 'package:lekec/services/alarm_service.dart';
import 'package:lekec/services/notifications.dart';
import 'package:lekec/services/permission.dart';
import 'package:lekec/widgets/tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

const version = '5.1.5';

class ExampleAlarmHomeScreen extends ConsumerStatefulWidget {
  const ExampleAlarmHomeScreen({super.key});

  @override
  ConsumerState<ExampleAlarmHomeScreen> createState() => _ExampleAlarmHomeScreenState();
}

class _ExampleAlarmHomeScreenState extends ConsumerState<ExampleAlarmHomeScreen> {
  Notifications? notifications;

  @override
  void initState() {
    super.initState();
    AlarmPermissions.checkNotificationPermission().then(
      (_) => AlarmPermissions.checkAndroidScheduleExactAlarmPermission(),
    );
    notifications = Notifications();
  }

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: ExampleAlarmEditScreen(alarmSettings: settings),
        );
      },
    );

    if (res != null && res == true) {
      await ref.read(alarmsProvider.notifier).loadAlarms();
    }
  }

  Future<void> launchReadmeUrl() async {
    final url = Uri.parse('https://pub.dev/packages/alarm/versions/$version');
    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('alarm $version'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: launchReadmeUrl,
          ),
          PopupMenuButton<String>(
            onSelected: notifications == null
                ? null
                : (value) async {
                    if (value == 'Show notification') {
                      await notifications?.showNotification();
                    } else if (value == 'Schedule notification') {
                      await notifications?.scheduleNotification();
                    }
                  },
            itemBuilder: (BuildContext context) =>
                {'Show notification', 'Schedule notification'}
                    .map(
                      (String choice) => PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: alarms.isNotEmpty
                  ? ListView.separated(
                      itemCount: alarms.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return ExampleAlarmTile(
                          key: Key(alarms[index].id.toString()),
                          title: TimeOfDay(
                            hour: alarms[index].dateTime.hour,
                            minute: alarms[index].dateTime.minute,
                          ).format(context),
                          onPressed: () => navigateToAlarmScreen(alarms[index]),
                          onDismissed: () {
                            ref.read(alarmsProvider.notifier).stopAlarm(alarms[index].id);
                          },
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No alarms set',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ExampleAlarmHomeShortcutButton(
              refreshAlarms: () => ref.read(alarmsProvider.notifier).loadAlarms(),
            ),
            FloatingActionButton(
              onPressed: () => ref.read(alarmsProvider.notifier).stopAllAlarms(),
              backgroundColor: Colors.red,
              heroTag: null,
              child: const Text(
                'STOP ALL',
                textScaler: TextScaler.linear(0.9),
                textAlign: TextAlign.center,
              ),
            ),
            FloatingActionButton(
              onPressed: () => navigateToAlarmScreen(null),
              child: const Icon(Icons.alarm_add_rounded, size: 33),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
