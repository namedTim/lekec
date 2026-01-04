import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../features/dev/providers/dev_actions_provider.dart';
import '../../features/core/providers/database_provider.dart';
import '../../database/drift_database.dart';
import '../../data/services/notification_service.dart';

class DeveloperSettingsScreen extends ConsumerWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(devActionsProvider);
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Developer Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DevCard(
            icon: Symbols.delete_forever,
            color: Colors.red,
            title: "Clear Local Database",
            subtitle: "Deletes all tables and user data",
            onTap: () async {
              await actions.clearDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Database cleared")),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.add_chart,
            color: Colors.blue,
            title: "Insert Mock Data",
            subtitle: "Loads sample medications & schedules",
            onTap: () async {
              await actions.insertMockData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Mock data inserted")),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.bug_report,
            color: Colors.green,
            title: "Test Insert User",
            subtitle: "Insert test user and log output",
            onTap: () async {
              try {
                final insertedId = await db.into(db.users).insert(
                  UsersCompanion.insert(
                    name: 'Test User',
                  ),
                );

                final allUsers = await db.select(db.users).get();
                final output = 'Inserted user id: $insertedId\nAll users: $allUsers';
                print(output);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(output),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e, st) {
                final error = 'Error inserting user: $e\n$st';
                print(error);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.notifications_active,
            color: Colors.orange,
            title: "Test Immediate Notification",
            subtitle: "Show test notification right now",
            onTap: () async {
              final notificationService = NotificationService();
              await notificationService.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Test notification sent")),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.schedule,
            color: Colors.purple,
            title: "Test Scheduled Notification",
            subtitle: "Schedule notification for 10 seconds from now",
            onTap: () async {
              final notificationService = NotificationService();
              await notificationService.scheduleTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Notification scheduled for 10 seconds from now"),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.info,
            color: Colors.teal,
            title: "Check Pending Notifications",
            subtitle: "View count of scheduled notifications",
            onTap: () async {
              final notificationService = NotificationService();
              final count = await notificationService.getPendingNotificationsCount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Pending notifications: $count"),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.list_alt,
            color: Colors.indigo,
            title: "Log All Pending Notifications",
            subtitle: "Print all scheduled notifications to debug console",
            onTap: () async {
              final notificationService = NotificationService();
              await notificationService.logPendingNotifications();
              final count = await notificationService.getPendingNotificationsCount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Logged $count notifications to console"),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.alarm,
            color: Colors.amber,
            title: "Check Exact Alarm Permission",
            subtitle: "Verify if app can schedule exact alarms",
            onTap: () async {
              final notificationService = NotificationService();
              final canSchedule = await notificationService.checkExactAlarmPermission();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      canSchedule 
                        ? "✓ Exact alarm permission granted" 
                        : "✗ Exact alarm permission NOT granted - go to Settings"
                    ),
                    backgroundColor: canSchedule ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.timer,
            color: Colors.deepPurple,
            title: "Test 30-Second Notification",
            subtitle: "Alternative test with detailed logging (30s delay)",
            onTap: () async {
              final notificationService = NotificationService();
              await notificationService.scheduleBasicTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("30-second test scheduled - check logs"),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.info_i_rounded,
            color: Colors.brown,
            title: "Full Notification Diagnostic",
            subtitle: "Check all permissions and notification status",
            onTap: () async {
              final notificationService = NotificationService();
              final status = await notificationService.checkNotificationStatus();
              if (context.mounted) {
                final message = 'Initialized: ${status['initialized']}\n'
                    'Notifications enabled: ${status['notificationPermission']}\n'
                    'Exact alarm: ${status['canScheduleExact']}\n'
                    'Pending: ${status['pendingCount']}\n'
                    'Active: ${status['activeCount']}';
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Notification Status'),
                    content: Text(message),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Symbols.notifications_paused,
            color: Colors.cyan,
            title: "Test All Notification Intervals",
            subtitle: "Schedule 8 tests: 1, 2, 5, 7, 10, 20, 30 min, 1h",
            onTap: () async {
              final notificationService = NotificationService();
              await notificationService.scheduleMultipleTestNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Scheduled 8 test notifications - check logs"),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DevCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DevCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(.1),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Symbols.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
