import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../database/drift_database.dart';
import '../../data/services/appointment_service.dart';
import '../../main.dart' show db;

/// Full-screen silent reminder shown ~2 hours before an appointment.
/// No sound, but vibrates to alert the user when they open the phone.
class AppointmentRingScreen extends StatefulWidget {
  const AppointmentRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  @override
  State<AppointmentRingScreen> createState() => _AppointmentRingScreenState();
}

class _AppointmentRingScreenState extends State<AppointmentRingScreen>
    with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.lekec/lockscreen');
  Appointment? _appointment;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _autoStopTimer;

  /// Auto-stop ringing after 5 minutes
  static const _autoStopDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _showOverLockscreen(true);
    _loadAppointment();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _autoStopTimer = Timer(_autoStopDuration, _onAutoStop);
  }

  Future<void> _onAutoStop() async {
    await Alarm.stop(widget.alarmSettings.id);
  }

  Future<void> _showOverLockscreen(bool show) async {
    try {
      await platform.invokeMethod('showOverLockscreen', {'show': show});
    } catch (e) {
      // Ignore errors on non-Android platforms
    }
  }

  Future<void> _loadAppointment() async {
    // Alarm ID encodes the appointment: offset + appointmentId * 2 + 1
    final alarmId = widget.alarmSettings.id;
    final appointmentId =
        (alarmId - AppointmentService.notifIdOffset - 1) ~/ 2;

    try {
      final service = AppointmentService(db);
      final appt = await service.getAppointment(appointmentId);
      if (mounted) {
        setState(() {
          _appointment = appt;
        });
      }
    } catch (_) {
      // ignore — fallback values are shown
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _showOverLockscreen(false);
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) context.go('/');
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}. ${dt.month}. ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final title = _appointment?.title ?? 'Termin';
    final note = _appointment?.note;
    final appointmentTime = _appointment?.appointmentTime ?? DateTime.now();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.primary,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.primary, colors.primary.withOpacity(0.85)],
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OPOMNIK ZA TERMIN',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Symbols.close, color: colors.onPrimary),
                        onPressed: _dismiss,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pulsing calendar icon
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: colors.onPrimary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Symbols.calendar_month,
                                size: 64,
                                color: colors.onPrimary,
                                fill: 1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // "Čez 2 uri" badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.onPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Čez 2 uri',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Appointment title
                          Text(
                            title,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Date & time
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.onPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Symbols.schedule,
                                  color: colors.onPrimary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${_formatDate(appointmentTime)} ob ${_formatTime(appointmentTime)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Note
                          if (note != null && note.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colors.onPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                note,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colors.onPrimary.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Dismiss button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _dismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.onPrimary,
                        foregroundColor: colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.check_circle, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'RAZUMEM',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
