import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:alarm/alarm.dart';
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import '../../data/services/medication_service.dart';
import '../../data/services/mood_service.dart';
import '../../data/services/period_service.dart';
import '../../helpers/medication_unit_helper.dart';
import '../widgets/medication_details_card.dart';
import '../widgets/empty_state_card.dart';
import '../components/confirmation_dialog.dart';
import '../components/mood_logging_sheet.dart';
import '../components/period_logging_sheet.dart';
import '../../main.dart' show db, homePageKey;
import '../../data/services/intake_log_service.dart';
import '../screens/medication_detail_screen.dart';
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
      _UserMedicationsScreenState();
}

class _UserMedicationsScreenState extends ConsumerState<UserMedicationsScreen> {
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;
  String? _userGender;

  // Mood tracking state
  List<Map<String, dynamic>> _moodHistory = [];
  double? _averageMood;
  MoodEntry? _todaysMood;

  // Period tracking state
  PeriodEntry? _activePeriod;
  int? _avgCycleLength;
  int? _avgPeriodDuration;
  DateTime? _nextPeriodPrediction;
  List<Map<String, dynamic>> _recentCycles = [];

  bool get _isFemale => _userGender == 'female';

  @override
  void initState() {
    super.initState();
    _loadUserGender();
    _loadUserMedications();
    _loadMoodData();
  }

