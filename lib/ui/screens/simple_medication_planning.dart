import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/drift_database.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/tables/medications.dart';
import '../components/quantity_selector.dart';
import '../components/step_progress_indicator.dart';
import '../../features/core/providers/database_provider.dart';
import '../../features/core/providers/intake_schedule_provider.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/medication_service.dart';
import '../../data/services/plan_service.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'medication_frequency_selection.dart' show FrequencyOption;
import '../../main.dart' show homePageKey;

class SimpleMedicationPlanningScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final FrequencyOption frequency;
  final int userId;

  const SimpleMedicationPlanningScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.frequency,
    required this.userId,
  });

  @override
  ConsumerState<SimpleMedicationPlanningScreen> createState() =>
      _SimpleMedicationPlanningScreenState();
}

class _SimpleMedicationPlanningScreenState
    extends ConsumerState<SimpleMedicationPlanningScreen> {
  DateTime? _startDate;
  TimeOfDay? _firstIntakeTime;
  int _quantity = 1;
  int _initialQuantity = 0;
  bool _isSaving = false;

  String _getFrequencyLabel() {
    switch (widget.frequency) {
      case FrequencyOption.onceDaily:
        return 'Enkrat dnevno';
      case FrequencyOption.twiceDaily:
        return 'Dvakrat dnevno';
      case FrequencyOption.asNeeded:
        return 'Po potrebi';
      default:
        return '';
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectFirstIntakeTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _firstIntakeTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _firstIntakeTime = time);
    }
  }

  Future<void> _selectQuantity() async {
    final quantity = await showQuantitySelector(
      context,
      initialValue: _quantity,
      label: 'Količina na vnos',
    );
    if (quantity != null) {
      setState(() => _quantity = quantity);
    }
  }

  Future<void> _selectInitialQuantity() async {
    final quantity = await showQuantitySelector(
      context,
      initialValue: _initialQuantity > 0 ? _initialQuantity : 1,
      minValue: 0,
      maxValue: 999,
      label: 'Začetna zaloga',
    );
    if (quantity != null) {
      setState(() => _initialQuantity = quantity);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return; // Prevent double-tap

    // Validate required fields
    if (widget.frequency != FrequencyOption.asNeeded) {
      if (_startDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izberite datum začetka')));
        return;
      }
      if (_firstIntakeTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izberite čas prvega vnosa')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final db = ref.read(databaseProvider);
    final scheduleGenerator = ref.read(intakeScheduleGeneratorProvider);
    final notificationService = NotificationService();
    final medicationService = MedicationService(db);
    final planService = PlanService(db);

    try {
      // 1. Insert medication
      final medicationId = await medicationService.createMedication(
        MedicationsCompanion(
          name: drift.Value(widget.medicationName),
          medType: drift.Value(widget.medType),
        ),
      );

      developer.log(
        'Medication created/found: ID $medicationId',
        name: 'SimpleMedicationPlanning',
      );

      // 2. Prepare schedule times
      List<String> times = [];
      String ruleType = 'daily';

      switch (widget.frequency) {
        case FrequencyOption.onceDaily:
          times = [_formatTime(_firstIntakeTime!)];
          ruleType = 'daily';
          break;
        case FrequencyOption.twiceDaily:
          times = [_formatTime(_firstIntakeTime!)];
          // Add second time (12 hours later)
          final secondTime = TimeOfDay(
            hour: (_firstIntakeTime!.hour + 12) % 24,
            minute: _firstIntakeTime!.minute,
          );
          times.add(_formatTime(secondTime));
          ruleType = 'daily';
          break;
        case FrequencyOption.asNeeded:
          ruleType = 'asNeeded';
          break;
        case FrequencyOption.moreOptions:
          // Should not reach here
          return;
      }

      // 3. Create medication plan with schedule rules
      final planId = await planService.createMedicationPlan(
        userId: widget.userId,
        medicationId: medicationId,
        startDate: _startDate ?? DateTime.now(),
        dosageAmount: _quantity.toDouble(),
        initialQuantity: _initialQuantity?.toDouble(),
        ruleType: ruleType,
        times: times,
      );

      developer.log(
        'Plan created: ID $planId',
        name: 'SimpleMedicationPlanning',
      );

      // 4. Generate future intake entries and notifications (if not "as needed")
      if (ruleType != 'asNeeded') {
        await scheduleGenerator.regeneratePlanSchedule(planId);
        await notificationService.scheduleAllUpcomingNotifications(db);

        developer.log(
          'Generated intake schedule and notifications for plan $planId',
          name: 'SimpleMedicationPlanning',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.medicationName} dodano!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh home page to show new medication
        homePageKey.currentState?.loadTodaysIntakes();

        context.go('/');
      }
    } catch (e, st) {
      developer.log(
        'Error saving medication plan',
        error: e,
        stackTrace: st,
        name: 'SimpleMedicationPlanning',
      );
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                widget.medicationName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getFrequencyLabel(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Show planning options only if not "as needed"
              if (widget.frequency != FrequencyOption.asNeeded) ...[
                // Start Date
                _PlanningCard(
                  icon: Symbols.calendar_today,
                  label: 'Datum začetka',
                  value: _startDate != null
                      ? '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}'
                      : 'Izberite datum',
                  onTap: _selectStartDate,
                ),
                const SizedBox(height: 16),

                // First Intake Time
                _PlanningCard(
                  icon: Symbols.schedule,
                  label: 'Prvi vnos',
                  value: _firstIntakeTime != null
                      ? _firstIntakeTime!.format(context)
                      : 'Izberite čas',
                  onTap: _selectFirstIntakeTime,
                ),
                const SizedBox(height: 16),

                // Quantity
                _PlanningCard(
                  icon: Symbols.pill,
                  label: 'Količina na vnos',
                  value: '$_quantity',
                  onTap: _selectQuantity,
                ),
                const SizedBox(height: 16),

                // Initial Quantity
                _PlanningCard(
                  icon: Symbols.inventory_2,
                  label: 'Začetna zaloga',
                  value: _initialQuantity > 0
                      ? '$_initialQuantity'
                      : 'Izberite količino',
                  onTap: _selectInitialQuantity,
                ),
                const SizedBox(height: 48),
              ] else ...[
                Text(
                  'Zdravilo bo na voljo za ročni vnos brez opomnikov.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
              ],

              FilledButton(
                onPressed: _isSaving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Shrani',
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
      bottomNavigationBar: const StepProgressIndicator(
        currentStep: 3,
        totalSteps: 3,
      ),
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PlanningCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
