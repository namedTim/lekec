import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lekec/database/drift_database.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lekec/database/tables/medications.dart';
import 'package:lekec/ui/components/quantity_selector.dart';
import 'package:lekec/features/core/providers/database_provider.dart';
import 'dart:developer' as developer;
import 'medication_frequency_selection.dart' show FrequencyOption;

class SimpleMedicationPlanningScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final FrequencyOption frequency;

  const SimpleMedicationPlanningScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.frequency,
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

  Future<void> _handleSave() async {
    // Validate required fields
    if (widget.frequency != FrequencyOption.asNeeded) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izberite datum začetka')),
        );
        return;
      }
      if (_firstIntakeTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izberite čas prvega vnosa')),
        );
        return;
      }
    }

    final db = ref.read(databaseProvider);

    try {
      final medicationId = await db.into(db.medications).insert(
            MedicationsCompanion(
              name: drift.Value(widget.medicationName),
              medType: drift.Value(widget.medType),
            ),
          );

      developer.log(
        'Medication saved',
        name: 'SimpleMedicationPlanning',
        error: {
          'id': medicationId,
          'name': widget.medicationName,
          'frequency': widget.frequency.toString(),
          'startDate': _startDate?.toIso8601String(),
          'firstIntakeTime': _firstIntakeTime?.format(context),
          'quantity': _quantity,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.medicationName} dodano!')),
        );
        context.go('/');
      }
    } catch (e) {
      developer.log('Error saving medication', name: 'SimpleMedicationPlanning', error: e);
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
                  label: 'Količina',
                  value: '$_quantity',
                  onTap: _selectQuantity,
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
                onPressed: _handleSave,
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
            ],
          ),
        ),
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
