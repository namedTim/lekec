import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/drift_database.dart';
import '../../main.dart' show db;
import '../../helpers/medication_unit_helper.dart';
import '../../ui/widgets/medication_card.dart';
import '../../ui/widgets/medication_detail_dialog.dart';
import '../../ui/components/confirmation_dialog.dart';
import '../../data/services/intake_log_service.dart';
import '../../data/services/mood_service.dart';
import '../../ui/widgets/time_island.dart';
import '../../ui/widgets/appointment_card.dart';
import '../../ui/components/time_slot.dart';
import '../../ui/widgets/empty_state_card.dart';
import '../../ui/components/mood_logging_sheet.dart';
import 'add_appointment_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.title});
  final String title;

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final controller = TimeIslandController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  Map<String, List<Map<String, dynamic>>> _groupedIntakes = {};
  late IntakeLogService _intakeService;
  int _totalUserCount = 0;
  Map<int, String> _userNames = {};

  // Time Island state
  Map<String, dynamic>? _nextMedication;
  Timer? _islandUpdateTimer;
  Timer? _dayChangeTimer;

  List<AlarmSettings> alarms = [];

  @override
  void initState() {
    super.initState();
    _intakeService = IntakeLogService(db);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadUserData();
    loadTodaysIntakes();
    _updateTimeIsland();
    _startIslandUpdateTimer();
    _startDayChangeTimer();
    loadAlarms();
  }

  Future<void> loadAlarms() async {
    final updatedAlarms = await Alarm.getAlarms();
    updatedAlarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    setState(() {
      alarms = updatedAlarms;
    });
  }

  Future<void> _loadUserData() async {
    final users = await (db.select(
      db.users,
    )..where((t) => t.isActive.equals(true))).get();
    if (mounted) {
      setState(() {
        _totalUserCount = users.length;
        _userNames = {for (var user in users) user.id: user.name};
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _islandUpdateTimer?.cancel();
    _dayChangeTimer?.cancel();
    super.dispose();
  }

  void _startDayChangeTimer() {
    // Calculate time until midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Schedule refresh at midnight
    _dayChangeTimer = Timer(timeUntilMidnight, () {
      if (mounted) {
        loadTodaysIntakes();
        // Restart timer for next day
        _startDayChangeTimer();
      }
    });
  }

  void _startIslandUpdateTimer() {
    // Update every second to keep island fresh
    _islandUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeIsland();
    });
  }

  Future<void> _updateTimeIsland() async {
    final nextMed = await _intakeService.getNextMedication();
    if (mounted) {
      setState(() {
        _nextMedication = nextMed;
      });
      controller.update();
    }
  }

  Future<void> loadTodaysIntakes({bool autoScroll = true}) async {
    final grouped = await _intakeService.loadTodaysIntakes();
    
    // Also load today's appointments
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    // Filter to today's appointments (upcoming service only returns future, so also fetch past-today)
    final allAppts = await (db.select(db.appointments)
      ..where((t) => t.appointmentTime.isBiggerOrEqualValue(startOfDay))
      ..where((t) => t.appointmentTime.isSmallerThanValue(endOfDay))
      ..orderBy([(t) => OrderingTerm.asc(t.appointmentTime)]))
      .get();

    // Merge appointments into grouped map
    for (final appt in allAppts) {
      final timeKey =
          '${appt.appointmentTime.hour.toString().padLeft(2, '0')}:${appt.appointmentTime.minute.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(timeKey, () => []);
      grouped[timeKey]!.add({
        'isAppointment': true,
        'appointment': appt,
      });
    }

    // Re-sort the grouped map by time key
    final sortedGrouped = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    setState(() {
      _groupedIntakes = sortedGrouped;
    });

    // Update time island after loading intakes
    await _updateTimeIsland();

    // Scroll to next intake only if autoScroll is true
    if (autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToNextIntake();
      });
    }
  }

  void _scrollToNextIntake() {
    if (_groupedIntakes.isEmpty) return;

    final now = DateTime.now();
    final times = _groupedIntakes.keys.toList();

    // Find the next upcoming time
    int nextIndex = times.indexWhere((timeStr) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeToday = DateTime(now.year, now.month, now.day, hour, minute);
      return timeToday.isAfter(now);
    });

    if (nextIndex > 0 && _scrollController.hasClients) {
      // Scroll to show the next time slot near the top
      // Each time slot + cards is roughly 100-150px, adjust as needed
      final offset = (nextIndex * 120.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void scrollToIntake(int intakeId) {
    if (_groupedIntakes.isEmpty || !_scrollController.hasClients) return;

    // Find the time slot containing this intake
    int targetIndex = -1;
    for (int i = 0; i < _groupedIntakes.keys.length; i++) {
      final timeKey = _groupedIntakes.keys.elementAt(i);
      final intakes = _groupedIntakes[timeKey] ?? [];
      if (intakes.any((intake) => intake['intake'].id == intakeId)) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex >= 0) {
      // Scroll to the time slot containing the intake
      final offset = (targetIndex * 120.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _deleteOneTimeEntry(int intakeId) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Izbriši vnos',
      message: 'Ali ste prepričani, da želite izbrisati ta enkraten vnos?',
      confirmText: 'Izbriši',
    );

    if (!confirmed) return;

    try {
      await _intakeService.deleteOneTimeEntry(intakeId);
      await loadTodaysIntakes(autoScroll: false);

      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vnos izbrisan',
              style: TextStyle(color: colors.onSurface),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: colors.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Napaka: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showMedicationDetail({
    required String medName,
    required String dosage,
    required DateTime scheduledTime,
    required double dosageAmount,
    required int? pillsRemaining,
    required String userName,
  }) {
    showDialog(
      context: context,
      builder: (context) => MedicationDetailDialog(
        medName: medName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        dosageAmount: dosageAmount,
        pillsRemaining: pillsRemaining,
        userName: userName,
      ),
    );
  }

  Future<void> _updateIntakeStatus(
    int intakeId,
    MedicationStatus newStatus,
  ) async {
    try {
      final wasTaken = newStatus == MedicationStatus.taken;
      await _intakeService.updateIntakeStatus(intakeId, wasTaken);
      await loadTodaysIntakes(autoScroll: false);

      // Update time island immediately after taking medication
      await _updateTimeIsland();

      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasTaken
                  ? 'Vnos zdravila zabeležen'
                  : 'Zdravilo označeno kot ne-vzeto',
              style: TextStyle(color: colors.onSurface),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: colors.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Napaka: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleSpeedDial() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _ensureSpeedDialClosed() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
    }
  }

  void _onAddSingleEntry() async {
    _toggleSpeedDial();
    await context.push('/add-single-entry');
    _ensureSpeedDialClosed();
    // Refresh after returning from adding entry
    await loadTodaysIntakes(autoScroll: false);
  }

  void _onAddNewMedication() async {
    _toggleSpeedDial();
    await context.push('/add-medication');
    _ensureSpeedDialClosed();
    // Refresh after returning — medication or new user may have been added
    await _loadUserData();
    await loadTodaysIntakes(autoScroll: false);
  }

  void _onAddAppointment() async {
    _toggleSpeedDial();
    final userId = await _pickUser();
    if (userId == null || !mounted) return;
    await context.push('/add-appointment', extra: {'userId': userId});
    _ensureSpeedDialClosed();
    // Refresh to show new appointment in daily view
    await loadTodaysIntakes(autoScroll: false);
  }

  /// Pick a user if multiple users exist, or auto-select the only user
  Future<int?> _pickUser() async {
    if (_userNames.length == 1) {
      return _userNames.keys.first;
    }

    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colors = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Izberite uporabnika',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._userNames.entries.map((entry) {
                return ListTile(
                  leading: Icon(Symbols.person, color: colors.primary),
                  title: Text(entry.value),
                  onTap: () => Navigator.of(ctx).pop(entry.key),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _onLogMood() async {
    _toggleSpeedDial();

    final userId = await _pickUser();
    if (userId == null || !mounted) return;

    final result = await showMoodLoggingSheet(context: context);
    _ensureSpeedDialClosed();
    if (result == null || !mounted) return;

    try {
      final moodService = MoodService(db);
      await moodService.logMood(
        userId: userId,
        moodLevel: result['moodLevel'] as int,
        note: result['note'] as String?,
      );

      if (mounted) {
        final emoji = MoodService.moodEmojis[result['moodLevel'] as int]!;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$emoji Razpoloženje zabeleženo'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Napaka: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Pre-compute running remaining count per intake
    // Walk all intakes in time order, decrement per medication
    final Map<int, int> _runningRemaining = {};
    {
      final Map<int, double> medRunning = {}; // medicationId → running count
      for (final timeKey in _groupedIntakes.keys) {
        for (final intakeData in _groupedIntakes[timeKey]!) {
          // Skip appointment items
          if (intakeData['isAppointment'] == true) continue;

          final medication = intakeData['medication'] as Medication;
          final plan = intakeData['plan'] as MedicationPlan?;
          final intake = intakeData['intake'] as MedicationIntakeLog;
          // Use intake's dosageAmount if set (for as-needed entries), otherwise plan's
          final dosageAmount = intake.dosageAmount ?? plan?.dosageAmount ?? 1.0;

          // Initialize with medication's current remaining if first encounter
          if (!medRunning.containsKey(medication.id)) {
            medRunning[medication.id] = (medication.dosagesRemaining ?? 0)
                .toDouble();
          }

          // Decrement and store for this intake
          medRunning[medication.id] = medRunning[medication.id]! - dosageAmount;
          _runningRemaining[intake.id] = medRunning[medication.id]!.toInt();
        }
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _nextMedication != null
                      ? TimeIsland(
                          medicationName:
                              (_nextMedication!['medication'] as Medication)
                                  .name,
                          totalDuration: const Duration(minutes: 30),
                          remainingDuration:
                              _nextMedication!['timeUntil'] as Duration,
                          isOverdue: _nextMedication!['isOverdue'] as bool,
                          controller: controller,
                        )
                      : TimeIsland(
                          totalDuration: const Duration(minutes: 30),
                          remainingDuration: const Duration(minutes: 30),
                          isOverdue: false,
                          controller: controller,
                        ),
                ),
              ),
              Expanded(
                child: _groupedIntakes.isEmpty
                    ? Center(
                        child: EmptyStateCard(
                          icon: Symbols.event_available,
                          title: 'Ni načrtovanih vnosov za danes',
                          subtitle: 'Dodajte zdravila ali termine',
                          onTap: () => context.push('/add-medication'),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 88.0,
                        ),
                        itemCount: _groupedIntakes.length,
                        itemBuilder: (context, index) {
                          final timeKey = _groupedIntakes.keys.elementAt(index);
                          final intakesAtTime = _groupedIntakes[timeKey]!;

                          // Determine if this time slot is in the past
                          final now = DateTime.now();
                          final parts = timeKey.split(':');
                          final hour = int.parse(parts[0]);
                          final minute = int.parse(parts[1]);
                          final slotTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            hour,
                            minute,
                          );
                          // Add 10 minute grace period before marking as "not taken"
                          final gracePeriodEnd = slotTime.add(
                            const Duration(minutes: 10),
                          );
                          // 10 minute window for green border
                          final borderWindowEnd = slotTime.add(
                            const Duration(minutes: 10),
                          );
                          final isPast = slotTime.isBefore(now);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TimeSlot(time: timeKey, isPast: isPast),
                              ...intakesAtTime.map((intakeData) {
                                // Check if this is an appointment item
                                if (intakeData['isAppointment'] == true) {
                                  final appt = intakeData['appointment'] as Appointment;
                                  final userName = _userNames[appt.userId] ?? '';
                                  // Show green border in the 10-min window before the appointment
                                  final isApptActive = now.isAfter(slotTime) && now.isBefore(borderWindowEnd);
                                  return AppointmentCard(
                                    title: appt.title,
                                    note: appt.note,
                                    appointmentTime: appt.appointmentTime,
                                    userName: userName,
                                    showName: _totalUserCount > 1,
                                    isPast: isPast,
                                    isActive: isApptActive,
                                    onTap: () async {
                                      final result = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => AddAppointmentScreen(
                                            userId: appt.userId,
                                            existingAppointment: appt,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        await loadTodaysIntakes(autoScroll: false);
                                      }
                                    },
                                  );
                                }

                                final medication =
                                    intakeData['medication'] as Medication;
                                final plan =
                                    intakeData['plan'] as MedicationPlan?;
                                final intake =
                                    intakeData['intake'] as MedicationIntakeLog;
                                final isOneTime =
                                    intakeData['isOneTimeEntry'] as bool;

                                // Determine status based on wasTaken and time
                                MedicationStatus status;
                                if (intake.wasTaken) {
                                  status = MedicationStatus.taken;
                                } else if (intake.takenTime != null) {
                                  // User explicitly marked as not taken (takenTime is set but wasTaken is false)
                                  status = MedicationStatus.notTaken;
                                } else if (now.isAfter(gracePeriodEnd)) {
                                  // Automatically mark as not taken after 10 minute grace period
                                  status = MedicationStatus.notTaken;
                                } else if (isPast) {
                                  // During grace period - show as upcoming (clock) if user hasn't acted yet
                                  status = MedicationStatus.upcoming;
                                } else {
                                  // Future medication (time hasn't arrived yet)
                                  status = MedicationStatus.upcoming;
                                }

                                // Check if this is the next medication to take
                                // Show border only when: time has arrived, within 10 min window, not yet taken
                                final isInBorderWindow =
                                    now.isAfter(slotTime) &&
                                    now.isBefore(borderWindowEnd);
                                final isNextMed =
                                    _nextMedication != null &&
                                    (_nextMedication!['intake']
                                                as MedicationIntakeLog?)
                                            ?.id ==
                                        intake.id &&
                                    status == MedicationStatus.upcoming &&
                                    isInBorderWindow;

                                // For as-needed entries, dosage is stored in the intake log
                                // Otherwise, use plan dosage
                                final dosageAmount =
                                    intake.dosageAmount ??
                                    plan?.dosageAmount ??
                                    1.0;
                                final dosageCount = dosageAmount.toInt();

                                // Get user name
                                final userName =
                                    _userNames[intake.userId] ?? 'Unknown';

                                // Get pre-computed running remaining for this intake
                                final remainingAfterDose =
                                    _runningRemaining[intake.id] ?? 0;

                                // Enable swipes only if time has passed (isPast)
                                // For future medications, disable swiping
                                // For one-time entries, only enable left swipe (delete)
                                final canSwipeScheduled = isPast && !isOneTime;
                                final canDeleteOneTime = isPast && isOneTime;

                                return MedicationCard(
                                  medName: medication.name,
                                  dosage:
                                      '$dosageCount ${getMedicationUnit(medication.medType, dosageCount)}',
                                  medicineRemaining: remainingAfterDose > 0
                                      ? 'še ${remainingAfterDose} ${getMedicationUnitShort(medication.medType, remainingAfterDose)}'
                                      : '',
                                  pillCount: remainingAfterDose,
                                  showName: _totalUserCount > 1,
                                  username: userName,
                                  userId: intake.userId.toString(),
                                  status: status,
                                  isOneTimeEntry: isOneTime,
                                  enableLeftSwipe:
                                      canSwipeScheduled || canDeleteOneTime,
                                  enableRightSwipe: canSwipeScheduled,
                                  isNextMedication: isNextMed,
                                  onTap: () {
                                    _showMedicationDetail(
                                      medName: medication.name,
                                      dosage:
                                          '$dosageCount ${getMedicationUnit(medication.medType, dosageCount)}',
                                      scheduledTime: intake.scheduledTime,
                                      dosageAmount: dosageAmount,
                                      pillsRemaining: remainingAfterDose > 0
                                          ? remainingAfterDose
                                          : null,
                                      userName: userName,
                                    );
                                  },
                                  onStatusChanged: isOneTime
                                      ? null
                                      : (newStatus) async {
                                          await _updateIntakeStatus(
                                            intake.id,
                                            newStatus,
                                          );
                                        },
                                  onDelete: isOneTime
                                      ? () async {
                                          await _deleteOneTimeEntry(intake.id);
                                        }
                                      : null,
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          // Full-screen barrier when FAB is expanded
          if (_isExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_isExpanded) {
                    _toggleSpeedDial();
                  }
                },
                child: Container(color: Colors.black.withOpacity(0.01)),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Speed dial options
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              if (!_isExpanded && _animation.value == 0) {
                return const SizedBox.shrink();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Option 2: Add new medication
                  Transform.scale(
                    scale: _animation.value,
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: _animation.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Dodaj novo zdravilo',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FloatingActionButton(
                              heroTag: 'add_medication',
                              mini: true,
                              onPressed: _onAddNewMedication,
                              child: const Icon(Symbols.pill),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Option 1: Add single entry
                  Transform.scale(
                    scale: _animation.value,
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: _animation.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Dodaj enkraten vnos zdravila',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FloatingActionButton(
                              heroTag: 'add_entry',
                              mini: true,
                              onPressed: _onAddSingleEntry,
                              child: const Icon(Symbols.add),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Option: Log mood
                  Transform.scale(
                    scale: _animation.value,
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: _animation.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Zabeleži razpoloženje',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FloatingActionButton(
                              heroTag: 'log_mood',
                              mini: true,
                              onPressed: _onLogMood,
                              child: const Text(
                                '😊',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Option: Add appointment
                  Transform.scale(
                    scale: _animation.value,
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: _animation.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Dodaj termin',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FloatingActionButton(
                              heroTag: 'add_appointment',
                              mini: true,
                              onPressed: _onAddAppointment,
                              child: const Icon(Symbols.calendar_add_on),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Main FAB
          FloatingActionButton(
            heroTag: 'main_fab',
            onPressed: _toggleSpeedDial,
            tooltip: 'Dodaj',
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                bottomLeft: Radius.circular(32),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Symbols.add),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
