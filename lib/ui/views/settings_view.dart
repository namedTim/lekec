import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../features/core/providers/theme_provider.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Izgled aplikacije'),
                subtitle: Text(
                  themeMode.when(
                    data: (mode) => _getThemeModeName(mode),
                    loading: () => 'Pridobivanje nastavitve...',
                    error: (_, __) => 'NaN',
                  ),
                ),
                leading: const Icon(Symbols.brightness_6),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('Sistemska'),
                      icon: Icon(Symbols.brightness_auto),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Svetla'),
                      icon: Icon(Symbols.light_mode),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Temna'),
                      icon: Icon(Symbols.dark_mode),
                    ),
                  ],
                  selected: {themeMode.value ?? ThemeMode.system},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(newSelection.first);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Symbols.developer_mode),
            title: const Text('Developer Settings'),
            trailing: const Icon(Symbols.chevron_right),
            onTap: () {
              context.push('/dev');
            },
          ),
        ),
      ],
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistemska';
      case ThemeMode.light:
        return 'Svetla';
      case ThemeMode.dark:
        return 'Temna';
    }
  }
}
