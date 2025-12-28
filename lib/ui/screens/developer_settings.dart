import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../features/dev/providers/dev_actions_provider.dart';
import '../../features/core/providers/database_provider.dart';
import '../../database/drift_database.dart';

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
