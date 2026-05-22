import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:alarm/alarm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../features/core/providers/theme_provider.dart';
import '../../features/core/providers/database_provider.dart';
import '../../database/drift_database.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/tip_screen.dart';

final alarmSoundsProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'name': '8-bit Arkada', 'file': '8bit_arcade.mp3'},
    {'name': 'Retro Piksel', 'file': 'return_to_8bit.mp3'},
    {'name': 'Nokia', 'file': 'nokia.mp3'},
    {'name': 'Marimba', 'file': 'marimba.mp3'},
    {'name': 'Mozart', 'file': 'mozart.mp3'},
    {'name': 'Star Wars', 'file': 'star_wars.mp3'},
    {'name': 'Budilka', 'file': 'alarm_clock.mp3'},
    {'name': 'Sirena', 'file': 'alarm_siren.mp3'},
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
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionLabel = 'Različica ${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {
      // Leave _versionLabel null; section will fall back to a placeholder.
    }
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
          assetAudioPath: 'assets/alarms/${_settings?.alarmSound ?? '8bit_arcade.mp3'}',
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
      assetAudioPath: 'assets/alarms/${_settings?.alarmSound ?? '8bit_arcade.mp3'}',
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 88),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: Text(
            'Nastavitve',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ── Izgled ────────────────────────────────────────────────────
        _SettingsSection(
          icon: Symbols.brightness_6,
          accent: const Color(0xFFF59E0B),
          title: 'Izgled aplikacije',
          subtitle: themeMode.when(
            data: (mode) => _getThemeModeName(mode),
            loading: () => 'Pridobivanje nastavitve...',
            error: (_, __) => '—',
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('Sistem'),
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
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Kritični opomniki ─────────────────────────────────────────
        _SettingsSection(
          icon: Symbols.alarm,
          accent: const Color(0xFFEF4444),
          title: 'Kritični opomniki',
          subtitle: 'Glasnost, melodija, vibracije',
          children: [
            // Volume slider
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Symbols.volume_up,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Glasnost',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${((_settings?.alarmVolume ?? 0.8) * 100).round()}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
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

            // Sound dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Symbols.music_note,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text('Melodija', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _settings?.alarmSound ?? '8bit_arcade.mp3',
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
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

            // Vibration toggle
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              secondary: Icon(
                Symbols.vibration,
                color: colors.onSurfaceVariant,
              ),
              title: const Text('Vibracije'),
              subtitle: const Text('Vibriraj ob alarmu'),
              value: _settings?.alarmVibration ?? true,
              onChanged: (value) {
                _updateSetting(
                  (_) => value,
                  (v) => AppSettingsCompanion(
                    alarmVibration: drift.Value(v),
                  ),
                  isAlarmSetting: true,
                );
              },
            ),

            // Test alarm
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _testAlarm,
                  icon: const Icon(Symbols.play_arrow, size: 20),
                  label: const Text('Testiraj alarm'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(
                      color: colors.primary.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Prenos podatkov ───────────────────────────────────────────
        _SettingsSection(
          icon: Symbols.sync_alt,
          accent: const Color(0xFF0EA5E9),
          title: 'Prenos podatkov',
          subtitle: 'Varnostna kopija ali obnovitev',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _exportDatabase,
                      icon: const Icon(Symbols.upload, size: 20),
                      label: const Text('Izvozi'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _importDatabase,
                      icon: const Icon(Symbols.download, size: 20),
                      label: const Text('Uvozi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(
                          color: colors.primary.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── O aplikaciji ──────────────────────────────────────────────
        _SettingsSection(
          icon: Symbols.info,
          accent: const Color(0xFF64748B),
          title: 'O aplikaciji',
          children: [
            _SettingsTile(
              icon: Symbols.favorite,
              accent: const Color(0xFFEC4899),
              filled: true,
              title: 'Podpri razvoj',
              subtitle: 'Neobvezen prispevek prek Google Play',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TipScreen()),
                );
              },
            ),
            Divider(
              height: 1,
              indent: 72,
              color: colors.outlineVariant.withOpacity(0.4),
            ),
            _SettingsTile(
              icon: Symbols.description,
              accent: const Color(0xFF64748B),
              title: 'Pogoji uporabe',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TermsOfServiceScreen(),
                  ),
                );
              },
            ),
            Divider(
              height: 1,
              indent: 72,
              color: colors.outlineVariant.withOpacity(0.4),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  Icon(
                    Symbols.info,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _versionLabel ?? 'Različica …',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dir.path, 'app_database.sqlite'));

    if (!await dbFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Baza podatkov ni bila najdena')),
        );
      }
      return;
    }

    final downloadsDir = Directory('/storage/emulated/0/Download');
    final exportPath = p.join(downloadsDir.path, 'lekec_backup.sqlite');
    await dbFile.copy(exportPath);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izvoženo v Downloads/lekec_backup.sqlite')),
      );
    }
  }

  Future<void> _importDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Symbols.warning, size: 48),
        title: const Text('Uvoz podatkov'),
        content: const Text(
          'Vsi trenutni podatki bodo prepisani z uvoženimi podatki. '
          'Tega dejanja ni mogoče razveljaviti.\n\n'
          'Ali želite nadaljevati?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Prekliči'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Uvozi in prepiši'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = File(result.files.single.path!);
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'app_database.sqlite');

    // Close current database before overwriting
    final db = ref.read(databaseProvider);
    await db.close();

    // Overwrite with imported file
    await pickedFile.copy(dbPath);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Podatki uvoženi. Aplikacija se mora znova zagnati.'),
        ),
      );

      // Give user time to see the message, then exit
      await Future.delayed(const Duration(seconds: 2));
      exit(0);
    }
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistem';
      case ThemeMode.light:
        return 'Svetla';
      case ThemeMode.dark:
        return 'Temna';
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.accent,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 22, fill: filled ? 1 : 0),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Symbols.chevron_right,
              color: colors.onSurfaceVariant.withOpacity(0.6),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
