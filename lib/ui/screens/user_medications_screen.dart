import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:alarm/alarm.dart';
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import '../../helpers/user_color_helper.dart';
import '../../data/services/medication_service.dart';
import '../../data/services/mood_service.dart';
import '../../data/services/water_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/appointment_service.dart';
import '../../helpers/medication_unit_helper.dart';
import '../widgets/medication_details_card.dart';
import '../widgets/empty_state_card.dart';
import '../components/confirmation_dialog.dart';
import '../components/mood_logging_sheet.dart';
import '../components/water_logging_sheet.dart';
import '../../main.dart' show db, homePageKey, medsPageKey;
import '../../data/services/intake_log_service.dart';
import '../screens/add_appointment_screen.dart';
import '../components/log_intake_sheet.dart';

class UserMedicationsScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userName;

  const UserMedicationsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<UserMedicationsScreen> createState() =>
      UserMedicationsScreenState();
}

class UserMedicationsScreenState extends ConsumerState<UserMedicationsScreen> {
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  // Mood tracking state
  List<Map<String, dynamic>> _moodHistory = [];
  double? _averageMood;
  MoodEntry? _todaysMood;

  // Appointments state
  List<Appointment> _appointments = [];

  // Water tracking state
  int _waterTodayMl = 0;
  List<Map<String, dynamic>> _waterDailyTotals = [];
  List<WaterIntakeLog> _waterTodayEntries = [];
  WaterSettings _waterSettings = WaterSettings.defaults;

  @override
  void initState() {
    super.initState();
    _loadUserMedications();
    _loadMoodData();
    _loadAppointments();
    _loadWaterData();
  }

