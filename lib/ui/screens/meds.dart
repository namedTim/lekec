import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../views/settings_view.dart';
import '../widgets/medication_details_card.dart';
import '../widgets/appointment_card.dart';
import '../components/confirmation_dialog.dart';
import '../../data/services/mood_service.dart';
import '../components/mood_logging_sheet.dart';
import '../components/medication_presets_panel.dart';
import '../../database/tables/medications.dart';
import '../../features/core/providers/database_provider.dart';
import '../../helpers/medication_unit_helper.dart';
import '../../data/services/medication_service.dart';
import '../../data/services/intake_log_service.dart';
import '../../data/services/appointment_service.dart';
import 'medication_detail_screen.dart';
import 'add_appointment_screen.dart';
import '../widgets/empty_state_card.dart';
import '../components/log_intake_sheet.dart';
import '../../main.dart' show homePageKey;

enum MedsTab { medications, appointments, settings }

class MedsScreen extends ConsumerStatefulWidget {
  const MedsScreen({super.key});

  @override
  ConsumerState<MedsScreen> createState() => _MedsScreenState();
}

class _MedsScreenState extends ConsumerState<MedsScreen> with SingleTickerProviderStateMixin {
  MedsTab _selectedTab = MedsTab.medications;
  int _refreshKey = 0;
  // ValueNotifier instead of plain bool so toggling the FAB never calls
  // setState on the parent — this prevents FutureBuilder from re-running.
  final ValueNotifier<bool> _fabExpanded = ValueNotifier(false);
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fabExpanded.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _refreshMedications() {
    setState(() {
      _refreshKey++;
    });
  }

