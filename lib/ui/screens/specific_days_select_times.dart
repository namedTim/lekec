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

class SpecificDaysSelectTimesScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final List<int> selectedDays;

  const SpecificDaysSelectTimesScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.selectedDays,
  });

  @override
  ConsumerState<SpecificDaysSelectTimesScreen> createState() =>
      _SpecificDaysSelectTimesScreenState();
}

class _SpecificDaysSelectTimesScreenState
    extends ConsumerState<SpecificDaysSelectTimesScreen> {
  final List<TimeOfDay> _times = [];

  final List<String> _dayNames = [
    'Ponedeljek',
    'Torek',
    'Sreda',
    'Četrtek',
    'Petek',
    'Sobota',
    'Nedelja',
  ];

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
                'Dodajte čase za izbrane dneve',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Show selected days
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.selectedDays.map((dayIndex) {
                  return Chip(
                    label: Text(_dayNames[dayIndex]),
                    backgroundColor: colors.primaryContainer,
                    labelStyle: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
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
                                  Icon(
                                    Symbols.schedule,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${_times[index].hour.toString().padLeft(2, '0')}:${_times[index].minute.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
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

              FilledButton(
                onPressed: _times.isNotEmpty ? _handleSave : null,
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
    if (_times.isEmpty) return;

    final medicationService = ref.read(medicationServiceProvider);
    final planService = ref.read(planServiceProvider);
    final scheduleGenerator = ref.read(intakeScheduleGeneratorProvider);

    try {
      // Find or create medication
      final medicationId = await medicationService.createMedication(
        MedicationsCompanion(
          name: drift.Value(widget.medicationName),
          medType: drift.Value(widget.medType),
        ),
      );

      // Convert times to string list
      final times = _times
          .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      // Create specific days plan
      await planService.createSpecificDaysPlan(
        userId: 1, // TODO: Get from auth
        medicationId: medicationId,
        startDate: DateTime.now(),
        dosageAmount: 1.0, // TODO: Get from dosage selection screen
        initialQuantity: null, // TODO: Get from quantity screen
        daysOfWeek: widget.selectedDays.map((d) => d + 1).toList(), // Convert 0-based to 1-based (1=Monday)
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
