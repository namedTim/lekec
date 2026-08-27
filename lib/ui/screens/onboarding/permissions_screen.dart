import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../services/permission.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionsScreen({super.key, required this.onComplete});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _requesting = false;

  Future<void> _requestPermissions() async {
    if (_requesting) return;
    setState(() => _requesting = true);

    await AlarmPermissions.checkNotificationPermission();
    await AlarmPermissions.checkAndroidScheduleExactAlarmPermission();
    await AlarmPermissions.checkFullScreenIntentPermission();
    await AlarmPermissions.checkIgnoreBatteryOptimizations();

    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.primary, width: 2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Symbols.notifications_active,
                            size: 64,
                            color: colors.primary,
                            fill: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'Dovoljenja za zanesljive opomnike',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Da vas Lekec lahko pravočasno opomni na jemanje '
                        'zdravil, potrebujemo nekaj dovoljenj. Brez njih '
                        'opomniki ne bodo delovali pravilno.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 32),

                      _PermissionItem(
                        icon: Symbols.notifications,
                        title: 'Obvestila',
                        description:
                            'Da vas obvestimo, kdaj je čas za jemanje zdravila.',
                        colors: colors,
                      ),
                      const SizedBox(height: 20),
                      _PermissionItem(
                        icon: Symbols.alarm,
                        title: 'Točni opomniki',
                        description:
                            'Da se opomniki sprožijo na natančno določen čas.',
                        colors: colors,
                      ),
                      const SizedBox(height: 20),
                      _PermissionItem(
                        icon: Symbols.lock_open,
                        title: 'Prikaz pri zaklenjenem zaslonu',
                        description:
                            'Da se opomnik prikaže tudi, ko je zaslon ugasnjen.',
                        colors: colors,
                      ),
                      const SizedBox(height: 20),
                      _PermissionItem(
                        icon: Symbols.battery_charging_full,
                        title: 'Neprekinjeno delovanje',
                        description:
                            'Da telefon ne ustavi opomnikov v načinu varčevanja.',
                        colors: colors,
                      ),

                      const SizedBox(height: 28),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Symbols.info,
                              color: colors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ko pritisnete "Dovoli", se bodo prikazala '
                                'sistemska okna. Prosimo, dovolite vsako — '
                                'pravilno delovanje opomnikov je ključno za '
                                'varno jemanje zdravil.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              FilledButton(
                onPressed: _requesting ? null : _requestPermissions,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _requesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Dovoli',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colors;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: colors.primary, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
