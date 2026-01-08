import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lekec/database/tables/medications.dart';

class MultipleTimesPlanningScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final String intakeAdvice;

  const MultipleTimesPlanningScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.intakeAdvice,
  });

  @override
  ConsumerState<MultipleTimesPlanningScreen> createState() =>
      _MultipleTimesPlanningScreenState();
}

class _MultipleTimesPlanningScreenState
    extends ConsumerState<MultipleTimesPlanningScreen> {
  int _timesPerDay = 2;

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
        title: const Text('Večkrat dnevno'),
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
                'Kolikokrat dnevno želite jemati zdravilo?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Intakes label
              Text(
                'Intakes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Times selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<int>(
                  value: _timesPerDay,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: List.generate(
                    10,
                    (index) {
                      final value = index + 1;
                      return DropdownMenuItem(
                        value: value,
                        child: Text('$value-krat dnevno'),
                      );
                    },
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _timesPerDay = value);
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

  void _handleContinue() {
    // Navigate to time selection screen
    context.push('/add-medication/advanced-planning/multiple-times/times',
        extra: {
          'name': widget.medicationName,
          'medType': widget.medType,
          'timesPerDay': _timesPerDay,
          'intakeAdvice': widget.intakeAdvice,
        });
  }
}
