import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lekec/database/drift_database.dart';
import 'package:lekec/database/tables/medications.dart';
import 'package:lekec/features/meds/providers/medications_provider.dart';
import 'package:lekec/features/core/providers/intake_schedule_provider.dart';
import 'package:lekec/main.dart' show homePageKey;
import 'package:lekec/ui/components/quantity_selector.dart';

class CyclicConfigureScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final int takingDays;
  final int pauseDays;
  final String intakeAdvice;

  const CyclicConfigureScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.takingDays,
    required this.pauseDays,
    required this.intakeAdvice,
  });

  @override
  ConsumerState<CyclicConfigureScreen> createState() =>
      _CyclicConfigureScreenState();
}

class _CyclicConfigureScreenState extends ConsumerState<CyclicConfigureScreen> {
  final List<TimeOfDay> _times = [];
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
                'Dodajte čase za dnevno jemanje',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Cycle info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Symbols.cycle, color: colors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Cikel',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.takingDays} dni jemanja, ${widget.pauseDays} dni pavze',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Times list
              Expanded(
                child: _times.isEmpty
                    ? Center(
                        child: Text(
                          'Ni dodanih časov',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _times.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Symbols.schedule, color: colors.primary),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${_times[index].hour.toString().padLeft(2, '0')}:${_times[index].minute.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Symbols.delete),
                                    color: colors.error,
                                    onPressed: () {
                                      setState(() => _times.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Add time button
              OutlinedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => _times.add(time));
                  }
                },
                icon: const Icon(Symbols.add),
                label: const Text('Dodaj čas'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                onPressed: _times.isNotEmpty && !_isSaving ? _handleSave : null,
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
    if (_times.isEmpty || _isSaving) return;

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
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .toList();

      // Create cyclic plan
      await planService.createCyclicPlan(
        userId: 1, // TODO: Get from auth
        medicationId: medicationId,
        startDate: DateTime.now(),
        dosageAmount: _dosageAmount.toDouble(),
        initialQuantity: initialQuantity,
        cycleDaysOn: widget.takingDays,
        cycleDaysOff: widget.pauseDays,
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
