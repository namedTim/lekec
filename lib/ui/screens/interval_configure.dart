import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lekec/database/tables/medications.dart';
import 'package:lekec/ui/screens/interval_planning.dart';
import 'package:lekec/features/meds/providers/medications_provider.dart';
import 'package:lekec/features/core/providers/intake_schedule_provider.dart';

class IntervalConfigureScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final IntervalType intervalType;
  final int intervalValue;

  const IntervalConfigureScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.intervalType,
    required this.intervalValue,
  });

  @override
  ConsumerState<IntervalConfigureScreen> createState() =>
      _IntervalConfigureScreenState();
}

class _IntervalConfigureScreenState
    extends ConsumerState<IntervalConfigureScreen> {
  TimeOfDay? _startTime;

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
                      Icon(
                        Symbols.schedule,
                        color: colors.primary,
                        size: 32,
                      ),
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
                    Icon(
                      Symbols.info,
                      color: colors.primary,
                      size: 20,
                    ),
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

              const Spacer(),

              FilledButton(
                onPressed: _startTime != null ? _handleSave : null,
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
    if (_startTime == null) return;

    final medicationService = ref.read(medicationServiceProvider);
    final planService = ref.read(planServiceProvider);
    final scheduleGenerator = ref.read(intakeScheduleGeneratorProvider);

    try {
      // Find or create medication
      final medicationId = await medicationService.findOrCreateMedication(
        widget.medicationName,
        widget.medType,
      );

      // Create interval plan
      final startTime = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      await planService.createIntervalPlan(
        userId: 1, // TODO: Get from auth
        medicationId: medicationId,
        startDate: DateTime.now(),
        dosageAmount: 1.0, // TODO: Get from dosage selection screen
        initialQuantity: null, // TODO: Get from quantity screen
        isHourInterval: widget.intervalType == IntervalType.hours,
        intervalValue: widget.intervalValue,
        startTime: startTime,
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
