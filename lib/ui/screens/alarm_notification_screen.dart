import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:alarm/alarm.dart';
import '../../database/tables/medications.dart';
import '../../helpers/medication_unit_helper.dart';
import '../../main.dart' show homePageKey, rootNavigatorKey;
import 'package:go_router/go_router.dart';

class AlarmNotificationScreen extends StatefulWidget {
  final int intakeId;
  final int medicationId;
  final String medicationName;
  final String dosage;
  final MedicationType medType;
  final DateTime scheduledTime;

  const AlarmNotificationScreen({
    super.key,
    required this.intakeId,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.medType,
    required this.scheduledTime,
  });

  @override
  State<AlarmNotificationScreen> createState() =>
      _AlarmNotificationScreenState();
}

class _AlarmNotificationScreenState extends State<AlarmNotificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    // Stop the alarm
    await Alarm.stop(widget.intakeId);

    // Navigate to home page and scroll to intake
    if (mounted) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        // Close this screen
        Navigator.of(context).pop();

        // Navigate to home page
        context.go('/');

        // Wait for navigation to complete, then scroll to the intake
        Future.delayed(const Duration(milliseconds: 300), () {
          homePageKey.currentState?.scrollToIntake(widget.intakeId);
        });
      }
    }
  }

  String _getTimeText() {
    final now = DateTime.now();
    final scheduled = widget.scheduledTime;

    if (now.difference(scheduled).inMinutes < 1) {
      return 'ZDAJ';
    } else if (now.isAfter(scheduled)) {
      final diff = now.difference(scheduled);
      if (diff.inHours > 0) {
        return '${diff.inHours} ur zamude';
      } else {
        return '${diff.inMinutes} min zamude';
      }
    } else {
      return '${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.error,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.error, colors.error.withOpacity(0.8)],
            ),
          ),
          child: Column(
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OPOMNIK ZA ZDRAVILO',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onError,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Symbols.close, color: colors.onError),
                      onPressed: _stopAlarm,
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
                        // Pulsing alarm icon
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: colors.onError.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Symbols.alarm,
                              size: 64,
                              color: colors.onError,
                              fill: 1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Time indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colors.onError.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getTimeText(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colors.onError,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Medication name
                        Text(
                          widget.medicationName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colors.onError,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Dosage info
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colors.onError.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Symbols.medication,
                                color: colors.onError,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.dosage,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colors.onError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stop button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _stopAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.onError,
                          foregroundColor: colors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Symbols.alarm_off, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'USTAVI ALARM',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pritisnite za zaustavitev alarma',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onError.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