  void _toggleSpeedDial() {
    _fabExpanded.value = !_fabExpanded.value;
    if (_fabExpanded.value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _ensureSpeedDialClosed() {
    if (_fabExpanded.value) {
      _fabExpanded.value = false;
      _animationController.reverse();
    }
  }

  void _onAddSingleEntry() async {
    _toggleSpeedDial();
    await context.push('/add-single-entry');
    _ensureSpeedDialClosed();
    _refreshMedications();
    homePageKey.currentState?.loadTodaysIntakes(autoScroll: false);
  }

  void _onAddNewMedication() async {
    _toggleSpeedDial();
    await context.push('/add-medication');
    _ensureSpeedDialClosed();
    _refreshMedications();
    homePageKey.currentState?.loadTodaysIntakes(autoScroll: false);
  }

  void _onAddAppointment() async {
    _toggleSpeedDial();
    final userId = await _pickUser();
    if (userId == null || !mounted) return;
    await context.push('/add-appointment', extra: {'userId': userId});
    _ensureSpeedDialClosed();
    _refreshMedications();
    homePageKey.currentState?.loadTodaysIntakes(autoScroll: false);
  }

  void _onLogMood() async {
    _toggleSpeedDial();
    final userId = await _pickUser();
    if (userId == null || !mounted) return;
    final result = await showMoodLoggingSheet(context: context);
    _ensureSpeedDialClosed();
    if (result == null || !mounted) return;
    try {
      final database = ref.read(databaseProvider);
      final moodService = MoodService(database);
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

  Future<int?> _pickUser() async {
    final database = ref.read(databaseProvider);
    final users = await (database.select(database.users)
          ..where((t) => t.isActive.equals(true)))
        .get();
    if (users.length == 1) return users.first.id;
    if (!mounted) return null;
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
              ...users.map(
                (user) => ListTile(
                  leading: Icon(Symbols.person, color: colors.primary),
                  title: Text(user.name),
                  onTap: () => Navigator.of(ctx).pop(user.id),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMedication(
    int medicationId,
    String medicationName,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Izbris zdravila',
      message: 'Ali želite izbrisati zdravilo $medicationName?',
    );

    if (confirmed) {
      try {
        final db = ref.read(databaseProvider);
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
          _refreshMedications();
          // Refresh home screen to reflect deleted medication
          homePageKey.currentState?.loadTodaysIntakes();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<MedsTab>(
                      segments: const [
                        ButtonSegment<MedsTab>(
                          value: MedsTab.medications,
                          label: Text('Zdravila'),
                          icon: Icon(Symbols.pill),
                        ),
                        ButtonSegment<MedsTab>(
                          value: MedsTab.appointments,
                          label: Text('Termini'),
                          icon: Icon(Symbols.calendar_month),
                        ),
                        ButtonSegment<MedsTab>(
                          value: MedsTab.settings,
                          label: Text('Nastavitve'),
                          icon: Icon(Symbols.settings),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (Set<MedsTab> newSelection) {
                        setState(() {
                          _selectedTab = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity(horizontal: -2),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
          // Full-screen barrier when FAB is expanded — ValueListenableBuilder
          // rebuilds only this subtree, never the parent.
          ValueListenableBuilder<bool>(
            valueListenable: _fabExpanded,
            builder: (context, isExpanded, _) {
              if (!isExpanded) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleSpeedDial,
                  child: Container(color: Colors.black.withOpacity(0.01)),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              if (_animation.value == 0) {
                return const SizedBox.shrink();
              }
              final theme = Theme.of(context);
              final colors = theme.colorScheme;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Add new medication
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
                              heroTag: 'meds_add_medication',
                              mini: true,
                              onPressed: _onAddNewMedication,
                              child: const Icon(Symbols.pill),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Add single entry
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
                              heroTag: 'meds_add_entry',
                              mini: true,
                              onPressed: _onAddSingleEntry,
                              child: const Icon(Symbols.add),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Log mood
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
                              heroTag: 'meds_log_mood',
                              mini: true,
                              onPressed: _onLogMood,
                              child: const Icon(Symbols.mood),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Add appointment
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
                              heroTag: 'meds_add_appointment',
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
          // Main FAB — ValueListenableBuilder keeps the rotation in sync
          // without triggering a parent setState.
          ValueListenableBuilder<bool>(
            valueListenable: _fabExpanded,
            builder: (context, isExpanded, _) => FloatingActionButton(
              heroTag: 'meds_main_fab',
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
                turns: isExpanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Symbols.add),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case MedsTab.medications:
        final db = ref.watch(databaseProvider);
        final medicationService = MedicationService(db);
        return FutureBuilder(
          key: ValueKey(_refreshKey),
          future: Future.wait([
            medicationService.loadMedicationsWithDetails(),
            (db.select(db.users)..where((t) => t.isActive.equals(true))).get(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Napaka: ${snapshot.error}'));
            }
            final results = snapshot.data as List<dynamic>;
            final medications = results[0] as List<Map<String, dynamic>>;
            final users = results[1] as List<User>;
            final userNames = {for (var u in users) u.id: u.name};
            final showUserNames = users.length > 1;
            final isEmpty = medications.isEmpty;

            return Stack(
              children: [
                // Main content
                if (isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: EmptyStateCard(
                        icon: Symbols.medication,
                        title: 'Ni dodanih zdravil',
                        subtitle: 'Izberite zdravilo spodaj ali dodajte novo',
                        onTap: () => context.push('/add-medication'),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 180, // Extra padding for the presets panel
                    ),
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];
                      final dosageAmount = med['dosage'] as double;
                      final dosageCount = dosageAmount.toInt();
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.of(context).push(
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
                                onRefresh: _refreshMedications,
                              ),
                            ),
                          );
                          if (mounted) {
                            homePageKey.currentState?.loadTodaysIntakes(
                              autoScroll: false,
                            );
                          }
                        },
                        child: MedicationDetailsCard(
                          medName: med['name'] as String,
                          userName: showUserNames
                              ? userNames[(med['plan'] as MedicationPlan?)?.userId]
                              : null,
                          dosage:
                              '$dosageCount ${getMedicationUnit(med['medType'] as MedicationType, dosageCount)}',
                          pillsRemaining: med['remaining'] as int,
                          frequency: med['frequency'] as String,
                          times: med['times'] as List<String>,
                          medType: med['medType'] as MedicationType,
                          onAddMedication: (quantity) async {
                            try {
                              final db = ref.read(databaseProvider);
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
                                _refreshMedications();                                  homePageKey.currentState?.loadTodaysIntakes(
                                    autoScroll: false,
                                  );                              }
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
                                      final database = ref.read(
                                        databaseProvider,
                                      );
                                      final intakeService = IntakeLogService(
                                        database,
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
                                        _refreshMedications();
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
                    },
                  ),

                // Presets panel at the bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MedicationPresetsPanel(
                    initiallyExpanded: isEmpty,
                    onPresetSelected: _refreshMedications,
                  ),
                ),
              ],
            );
          },
        );
      case MedsTab.appointments:
        final database = ref.watch(databaseProvider);
        final appointmentService = AppointmentService(database);
        return FutureBuilder(
          key: ValueKey(_refreshKey),
          future: Future.wait([
            appointmentService.getUpcomingAppointments(),
            (database.select(database.users)..where((t) => t.isActive.equals(true))).get(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Napaka: ${snapshot.error}'));
            }

            final results = snapshot.data as List<dynamic>;
            final appointments = results[0] as List<Appointment>;
            final users = results[1] as List<User>;
            final userNames = {for (var u in users) u.id: u.name};
            final showUserNames = users.length > 1;

            if (appointments.isEmpty) {
              return Center(
                child: EmptyStateCard(
                  icon: Symbols.calendar_month,
                  title: 'Ni prihajajočih terminov',
                  subtitle: 'Dodajte termin za opomnike',
                  onTap: () async {
                    await context.push('/add-appointment');
                    _refreshMedications();
                  },
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: 8,
                left: 8,
                right: 8,
                bottom: 88,
              ),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                return AppointmentDetailsCard(
                  title: appt.title,
                  note: appt.note,
                  appointmentTime: appt.appointmentTime,
                  userName: userNames[appt.userId],
                  showName: showUserNames,
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AddAppointmentScreen(
                          userId: appt.userId,
                          existingAppointment: appt,
                        ),
                      ),
                    );
                    if (result == true) _refreshMedications();
                  },
                  onDelete: () async {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Izbriši termin',
                      message: 'Ali želite izbrisati termin "${appt.title}"?',
                    );
                    if (confirmed) {
                      await appointmentService.deleteAppointment(appt.id);
                      _refreshMedications();
                    }
                  },
                );
              },
            );
          },
        );
      case MedsTab.settings:
        return const SettingsView();
    }
  }
}