  /// Re-fetch everything this screen displays. Called from outside via the
  /// global key (e.g. after an appointment is added from the dashboard speed
  /// dial while this screen is alive in another tab branch).
  void refresh() {
    _loadUserMedications();
    _loadMoodData();
    _loadAppointments();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    try {
      final service = WaterService(db);
      final total = await service.getTodayTotal(widget.userId);
      final daily = await service.getDailyTotals(widget.userId, days: 7);
      final entries = await service.getTodayEntries(widget.userId);
      final settings = await service.getSettings(widget.userId);

      if (mounted) {
        setState(() {
          _waterTodayMl = total;
          _waterDailyTotals = daily;
          _waterTodayEntries = entries;
          _waterSettings = settings;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMoodData() async {
    try {
      final moodService = MoodService(db);
      final history = await moodService.getDailyMoodAverages(
        widget.userId,
        days: 14,
      );
      final avg = await moodService.getAverageMood(widget.userId, days: 7);
      final todaysMood = await moodService.getTodaysMood(widget.userId);

      if (mounted) {
        setState(() {
          _moodHistory = history;
          _averageMood = avg;
          _todaysMood = todaysMood;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAppointments() async {
    try {
      final service = AppointmentService(db);
      final appts = await service.getAppointmentsForUser(widget.userId);
      if (mounted) {
        setState(() => _appointments = appts);
      }
    } catch (_) {}
  }

  Future<void> _loadUserMedications() async {
    setState(() => _isLoading = true);

    try {
      // Get all active medication plans for this user
      final query =
          db.select(db.medicationPlans).join([
            drift.innerJoin(
              db.medications,
              db.medications.id.equalsExp(db.medicationPlans.medicationId),
            ),
          ])..where(
            db.medicationPlans.userId.equals(widget.userId) &
                db.medicationPlans.isActive.equals(true),
          );

      final results = await query.get();
      final medicationService = MedicationService(db);
      final medications = <Map<String, dynamic>>[];

      for (var row in results) {
        final medication = row.readTable(db.medications);

        // Get the full medication details including times
        final medDetails = await medicationService.loadMedicationsWithDetails();

        // Find this specific medication in the details
        final thisMedDetail = medDetails.firstWhere(
          (m) => m['id'] == medication.id,
          orElse: () => <String, dynamic>{},
        );

        if (thisMedDetail.isNotEmpty) {
          medications.add(thisMedDetail);
        }
      }

      setState(() {
        _medications = medications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Napaka pri nalaganju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedication(
    int medicationId,
    String medicationName, {
    bool skipConfirm = false,
  }) async {
    if (!skipConfirm) {
      final confirmed = await showConfirmationDialog(
        context,
        title: 'Izbris zdravila',
        message:
            'Ali želite izbrisati zdravilo $medicationName za uporabnika ${widget.userName}?',
      );
      if (!confirmed) return;
    }

    try {
      final medicationService = MedicationService(db);
      await medicationService.deleteMedication(medicationId);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zdravilo $medicationName je bilo izbrisano'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserMedications();
        homePageKey.currentState?.loadTodaysIntakes(autoScroll: false);
        medsPageKey.currentState?.refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Napaka pri brisanju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deactivateUser() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Izbriši račun',
      message:
          'Ali ste prepričani? Podatki bodo dostopni v zgodovini, račun pa izbrisan.',
    );

    if (confirmed) {
      try {
        // Cancel all alarms for this user's medications
        final allIntakes = await db.select(db.medicationIntakeLogs).get();
        for (var intake in allIntakes) {
          if (intake.userId == widget.userId) {
            try {
              await Alarm.stop(intake.id);
            } catch (e) {
              // Alarm might not exist, continue
            }
          }
        }

        // Deactivate the user
        await (db.update(db.users)..where((t) => t.id.equals(widget.userId)))
            .write(UsersCompanion(isActive: drift.Value(false)));

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Račun za ${widget.userName} je bil deaktiviran'),
              backgroundColor: Colors.green,
            ),
          );
          // Active-user set shrank: refresh other tabs so cards drop the
          // owner labels (and remove this user's intakes) right away.
          homePageKey.currentState?.loadUserData();
          homePageKey.currentState?.loadTodaysIntakes(autoScroll: false);
          medsPageKey.currentState?.refresh();
          Navigator.of(context).pop(); // Go back to user list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildMoodSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick log button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _onQuickLogMood,
              icon: const Text('😊', style: TextStyle(fontSize: 16)),
              label: const Text('Zabeleži'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),

        // Today's mood
        if (_todaysMood != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  MoodService.moodEmojis[_todaysMood!.moodLevel]!,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danes: ${MoodService.moodLabels[_todaysMood!.moodLevel]}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_todaysMood!.note != null)
                        Text(
                          _todaysMood!.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Weekly average
        if (_averageMood != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Tedensko povprečje: ${MoodService.moodEmojis[_averageMood!.round()]} ${_averageMood!.toStringAsFixed(1)} / 5',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),

        // Mood chart (last 14 days)
        if (_moodHistory.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zadnjih 14 dni',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _moodHistory.map((day) {
                      final avg = day['average'] as double?;
                      final hasData = avg != null;
                      final height = hasData ? (avg / 5.0) * 60 + 8 : 4.0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (hasData)
                                Text(
                                  MoodService.moodEmojis[avg.round()]!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              const SizedBox(height: 2),
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: hasData
                                      ? _moodColor(avg, colors)
                                      : colors.outlineVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '14 dni nazaj',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'Danes',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (_moodHistory.every((d) => d['average'] == null) &&
            _todaysMood == null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: EmptyStateInline(
              icon: Symbols.mood,
              message: 'Ni zabeleženih razpoloženj',
            ),
          ),
      ],
    );
  }

  Color _moodColor(double mood, ColorScheme colors) {
    if (mood >= 4) return Colors.green;
    if (mood >= 3) return colors.primary;
    if (mood >= 2) return Colors.orange;
    return Colors.red;
  }

  // ── Water actions ───────────────────────────────────────────────────────

  /// Look up the active `User` row + (re)schedule water reminders to match.
  /// Centralised so every settings write goes through the same path and the
  /// OS schedule can't drift from the DB.
  Future<void> _resyncWaterReminders() async {
    final user = await (db.select(db.users)
          ..where((t) => t.id.equals(widget.userId)))
        .getSingleOrNull();
    if (user == null) return;
    await NotificationService().scheduleWaterReminders(user);
  }

  Future<void> _onLogWater() async {
    final result = await showWaterLoggingSheet(context: context);
    if (result == null || !mounted) return;
    try {
      await WaterService(db).logIntake(
        userId: widget.userId,
        amountMl: result['amountMl'] as int,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💧 ${result['amountMl']} ml zabeleženo'),
            backgroundColor: const Color(0xFF38BDF8),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadWaterData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteWaterIntake(int id) async {
    try {
      await WaterService(db).deleteIntake(id);
      _loadWaterData();
    } catch (_) {}
  }

  Future<void> _editWaterGoal() async {
    int draft = _waterSettings.goalMl;
    final newGoal = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Dnevni cilj'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$draft ml',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                  Slider(
                    min: 500,
                    max: 4000,
                    divisions: 35, // 100 ml steps
                    value: draft.clamp(500, 4000).toDouble(),
                    activeColor: const Color(0xFF38BDF8),
                    onChanged: (v) =>
                        setDialogState(() => draft = v.round()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Prekliči'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(draft),
                  child: const Text('Shrani'),
                ),
              ],
            );
          },
        );
      },
    );
    if (newGoal == null) return;
    await WaterService(db).setGoal(widget.userId, newGoal);
    _loadWaterData();
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    await WaterService(db).setReminderSettings(widget.userId, enabled: enabled);
    await _resyncWaterReminders();
    _loadWaterData();
  }

  Future<void> _pickReminderHour({required bool isStart}) async {
    final current = isStart
        ? _waterSettings.startHour
        : _waterSettings.endHour;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current, minute: 0),
      helpText: isStart ? 'Začetek opomnikov' : 'Konec opomnikov',
    );
    if (picked == null) return;
    await WaterService(db).setReminderSettings(
      widget.userId,
      startHour: isStart ? picked.hour : null,
      endHour: isStart ? null : picked.hour,
    );
    await _resyncWaterReminders();
    _loadWaterData();
  }

  Future<void> _pickReminderInterval() async {
    // Common cadences. Anything finer would just spam.
    const options = [30, 60, 90, 120, 180, 240];
    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pogostost opomnikov',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              for (final mins in options)
                RadioListTile<int>(
                  value: mins,
                  groupValue: _waterSettings.intervalMinutes,
                  title: Text(_intervalFullLabel(mins)),
                  onChanged: (v) => Navigator.of(ctx).pop(v),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    await WaterService(db).setReminderSettings(
      widget.userId,
      intervalMinutes: picked,
    );
    await _resyncWaterReminders();
    _loadWaterData();
  }

  Future<void> _onQuickLogMood() async {
    final result = await showMoodLoggingSheet(
      context: context,
      existingMoodLevel: _todaysMood?.moodLevel,
    );
    if (result == null || !mounted) return;

    try {
      final moodService = MoodService(db);
      await moodService.logMood(
        userId: widget.userId,
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
        _loadMoodData();
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

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (_) {
            final accent = getUserColor(
              userId: widget.userId,
              name: widget.userName,
            );
            return Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(widget.userName),
              ],
            );
          },
        ),
        scrolledUnderElevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 12, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Zdravila ────────────────────────────────────────────
                  _ExpandableSection(
                    icon: Symbols.pill,
                    title: 'Zdravila',
                    initiallyExpanded: true,
                    trailing: _medications.isNotEmpty
                        ? _SectionBadge(
                            label: '${_medications.length}',
                            color: colors.primary,
                          )
                        : null,
                    child: _buildMedicationsContent(theme, colors),
                  ),

                  // ── Razpoloženje ─────────────────────────────────────────
                  _ExpandableSection(
                    icon: Symbols.mood,
                    title: 'Razpoloženje',
                    trailing: _todaysMood != null
                        ? Text(
                            MoodService.moodEmojis[_todaysMood!.moodLevel]!,
                            style: const TextStyle(fontSize: 22),
                          )
                        : null,
                    child: _buildMoodSection(theme, colors),
                  ),

                  // ── Voda ─────────────────────────────────────────────────
                  _ExpandableSection(
                    icon: Symbols.water_drop,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Voda',
                    trailing: _SectionBadge(
                      label:
                          '$_waterTodayMl / ${_waterSettings.goalMl} ml',
                      color: const Color(0xFF38BDF8),
                    ),
                    child: _buildWaterSection(theme, colors),
                  ),

                  // ── Termini ──────────────────────────────────────────────
                  _ExpandableSection(
                    icon: Symbols.calendar_month,
                    title: 'Termini',
                    trailing: () {
                      final upcomingCount = _appointments
                          .where(
                            (a) => a.appointmentTime.isAfter(DateTime.now()),
                          )
                          .length;
                      return upcomingCount > 0
                          ? _SectionBadge(
                              label: '$upcomingCount',
                              color: colors.primary,
                            )
                          : null;
                    }(),
                    child: _buildAppointmentsSection(theme, colors),
                  ),

                  // ── Izbriši račun ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _deactivateUser,
                      icon: Icon(Symbols.delete, color: colors.error),
                      label: Text(
                        'Izbriši račun',
                        style: TextStyle(color: colors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.error),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Deaktivacija bo ohranila zgodovino, a onemogočila dostop do računa.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildMedicationsContent(ThemeData theme, ColorScheme colors) {
    if (_medications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: EmptyStateInline(
          icon: Symbols.medication,
          message: 'Ni zdravil za tega uporabnika',
        ),
      );
    }

    return Column(
      children: _medications.map((med) {
        final dosageAmount = med['dosage'] as double;
        final dosageCount = dosageAmount.toInt();

        return GestureDetector(
          onTap: () {
            context.push('/medication-detail', extra: {
              'medicationId': med['id'] as int,
              'medicationName': med['name'] as String,
              'medType': med['medType'] as MedicationType,
              'pillsRemaining': med['remaining'] as int,
              'dosageAmount': dosageAmount,
              'frequency': med['frequency'] as String,
              'times': med['times'] as List<String>,
              'intakeAdvice': med['intakeAdvice'] as String?,
              'criticalReminder': med['criticalReminder'] as bool,
              'isAsNeeded': (med['frequency'] as String) == 'Po potrebi',
              'planId': (med['plan'] as MedicationPlan?)?.id,
              'userId': (med['plan'] as MedicationPlan?)?.userId,
              'onDelete': () => _deleteMedication(
                med['id'] as int,
                med['name'] as String,
                skipConfirm: true,
              ),
              'onRefresh': _loadUserMedications,
            });
          },
          child: MedicationDetailsCard(
            medName: med['name'] as String,
            dosage:
                '$dosageCount ${getMedicationUnit(med['medType'] as MedicationType, dosageCount)}',
            pillsRemaining: med['remaining'] as int,
            frequency: med['frequency'] as String,
            times: med['times'] as List<String>,
            medType: med['medType'] as MedicationType,
            onAddMedication: (quantity) async {
              try {
                final currentRemaining = med['remaining'] as int;
                final newRemaining = (currentRemaining + quantity.toInt())
                    .clamp(0, 9999);

                await (db.update(
                  db.medications,
                )..where((t) => t.id.equals(med['id'] as int))).write(
                  MedicationsCompanion(
                    dosagesRemaining: drift.Value(newRemaining.toDouble()),
                  ),
                );

                if (mounted) {
                  final absQuantity = quantity.abs().toInt();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        quantity >= 0
                            ? 'Dodal ${quantity.toInt()} ${getMedicationUnitShort(med['medType'] as MedicationType, quantity.toInt())}'
                            : 'Odstranil $absQuantity ${getMedicationUnitShort(med['medType'] as MedicationType, absQuantity)}',
                      ),
                      backgroundColor: quantity >= 0
                          ? Colors.green
                          : Colors.orange,
                    ),
                  );
                  _loadUserMedications();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Napaka: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onDelete: () =>
                _deleteMedication(med['id'] as int, med['name'] as String),
            isAsNeeded: (med['frequency'] as String) == 'Po potrebi',
            onLogIntake:
                (med['frequency'] as String) == 'Po potrebi' &&
                    (med['plan'] as MedicationPlan?) != null
                ? () async {
                    final plan = med['plan'] as MedicationPlan;
                    final result = await showLogIntakeSheet(
                      context: context,
                      medicationName: med['name'] as String,
                      medType: med['medType'] as MedicationType,
                      defaultQuantity: dosageCount,
                    );
                    if (result != null && mounted) {
                      final time = result['time'] as TimeOfDay;
                      final qty = result['quantity'] as int;
                      final now = DateTime.now();
                      final takenTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        time.hour,
                        time.minute,
                      );
                      try {
                        final intakeService = IntakeLogService(db);
                        await intakeService.logAsNeededIntake(
                          planId: plan.id,
                          medicationId: med['id'] as int,
                          userId: plan.userId,
                          dosageAmount: qty.toDouble(),
                          takenTime: takenTime,
                        );
                        if (mounted) {
                          final timeStr =
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✓ $qty ${getMedicationUnitShort(med['medType'] as MedicationType, qty)} ob $timeStr',
                                style: TextStyle(color: colors.onSurface),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: colors.surfaceContainerHighest,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadUserMedications();
                          homePageKey.currentState?.loadTodaysIntakes(
                            autoScroll: false,
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
                  }
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ── Water section ───────────────────────────────────────────────────────

  static const Color _waterBlue = Color(0xFF38BDF8);

  Widget _buildWaterSection(ThemeData theme, ColorScheme colors) {
    final goal = _waterSettings.goalMl;
    final progress = goal == 0 ? 0.0 : (_waterTodayMl / goal).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final remaining = (goal - _waterTodayMl).clamp(0, goal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick log button (mirrors the mood section affordance).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _onLogWater,
              icon: const Icon(Symbols.water_drop, size: 18),
              label: const Text('Zabeleži'),
              style: FilledButton.styleFrom(
                backgroundColor: _waterBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),

        // ── Progress card ──────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _waterBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _waterBlue.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_waterTodayMl',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: _waterBlue,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'ml',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Tap-to-edit goal — filled blue chip so users notice
                  // immediately that the goal is adjustable.
                  Material(
                    color: _waterBlue,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 1,
                    child: InkWell(
                      onTap: _editWaterGoal,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Symbols.flag,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cilj $goal ml',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Symbols.edit,
                              size: 15,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: _waterBlue.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(_waterBlue),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                percent >= 100
                    ? '🎉 Cilj dosežen!'
                    : 'Še $remaining ml do cilja ($percent %)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // ── Today's entries (compact, swipe-to-delete) ─────────────────
        if (_waterTodayEntries.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Text(
              'Današnji vnosi',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._waterTodayEntries.map(
            (entry) => _buildWaterEntryTile(entry, theme, colors),
          ),
        ],

        // ── 7-day bar chart ────────────────────────────────────────────
        if (_waterDailyTotals.any((d) => (d['totalMl'] as int) > 0))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zadnjih 7 dni',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _waterDailyTotals.map((day) {
                      final totalMl = day['totalMl'] as int;
                      final ratio = goal == 0
                          ? 0.0
                          : (totalMl / goal).clamp(0.0, 1.2);
                      // Reserve a little headroom so a perfect-100% bar fills
                      // ~85% of the vertical space and going over goal is
                      // still visually distinguishable.
                      final height = (ratio * 70).clamp(4.0, 86.0);
                      final hit = totalMl >= goal && goal > 0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (totalMl > 0)
                                Text(
                                  totalMl >= 1000
                                      ? '${(totalMl / 1000).toStringAsFixed(1)}l'
                                      : '${totalMl}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: totalMl == 0
                                      ? colors.outlineVariant.withOpacity(0.3)
                                      : hit
                                          ? _waterBlue
                                          : _waterBlue.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '6 dni nazaj',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'Danes',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // ── Reminders sub-panel ────────────────────────────────────────
        _buildWaterReminderPanel(theme, colors),
      ],
    );
  }

  Widget _buildWaterEntryTile(
    WaterIntakeLog entry,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final t = entry.loggedAt;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey('water_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Symbols.delete, color: colors.error),
      ),
      onDismissed: (_) => _deleteWaterIntake(entry.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: _waterBlue.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Symbols.water_drop, color: _waterBlue, size: 18),
            const SizedBox(width: 10),
            Text(
              '${entry.amountMl} ml',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              timeStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Time part only, e.g. "30 min", "1 h", "1 h 30 min", "2 h".
  static String _intervalTime(int mins) {
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// Full "Vsak*" + time label with the correct Slovenian declension.
  /// Hours count drives the prefix:
  ///   1 → Vsako, 2 → Vsaki, 3–4 → Vsake, 0/5+ → Vsakih.
  /// Sub-hour cadences (15/30/45 min) all take "Vsakih" (genitive plural).
  static String _intervalFullLabel(int mins) {
    String prefix;
    if (mins < 60) {
      prefix = 'Vsakih';
    } else {
      final h = mins ~/ 60;
      if (h == 1) {
        prefix = 'Vsako';
      } else if (h == 2) {
        prefix = 'Vsaki';
      } else if (h <= 4) {
        prefix = 'Vsake';
      } else {
        prefix = 'Vsakih';
      }
    }
    return '$prefix ${_intervalTime(mins)}';
  }

  Widget _buildWaterReminderPanel(ThemeData theme, ColorScheme colors) {
    final s = _waterSettings;
    String fmtHour(int h) => '${h.toString().padLeft(2, '0')}:00';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _waterBlue.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: s.reminderEnabled,
            onChanged: _setReminderEnabled,
            activeColor: _waterBlue,
            secondary: const Icon(
              Symbols.notifications_active,
              color: _waterBlue,
            ),
            title: const Text('Opomniki za pitje'),
            subtitle: Text(
              s.reminderEnabled
                  ? '${_intervalFullLabel(s.intervalMinutes)} med ${fmtHour(s.startHour)}–${fmtHour(s.endHour)}'
                  : 'Izklopljeno',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (s.reminderEnabled) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Symbols.wb_sunny),
              title: const Text('Začetek'),
              trailing: Text(
                fmtHour(s.startHour),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () => _pickReminderHour(isStart: true),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Symbols.bedtime),
              title: const Text('Konec'),
              trailing: Text(
                fmtHour(s.endHour),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () => _pickReminderHour(isStart: false),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Symbols.schedule),
              title: const Text('Pogostost'),
              trailing: Text(
                _intervalTime(s.intervalMinutes),
                style: theme.textTheme.titleMedium,
              ),
              onTap: _pickReminderInterval,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentsSection(ThemeData theme, ColorScheme colors) {
    if (_appointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: EmptyStateInline(
          icon: Symbols.calendar_month,
          message: 'Ni terminov za tega uporabnika',
        ),
      );
    }

    final now = DateTime.now();
    final upcoming = _appointments
        .where((a) => a.appointmentTime.isAfter(now))
        .toList();
    final past = _appointments
        .where((a) => !a.appointmentTime.isAfter(now))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Prihajajoči',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...upcoming.map(
            (appt) =>
                _buildAppointmentTile(appt, theme, colors, isUpcoming: true),
          ),
        ],
        if (past.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Pretekli',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...past.reversed
              .take(5)
              .map(
                (appt) => _buildAppointmentTile(
                  appt,
                  theme,
                  colors,
                  isUpcoming: false,
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildAppointmentTile(
    Appointment appt,
    ThemeData theme,
    ColorScheme colors, {
    required bool isUpcoming,
  }) {
    final dt = appt.appointmentTime;
    final dateStr = '${dt.day}. ${dt.month}. ${dt.year}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(appt.id),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Izbriši',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Symbols.delete, color: colors.error),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return showConfirmationDialog(
          context,
          title: 'Izbriši termin',
          message: 'Ali želite izbrisati termin "${appt.title}"?',
        );
      },
      onDismissed: (_) async {
        final service = AppointmentService(db);
        await service.deleteAppointment(appt.id);
        _loadAppointments();
      },
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddAppointmentScreen(
                userId: widget.userId,
                existingAppointment: appt,
              ),
            ),
          );
          if (result == true) {
            _loadAppointments();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUpcoming
                ? colors.primaryContainer.withOpacity(0.3)
                : colors.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Symbols.calendar_today,
                color: isUpcoming ? colors.primary : colors.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUpcoming ? null : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr ob $timeStr',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (appt.note != null && appt.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        appt.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Symbols.chevron_right,
                color: colors.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Expandable section with animated show/hide of its child.
class _ExpandableSection extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget? trailing;
  final Widget child;
  final bool initiallyExpanded;

  const _ExpandableSection({
    required this.icon,
    this.iconColor,
    required this.title,
    this.trailing,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _controller;
  late final Animation<double> _expandAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _rotateAnim = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = widget.iconColor ?? colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  widget.trailing!,
                  const SizedBox(width: 8),
                ],
                RotationTransition(
                  turns: _rotateAnim,
                  child: Icon(
                    Symbols.expand_more,
                    color: colors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// Small rounded badge used next to section headers.
class _SectionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
