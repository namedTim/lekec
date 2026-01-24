import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/tables/medications.dart';

enum IntervalType { hours, days }

class IntervalPlanningScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final String intakeAdvice;

  const IntervalPlanningScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.intakeAdvice,
  });

  @override
  ConsumerState<IntervalPlanningScreen> createState() =>
      _IntervalPlanningScreenState();
}

class _IntervalPlanningScreenState
    extends ConsumerState<IntervalPlanningScreen> {
  IntervalType _selectedType = IntervalType.hours;
  int _intervalValue = 8;

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
        title: const Text('Interval'),
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
                'Izberite interval jemanja',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Type selector buttons
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      type: IntervalType.hours,
                      label: 'Vsakih X ur',
                      icon: Symbols.schedule,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTypeButton(
                      type: IntervalType.days,
                      label: 'Vsakih X dni',
                      icon: Symbols.calendar_today,
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Remind every
              Text(
                'Opomni vsakih',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Interval value selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<int>(
                  value: _intervalValue,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: List.generate(
                    _selectedType == IntervalType.hours ? 24 : 30,
                    (index) {
                      final value = index + 1;
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          '$value ${_selectedType == IntervalType.hours ? "ur" : "dni"}',
                        ),
                      );
                    },
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _intervalValue = value);
                    }
                  },
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: _handleContinue,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Naprej',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required IntervalType type,
    required String label,
    required IconData icon,
    required ColorScheme colors,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() {
        _selectedType = type;
        _intervalValue = type == IntervalType.hours ? 8 : 1;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    // Navigate to time selection or final configuration
    context.push(
      '/add-medication/advanced-planning/interval/configure',
      extra: {
        'name': widget.medicationName,
        'medType': widget.medType,
        'intervalType': _selectedType,
        'intervalValue': _intervalValue,
        'intakeAdvice': widget.intakeAdvice,
      },
    );
  }
}
