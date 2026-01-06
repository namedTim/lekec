import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lekec/database/tables/medications.dart';

enum AdvancedScheduleType {
  interval,
  multipleTimes,
  specificDays,
  cyclic,
}

class AdvancedMedicationPlanningScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;

  const AdvancedMedicationPlanningScreen({
    super.key,
    required this.medicationName,
    required this.medType,
  });

  @override
  ConsumerState<AdvancedMedicationPlanningScreen> createState() =>
      _AdvancedMedicationPlanningScreenState();
}

class _AdvancedMedicationPlanningScreenState
    extends ConsumerState<AdvancedMedicationPlanningScreen> {
  AdvancedScheduleType? _selectedType;

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
        title: const Text('Napredne možnosti'),
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
                'Izberite način jemanja',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              _buildScheduleOption(
                type: AdvancedScheduleType.interval,
                icon: Symbols.schedule,
                title: 'Interval',
                description: 'Na X ur ali X dni',
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildScheduleOption(
                type: AdvancedScheduleType.multipleTimes,
                icon: Symbols.counter_1,
                title: 'Večkrat dnevno',
                description: 'Določite število vnosov na dan',
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildScheduleOption(
                type: AdvancedScheduleType.specificDays,
                icon: Symbols.calendar_month,
                title: 'Specifični dnevi v tednu',
                description: 'Izberite dneve v tednu',
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildScheduleOption(
                type: AdvancedScheduleType.cyclic,
                icon: Symbols.cycle,
                title: 'Ciklično',
                description: 'Npr. 10 dni jemanja, 20 dni pavze',
                colors: colors,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _selectedType != null ? _handleContinue : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Naprej',
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

  Widget _buildScheduleOption({
    required AdvancedScheduleType type,
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colors,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colors.onPrimaryContainer
                              : colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Symbols.check_circle,
                color: colors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_selectedType == null) return;

    switch (_selectedType!) {
      case AdvancedScheduleType.interval:
        context.push('/add-medication/advanced-planning/interval', extra: {
          'name': widget.medicationName,
          'medType': widget.medType,
        });
        break;
      case AdvancedScheduleType.multipleTimes:
        context.push('/add-medication/advanced-planning/multiple-times', extra: {
          'name': widget.medicationName,
          'medType': widget.medType,
        });
        break;
      case AdvancedScheduleType.specificDays:
        context.push('/add-medication/advanced-planning/specific-days', extra: {
          'name': widget.medicationName,
          'medType': widget.medType,
        });
        break;
      case AdvancedScheduleType.cyclic:
        context.push('/add-medication/advanced-planning/cyclic', extra: {
          'name': widget.medicationName,
          'medType': widget.medType,
        });
        break;
    }
  }
}
