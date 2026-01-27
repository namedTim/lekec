import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import '../../features/meds/providers/medications_provider.dart';
import '../../features/core/providers/intake_schedule_provider.dart';
import '../../main.dart' show homePageKey;
import '../components/quantity_selector.dart';

class MultipleTimesSelectTimesScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final int timesPerDay;
  final String intakeAdvice;
  final int userId;

  const MultipleTimesSelectTimesScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.timesPerDay,
    required this.intakeAdvice,
    required this.userId,
  });

  @override
  ConsumerState<MultipleTimesSelectTimesScreen> createState() =>
      _MultipleTimesSelectTimesScreenState();
}

class _MultipleTimesSelectTimesScreenState
    extends ConsumerState<MultipleTimesSelectTimesScreen> {
  List<TimeOfDay?> _times = [];
  int _initialQuantity = 0;
  int _dosageAmount = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _times = List.generate(widget.timesPerDay, (_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allTimesSelected = _times.every((t) => t != null);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Časi opomnikov'),
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
                'Izberite čase za ${widget.timesPerDay} dnevne vnose',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: ListView.builder(
                  itemCount: widget.timesPerDay,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _times[index] ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => _times[index] = time);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _times[index] != null
                                ? colors.surfaceContainerHighest
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _times[index] != null
                                  ? colors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _times[index] != null
                                      ? colors.primary
                                      : colors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Symbols.schedule,
                                  color: _times[index] != null
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}. vnos',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _times[index] != null
                                          ? '${_times[index]!.hour.toString().padLeft(2, '0')}:${_times[index]!.minute.toString().padLeft(2, '0')}'
                                          : 'Izberite čas',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _times[index] != null
                                    ? Symbols.check_circle
                                    : Symbols.arrow_forward_ios,
                                color: _times[index] != null
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

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
              const SizedBox(height: 16),

              FilledButton(
                onPressed: allTimesSelected && !_isSaving ? _handleSave : null,
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
    if (_times.any((t) => t == null) || _isSaving) return;

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

      // Convert times to string list
      final times = _times
          .map(
            (t) =>
                '${t!.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .toList();

      // Create daily plan with multiple times
      await planService.createMedicationPlan(
        userId: widget.userId,
        medicationId: medicationId,
        startDate: DateTime.now(),
        dosageAmount: _dosageAmount.toDouble(),
        initialQuantity: initialQuantity,
        ruleType: 'daily',
        times: times,
      );

      // Generate schedule
      await scheduleGenerator.generateScheduledIntakes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zdravilo uspešno dodano!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
        // Trigger refresh of home page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homePageKey.currentState?.loadTodaysIntakes();
        });
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