  Future<void> _loadUserGender() async {
    try {
      final user = await (db.select(
        db.users,
      )..where((t) => t.id.equals(widget.userId))).getSingleOrNull();
      if (mounted && user != null) {
        setState(() {
          _userGender = user.gender;
        });
        // Only load period data for female users
        if (user.gender == 'female') {
          _loadPeriodData();
        }
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

  Future<void> _loadPeriodData() async {
    try {
      final periodService = PeriodService(db);
      final active = await periodService.getActivePeriod(widget.userId);
      final avgCycle = await periodService.getAverageCycleLength(widget.userId);
      final avgDuration = await periodService.getAveragePeriodDuration(
        widget.userId,
      );
      final nextPrediction = await periodService.predictNextPeriod(
        widget.userId,
      );
      final cycles = await periodService.getCompletedCycles(widget.userId);

      if (mounted) {
        setState(() {
          _activePeriod = active;
          _avgCycleLength = avgCycle;
          _avgPeriodDuration = avgDuration;
          _nextPeriodPrediction = nextPrediction;
          _recentCycles = cycles;
        });
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
    String medicationName,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Izbris zdravila',
      message:
          'Ali želite izbrisati zdravilo $medicationName za uporabnika ${widget.userName}?',
    );

    if (confirmed) {
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                'Razpoloženje',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Quick log button
              TextButton.icon(
                onPressed: _onQuickLogMood,
                icon: const Text('😊', style: TextStyle(fontSize: 16)),
                label: const Text('Zabeleži'),
              ),
            ],
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

  Widget _buildPeriodSection(ThemeData theme, ColorScheme colors) {
    final hasAnyData =
        _activePeriod != null ||
        _recentCycles.isNotEmpty ||
        _avgCycleLength != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                'Menstruacija',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _onQuickLogPeriod,
                icon: const Icon(
                  Symbols.water_drop,
                  size: 16,
                  color: Colors.red,
                ),
                label: const Text('Zabeleži'),
              ),
            ],
          ),
        ),

        // Active period indicator
        if (_activePeriod != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Symbols.water_drop, color: colors.error, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menstruacija v teku',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.error,
                        ),
                      ),
                      Text(
                        'Začetek: ${_formatDate(_activePeriod!.date)} (${DateTime.now().difference(_activePeriod!.date).inDays + 1}. dan)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => _endPeriod(),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Končaj'),
                ),
              ],
            ),
          ),

        // Cycle stats
        if (_avgCycleLength != null || _avgPeriodDuration != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (_avgCycleLength != null)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_avgCycleLength',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        Text(
                          'dni cikel',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_avgCycleLength != null && _avgPeriodDuration != null)
                  Container(width: 1, height: 40, color: colors.outlineVariant),
                if (_avgPeriodDuration != null)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_avgPeriodDuration',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.error,
                          ),
                        ),
                        Text(
                          'dni trajanje',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // Next period prediction
        if (_nextPeriodPrediction != null && _activePeriod == null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Symbols.event, color: colors.tertiary, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Naslednja predvidena menstruacija',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _formatDate(_nextPeriodPrediction!),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Recent cycles
        if (_recentCycles.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zadnji cikli',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ..._recentCycles.reversed.take(4).map((cycle) {
                  final start = cycle['start'] as DateTime;
                  final end = cycle['end'] as DateTime;
                  final days = cycle['durationDays'] as int;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Symbols.water_drop, size: 16, color: colors.error),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatDate(start)} – ${_formatDate(end)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '$days dni',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        if (!hasAnyData)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: EmptyStateInline(
              icon: Symbols.water_drop,
              message: 'Ni zabeleženih podatkov o menstruaciji',
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }

  Future<void> _onQuickLogPeriod() async {
    try {
      final periodService = PeriodService(db);
      final active = await periodService.getActivePeriod(widget.userId);

      if (!mounted) return;

      final result = await showPeriodLoggingSheet(
        context: context,
        hasActivePeriod: active != null,
      );
      if (result == null || !mounted) return;

      final action = result['action'] as String;
      final now = DateTime.now();

      if (action == 'start') {
        await periodService.logPeriodStart(
          userId: widget.userId,
          date: now,
          flowIntensity: result['flowIntensity'] as int?,
          note: result['note'] as String?,
        );
      } else if (action == 'end') {
        await periodService.logPeriodEnd(
          userId: widget.userId,
          date: now,
          note: result['note'] as String?,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'start'
                  ? '🔴 Začetek menstruacije zabeležen'
                  : '✓ Konec menstruacije zabeležen',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadPeriodData();
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

  Future<void> _endPeriod() async {
    try {
      final periodService = PeriodService(db);
      await periodService.logPeriodEnd(
        userId: widget.userId,
        date: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Konec menstruacije zabeležen'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadPeriodData();
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
        title: Row(
          children: [
            Icon(Symbols.person, color: colors.primary),
            const SizedBox(width: 8),
            Text(widget.userName),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zdravila Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Zdravila',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_medications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: EmptyStateInline(
                        icon: Symbols.medication,
                        message: 'Ni zdravil za tega uporabnika',
                      ),
                    )
                  else
                    ..._medications.map((med) {
                      final dosageAmount = med['dosage'] as double;
                      final dosageCount = dosageAmount.toInt();

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MedicationDetailScreen(
                                medicationId: med['id'] as int,
                                medicationName: med['name'] as String,
                                medType: med['medType'] as MedicationType,
                                pillsRemaining: med['remaining'] as int,
                                dosageAmount: dosageAmount,
                                frequency: med['frequency'] as String,
                                times: med['times'] as List<String>,
                                intakeAdvice: med['intakeAdvice'] as String?,
                                criticalReminder:
                                    med['criticalReminder'] as bool,
                                isAsNeeded:
                                    (med['frequency'] as String) ==
                                    'Po potrebi',
                                planId: (med['plan'] as MedicationPlan?)?.id,
                                userId:
                                    (med['plan'] as MedicationPlan?)?.userId,
                                onDelete: () => _deleteMedication(
                                  med['id'] as int,
                                  med['name'] as String,
                                ),
                                onRefresh: _loadUserMedications,
                              ),
                            ),
                          );
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

                              await (db.update(db.medications)..where(
                                    (t) => t.id.equals(med['id'] as int),
                                  ))
                                  .write(
                                    MedicationsCompanion(
                                      dosagesRemaining: drift.Value(
                                        newRemaining.toDouble(),
                                      ),
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
                          onDelete: () => _deleteMedication(
                            med['id'] as int,
                            med['name'] as String,
                          ),
                          isAsNeeded:
                              (med['frequency'] as String) == 'Po potrebi',
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
                                      final intakeService = IntakeLogService(
                                        db,
                                      );
                                      await intakeService.logAsNeededIntake(
                                        planId: plan.id,
                                        medicationId: med['id'] as int,
                                        userId: plan.userId,
                                        dosageAmount: qty.toDouble(),
                                        takenTime: takenTime,
                                      );
                                      if (mounted) {
                                        final colors = Theme.of(
                                          context,
                                        ).colorScheme;
                                        final timeStr =
                                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                        ScaffoldMessenger.of(
                                          context,
                                        ).clearSnackBars();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '✓ $qty ${getMedicationUnitShort(med['medType'] as MedicationType, qty)} ob $timeStr',
                                              style: TextStyle(
                                                color: colors.onSurface,
                                              ),
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            backgroundColor:
                                                colors.surfaceContainerHighest,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        _loadUserMedications();
                                        homePageKey.currentState
                                            ?.loadTodaysIntakes(
                                              autoScroll: false,
                                            );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).clearSnackBars();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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

                  const SizedBox(height: 32),

                  // Razpoloženje (Mood) Section
                  _buildMoodSection(theme, colors),

                  // Menstruacija (Period) Section - only for female users
                  if (_isFemale) ...[
                    const SizedBox(height: 32),
                    _buildPeriodSection(theme, colors),
                  ],

                  const SizedBox(height: 32),

                  // Uporabniški račun Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Uporabniški račun',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Izbriši račun
                  GestureDetector(
                    onTap: _deactivateUser,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.error, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Symbols.delete, color: colors.error, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Izbriši račun',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Deaktiviraj ta uporabniški račun',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Symbols.chevron_right,
                            color: colors.error,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
