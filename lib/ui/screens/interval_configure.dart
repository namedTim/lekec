import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import 'interval_planning.dart';
import '../../features/meds/providers/medications_provider.dart';
import '../../features/core/providers/intake_schedule_provider.dart';
import '../../main.dart' show homePageKey;
import '../components/quantity_selector.dart';

class IntervalConfigureScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final IntervalType intervalType;
  final int intervalValue;
  final String intakeAdvice;

  const IntervalConfigureScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.intervalType,
    required this.intervalValue,
    required this.intakeAdvice,
  });

  @override
  ConsumerState<IntervalConfigureScreen> createState() =>
      _IntervalConfigureScreenState();
}

class _IntervalConfigureScreenState
    extends ConsumerState<IntervalConfigureScreen> {
  TimeOfDay? _startTime;
  int _initialQuantity = 0;
  int _dosageAmount = 1;
  bool _isSaving = false;

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
        title: const Text('Čas začetka'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.medicationName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Izberite čas prvega opomnika',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => _startTime = time);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.schedule, color: colors.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _startTime != null
                              ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                              : 'Izberite čas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Symbols.arrow_forward_ios,
                        color: colors.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info about the schedule
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.info, color: colors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Opomnik bo nastavljen vsakih ${widget.intervalValue} ${widget.intervalType == IntervalType.hours ? "ur" : "dni"}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Količina na vnos card
              InkWell(
                onTap: () async {
                  final quantity = await showQuantitySelector(
                    context,
                    initialValue: _dosageAmount,
                    minValue: 1,
                    maxValue: 99,
                    label: 'Količina na vnos',
                  );
                  if (quantity != null) {
                    setState(() => _dosageAmount = quantity);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.pill, color: colors.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Količina na vnos',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_dosageAmount',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Symbols.arrow_forward_ios,
                        color: colors.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Initial quantity card
              InkWell(
                onTap: () async {
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
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.inventory_2,
                        color: colors.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Začetna zaloga',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _initialQuantity > 0
                                  ? '$_initialQuantity'
                                  : 'Ni nastavljeno',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _initialQuantity > 0
                                    ? null
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Symbols.arrow_forward_ios,
                        color: colors.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: _startTime != null && !_isSaving
                    ? _handleSave
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Shranjujem...' : 'Shrani',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave() async {
    if (_startTime == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final medicationService = ref.read(medicationServiceProvider);
    final planService = ref.read(planServiceProvider);
    final scheduleGenerator = ref.read(intakeScheduleGeneratorProvider);

    try {
      // Use initial quantity if set
      final initialQuantity = _initialQuantity > 0
          ? _initialQuantity.toDouble()
          : null;

      // Find or create medication
      final medicationId = await medicationService.createMedication(
        MedicationsCompanion(
          name: drift.Value(widget.medicationName),
          medType: drift.Value(widget.medType),
          intakeAdvice: drift.Value(widget.intakeAdvice),
          dosagesRemaining: drift.Value(initialQuantity),
        ),
      );

      // Create interval plan
      final startTime =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      await planService.createIntervalPlan(
        userId: 1, // TODO: Get from auth
        medicationId: medicationId,
        startDate: DateTime.now(),
        dosageAmount: _dosageAmount.toDouble(),
        initialQuantity: initialQuantity,
        isHourInterval: widget.intervalType == IntervalType.hours,
        intervalValue: widget.intervalValue,
        startTime: startTime,
      );

      // Generate schedule for the new plan
      await scheduleGenerator.generateScheduledIntakes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zdravilo uspešno dodano!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home and refresh
        context.go('/');

        // Wait a moment for navigation to complete, then refresh
        await Future.delayed(const Duration(milliseconds: 100));
        homePageKey.currentState?.loadTodaysIntakes();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
