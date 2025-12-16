import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dev/providers/dev_actions_provider.dart';

class DeveloperSettingsScreen extends ConsumerWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(devActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Developer Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DevCard(
            icon: Icons.delete_forever,
            color: Colors.red,
            title: "Clear Local Database",
            subtitle: "Deletes all tables and user data",
            onTap: () async {
              await actions.clearDatabase();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Database cleared")),
              );
            },
          ),
          const SizedBox(height: 16),
          _DevCard(
            icon: Icons.add_chart,
            color: Colors.blue,
            title: "Insert Mock Data",
            subtitle: "Loads sample medications & schedules",
            onTap: () async {
              await actions.insertMockData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mock data inserted")),
              );
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
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
