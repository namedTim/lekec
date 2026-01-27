import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:alarm/alarm.dart';
import '../../features/core/providers/theme_provider.dart';
import '../../features/core/providers/database_provider.dart';
import '../../database/drift_database.dart';
import '../../services/alarm_service.dart';

final alarmSoundsProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'name': 'Nokia', 'file': 'nokia.mp3'},
    {'name': 'Marimba', 'file': 'marimba.mp3'},
    {'name': 'Mozart', 'file': 'mozart.mp3'},
    {'name': 'One Piece', 'file': 'one_piece.mp3'},
    {'name': 'Star Wars', 'file': 'star_wars.mp3'},
  ];
});

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  AppSetting? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = ref.read(databaseProvider);
    final settings = await (db.select(
      db.appSettings,
    )..limit(1)).getSingleOrNull();

    if (settings == null) {
      // Create default settings
      await db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(themeMode: const drift.Value('system')),
          );
      await _loadSettings();
      return;
    }

    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting<T>(
    T Function(AppSetting) getValue,
    AppSettingsCompanion Function(T) createCompanion,
    {bool isAlarmSetting = false}
  ) async {
    if (_settings == null) return;

    final db = ref.read(databaseProvider);
    await (db.update(db.appSettings)..where((t) => t.id.equals(_settings!.id)))
        .write(createCompanion(getValue(_settings!)));

    await _loadSettings();

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nastavitve shranjene'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // If this is an alarm setting, reschedule all existing critical alarms in background
    if (isAlarmSetting) {
      _rescheduleAllAlarms(db);
    }
  }

  Future<void> _rescheduleAllAlarms(AppDatabase db) async {
    // Get all upcoming critical medication intakes
    final now = DateTime.now();
    final upcomingIntakes = await (db.select(db.medicationIntakeLogs)
          ..where((log) => log.scheduledTime.isBiggerThanValue(now))
          ..where((log) => log.wasTaken.equals(false)))
        .get();

    for (final intake in upcomingIntakes) {
      // Get medication to check if it has critical reminder
      final medication = await (db.select(db.medications)
            ..where((m) => m.id.equals(intake.medicationId)))
          .getSingleOrNull();

      if (medication != null && medication.criticalReminder) {
        // Cancel existing alarm
        await Alarm.stop(intake.id);

        // Get plan for dosage info
        final plan = await (db.select(db.medicationPlans)
              ..where((p) => p.id.equals(intake.planId)))
            .getSingleOrNull();

        String dosage = '';
        if (plan != null) {
          final dosageCount = plan.dosageAmount.toInt();
          dosage = '$dosageCount';
        }

        // Reschedule with new settings
        final alarmSettings = AlarmSettings(
          id: intake.id,
          dateTime: intake.scheduledTime,
          assetAudioPath: 'assets/${_settings?.alarmSound ?? 'nokia.mp3'}',
          loopAudio: true,
          vibrate: _settings?.alarmVibration ?? true,
          androidFullScreenIntent: true,
          volumeSettings: VolumeSettings.fixed(
            volume: _settings?.alarmVolume ?? 0.8,
          ),
          notificationSettings: NotificationSettings(
            title: 'Kritično: Vzemite ${medication.name}',
            body: dosage.isNotEmpty ? 'Vzemite $dosage' : 'Čas za jemanje zdravila',
            stopButton: 'Zaustavi',
            icon: 'notification_icon',
          ),
        );

        await Alarm.set(alarmSettings: alarmSettings);
      }
    }
  }

  Future<void> _testAlarm() async {
    final alarmSettings = AlarmSettings(
      id: 999999,
      dateTime: DateTime.now().add(const Duration(seconds: 2)),
      assetAudioPath: 'assets/${_settings?.alarmSound ?? 'nokia.mp3'}',
      loopAudio: true,
      warningNotificationOnKill: false,
      vibrate: _settings?.alarmVibration ?? true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fixed(
        volume: _settings?.alarmVolume ?? 0.8,
      ),
      notificationSettings: const NotificationSettings(
        title: 'Test Alarm',
        body: 'To je testni alarm',
        stopButton: 'Zaustavi',
        icon: 'notification_icon',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testni alarm se bo sprožil čez 2 sekundi'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final alarmSounds = ref.watch(alarmSoundsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Theme Settings
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

        // Critical Alarms Settings
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Symbols.alarm, color: colors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Kritični opomniki',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Volume Slider
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Symbols.volume_up, size: 20),
                        const SizedBox(width: 8),
                        Text('Glasnost', style: theme.textTheme.bodyLarge),
                        const Spacer(),
                        Text(
                          '${((_settings?.alarmVolume ?? 0.8) * 100).round()}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _settings?.alarmVolume ?? 0.8,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        _updateSetting(
                          (_) => value,
                          (v) =>
                              AppSettingsCompanion(alarmVolume: drift.Value(v)),
                          isAlarmSetting: true,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Alarm Sound Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Symbols.music_note, size: 20),
                        const SizedBox(width: 8),
                        Text('Melodija', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _settings?.alarmSound ?? 'nokia.mp3',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: alarmSounds.map((sound) {
                        return DropdownMenuItem<String>(
                          value: sound['file'],
                          child: Text(sound['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updateSetting(
                            (_) => value,
                            (v) => AppSettingsCompanion(
                              alarmSound: drift.Value(v),
                            ),
                            isAlarmSetting: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Vibration Toggle
              SwitchListTile(
                secondary: const Icon(Symbols.vibration),
                title: const Text('Vibracije'),
                subtitle: const Text('Vibriraj ob alarmu'),
                value: _settings?.alarmVibration ?? true,
                onChanged: (value) {
                  _updateSetting(
                    (_) => value,
                    (v) => AppSettingsCompanion(alarmVibration: drift.Value(v)),
                    isAlarmSetting: true,
                  );
                },
              ),

              const Divider(height: 1),

              // Test Alarm Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _testAlarm,
                    icon: const Icon(Symbols.play_arrow),
                    label: const Text('Testiraj alarm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: theme.brightness == Brightness.dark 
                          ? Colors.black 
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Notification Settings
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Symbols.notifications, color: colors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Obvestila',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Symbols.warning),
                title: const Text('Opozorilo za zaprtje'),
                subtitle: const Text('Pokaži obvestilo za zaprtje aplikacije'),
                value: _settings?.showKillWarning ?? true,
                onChanged: (value) async {
                  await _updateSetting(
                    (_) => value,
                    (v) =>
                        AppSettingsCompanion(showKillWarning: drift.Value(v)),
                  );

                  // Reload all alarms in background
                  final alarmService = ref.read(alarmServiceProvider);
                  alarmService.reloadAllAlarms();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Developer Settings
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
