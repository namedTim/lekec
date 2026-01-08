import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lekec/database/tables/medications.dart';

class CyclicPlanningScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final String intakeAdvice;

  const CyclicPlanningScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.intakeAdvice,
  });

  @override
  ConsumerState<CyclicPlanningScreen> createState() =>
      _CyclicPlanningScreenState();
}

class _CyclicPlanningScreenState extends ConsumerState<CyclicPlanningScreen> {
  final _takingDaysController = TextEditingController(text: '10');
  final _pauseDaysController = TextEditingController(text: '20');

  @override
  void dispose() {
    _takingDaysController.dispose();
    _pauseDaysController.dispose();
    super.dispose();
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
        title: const Text('Ciklično jemanje'),
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
                'Nastavite cikel jemanja',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Taking days
              Text(
                'Dni jemanja',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _takingDaysController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  hintText: 'Npr. 10',
                  suffixText: 'dni',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Pause days
              Text(
                'Dni pavze',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pauseDaysController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  hintText: 'Npr. 20',
                  suffixText: 'dni',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Preview
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
                        'Cikel: ${_takingDaysController.text} dni jemanja, ${_pauseDaysController.text} dni pavze',
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
    final takingDays = int.tryParse(_takingDaysController.text) ?? 0;
    final pauseDays = int.tryParse(_pauseDaysController.text) ?? 0;

    if (takingDays <= 0 || pauseDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prosim vnesite veljavne vrednosti'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to time configuration
    context.push('/add-medication/advanced-planning/cyclic/configure', extra: {
      'name': widget.medicationName,
      'medType': widget.medType,
      'takingDays': takingDays,
      'pauseDays': pauseDays,
      'intakeAdvice': widget.intakeAdvice,
    });
  }
}
