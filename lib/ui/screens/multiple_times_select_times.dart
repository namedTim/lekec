import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lekec/database/tables/medications.dart';
import 'package:lekec/features/meds/providers/medications_provider.dart';
import 'package:lekec/features/core/providers/intake_schedule_provider.dart';

class MultipleTimesSelectTimesScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final int timesPerDay;

  const MultipleTimesSelectTimesScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.timesPerDay,
  });

  @override
  ConsumerState<MultipleTimesSelectTimesScreen> createState() =>
      _MultipleTimesSelectTimesScreenState();
}

class _MultipleTimesSelectTimesScreenState
    extends ConsumerState<MultipleTimesSelectTimesScreen> {
  List<TimeOfDay?> _times = [];

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
                                ? colors.primaryContainer.withOpacity(0.5)
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
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _times[index] != null
                                          ? '${_times[index]!.hour.toString().padLeft(2, '0')}:${_times[index]!.minute.toString().padLeft(2, '0')}'
                                          : 'Izberite čas',
                                      style: theme.textTheme.titleMedium?.copyWith(
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

              FilledButton(
                onPressed: allTimesSelected ? _handleSave : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Shrani',
                  style: TextStyle(
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
    if (_times.any((t) => t == null)) return;

    final medicationService = ref.read(medicationServiceProvider);
    final planService = ref.read(planServiceProvider);
    final scheduleGenerator = ref.read(intakeScheduleGeneratorProvider);

    try {
      // Find or create medication
      final medicationId = await medicationService.findOrCreateMedication(
        widget.medicationName,
        widget.medType,
      );

      // Convert times to string list
      final times = _times
          .map((t) => '${t!.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      // Create daily plan with multiple times
      await planService.createMedicationPlan(
        userId: 1, // TODO: Get from auth
        medicationId: medicationId,
        startDate: DateTime.now(),
        dosageAmount: 1.0, // TODO: Get from dosage selection screen
        initialQuantity: null, // TODO: Get from quantity screen
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Napaka: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
