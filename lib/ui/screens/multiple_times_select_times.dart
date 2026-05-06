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
import '../../services/gemini_medication_service.dart';
import '../components/quantity_selector.dart';
import '../components/critical_reminder_recap.dart';

class MultipleTimesSelectTimesScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final int timesPerDay;
  final String intakeAdvice;
  final int userId;
  final MedicationExtractionResult? extractedData;

  const MultipleTimesSelectTimesScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.timesPerDay,
    required this.intakeAdvice,
    required this.userId,
    this.extractedData,
  });

  @override
  ConsumerState<MultipleTimesSelectTimesScreen> createState() =>
      _MultipleTimesSelectTimesScreenState();
}

class _MultipleTimesSelectTimesScreenState
    extends ConsumerState<MultipleTimesSelectTimesScreen> {
  List<TimeOfDay?> _times = [];
  List<bool> _aiSuggestedTimes = [];
  int _initialQuantity = 0;
  double _dosageAmount = 1;
  bool _isSaving = false;
  bool _criticalReminder = true;

  @override
  void initState() {
    super.initState();
    _times = List.generate(widget.timesPerDay, (_) => null);
    _aiSuggestedTimes = List.generate(widget.timesPerDay, (_) => false);
    _initFromExtractedData();
  }

  void _initFromExtractedData() {
    final suggestedTimes =
        widget.extractedData?.dosageFrequency?.suggestedTimes;
    if (suggestedTimes != null && suggestedTimes.isNotEmpty) {
      for (
        int i = 0;
        i < widget.timesPerDay && i < suggestedTimes.length;
        i++
      ) {
        final time = _parseTimeString(suggestedTimes[i]);
        if (time != null) {
          _times[i] = time;
          _aiSuggestedTimes[i] = true;
        }
      }
    }

    // Also auto-fill dosage amount if available
    final amountPerDose = widget.extractedData?.dosageFrequency?.amountPerDose;
    if (amountPerDose != null && amountPerDose > 0) {
      _dosageAmount = amountPerDose;
    }

    // Auto-fill initial quantity if available
    final quantityInBox = widget.extractedData?.quantityInBox;
    if (quantityInBox != null && quantityInBox > 0) {
      _initialQuantity = quantityInBox;
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final allTimesSelected = _times.every((t) => t != null);
    final hasAnySuggestedTime = _aiSuggestedTimes.any((v) => v);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Časi opomnikov'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              // Header with AI badge if any times are AI-suggested
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Izberite čase za ${widget.timesPerDay} dnevne vnose',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (hasAnySuggestedTime)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.auto_awesome,
                            size: 14,
                            color: colors.surface,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.surface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Progress indicator: X / Y times selected
              Builder(
                builder: (context) {
                  final filledCount = _times.where((t) => t != null).length;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: filledCount == widget.timesPerDay
                          ? colors.primaryContainer.withOpacity(0.5)
                          : colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          filledCount == widget.timesPerDay
                              ? Symbols.check_circle
                              : Symbols.schedule,
                          color: filledCount == widget.timesPerDay
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$filledCount / ${widget.timesPerDay} časov nastavljenih',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: filledCount == widget.timesPerDay
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.timesPerDay,
                  itemBuilder: (context, index) {
                    final isAiTime = _aiSuggestedTimes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _times[index] ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              _times[index] = time;
                              _aiSuggestedTimes[index] =
                                  false; // User changed it
                            });
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
                                  ? (isAiTime
                                        ? colors.onSurface
                                        : colors.primary)
                                    : colors.outlineVariant.withOpacity(0.5),
                                width: _times[index] != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _times[index] != null
                                      ? (isAiTime
                                            ? colors.onSurface
                                            : colors.primary)
                                      : colors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isAiTime
                                      ? Symbols.auto_awesome
                                      : Symbols.schedule,
                                  color: _times[index] != null
                                      ? (isAiTime
                                            ? colors.surface
                                            : colors.onPrimary)
                                      : colors.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${index + 1}. vnos',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                        if (isAiTime) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.onSurface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'AI',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: colors.surface,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
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
              const SizedBox(height: 16),

              // Količina na vnos card
              InkWell(
                onTap: () async {
                  final quantity = await showQuantitySelector(
                    context,
                    initialValue: _dosageAmount,
                    minValue: 1,
                    maxValue: 9999,
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
                              '${_dosageAmount == _dosageAmount.roundToDouble() ? _dosageAmount.toInt().toString() : _dosageAmount.toString()}',
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
                    initialValue: _initialQuantity > 0 ? _initialQuantity.toDouble() : 1,
                    minValue: 0,
                    maxValue: 99999,
                    step: 1,
                    label: 'Začetna zaloga',
                  );
                  if (quantity != null) {
                    setState(() => _initialQuantity = quantity.toInt());
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

              // Critical Reminder Recap
              CriticalReminderRecap(
                enabled: _criticalReminder,
                onChanged: (value) => setState(() => _criticalReminder = value),
              ),
              const SizedBox(height: 24),

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
          criticalReminder: drift.Value(_criticalReminder),
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
        dosageAmount: _dosageAmount,
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
