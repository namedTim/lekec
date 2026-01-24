import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/tables/medications.dart';

class SpecificDaysPlanningScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final String intakeAdvice;

  const SpecificDaysPlanningScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.intakeAdvice,
  });

  @override
  ConsumerState<SpecificDaysPlanningScreen> createState() =>
      _SpecificDaysPlanningScreenState();
}

class _SpecificDaysPlanningScreenState
    extends ConsumerState<SpecificDaysPlanningScreen> {
  final Set<int> _selectedDays = {};

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
        title: const Text('Specifični dnevi'),
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
                'Izberite dneve v tednu',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Day selection
              Expanded(
                child: ListView.builder(
                  itemCount: _dayNames.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedDays.contains(index);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.remove(index);
                            } else {
                              _selectedDays.add(index);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Symbols.check_circle
                                    : Symbols.circle,
                                color: isSelected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                _dayNames[index],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colors.onPrimaryContainer
                                      : colors.onSurface,
                                ),
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
                onPressed: _selectedDays.isNotEmpty ? _handleContinue : null,
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

  void _handleContinue() {
    // Navigate to time selection screen
    context.push(
      '/add-medication/advanced-planning/specific-days/times',
      extra: {
        'name': widget.medicationName,
        'medType': widget.medType,
        'selectedDays': _selectedDays.toList(),
        'intakeAdvice': widget.intakeAdvice,
      },
    );
  }
}
