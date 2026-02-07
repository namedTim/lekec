import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/tables/medications.dart';
import '../../services/gemini_medication_service.dart';
import '../components/step_progress_indicator.dart';

enum FrequencyOption { onceDaily, twiceDaily, asNeeded, moreOptions }

class MedicationFrequencySelectionScreen extends StatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final String intakeAdvice;
  final int userId;
  final MedicationExtractionResult? extractedData;

  const MedicationFrequencySelectionScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.intakeAdvice,
    required this.userId,
    this.extractedData,
  });

  @override
  State<MedicationFrequencySelectionScreen> createState() =>
      _MedicationFrequencySelectionScreenState();
}

class _MedicationFrequencySelectionScreenState
    extends State<MedicationFrequencySelectionScreen> {
  FrequencyOption? _selectedFrequency;

  @override
  void initState() {
    super.initState();
    // Auto-select frequency if extracted from label
    if (widget.extractedData?.dosageFrequency != null) {
      final suggestedFrequency = widget.extractedData!.dosageFrequency!.toFrequencyOption();
      if (suggestedFrequency != null) {
        _selectedFrequency = suggestedFrequency;
      }
    }
  }

  String _getFrequencyLabel(FrequencyOption option) {
    switch (option) {
      case FrequencyOption.onceDaily:
        return 'Enkrat dnevno';
      case FrequencyOption.twiceDaily:
        return 'Dvakrat dnevno';
      case FrequencyOption.asNeeded:
        return 'Po potrebi (ne potrebujem opomnika)';
      case FrequencyOption.moreOptions:
        return 'Potrebujem več opcij';
    }
  }

  /// Check if this option was suggested by AI
  bool _isSuggestedByAI(FrequencyOption option) {
    if (widget.extractedData?.dosageFrequency == null) return false;
    return widget.extractedData!.dosageFrequency!.toFrequencyOption() == option;
  }

  void _handleNext() {
    if (_selectedFrequency == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Izberite možnost')));
      return;
    }

    if (_selectedFrequency == FrequencyOption.moreOptions) {
      // Navigate to advanced medication planning
      context.push(
        '/add-medication/advanced-planning',
        extra: {
          'name': widget.medicationName,
          'medType': widget.medType,
          'intakeAdvice': widget.intakeAdvice,
          'userId': widget.userId,
          'extractedData': widget.extractedData,
        },
      );
    } else {
      context.push(
        '/add-medication/simple-planning',
        extra: {
          'name': widget.medicationName,
          'medType': widget.medType,
          'frequency': _selectedFrequency,
          'intakeAdvice': widget.intakeAdvice,
          'userId': widget.userId,
          'extractedData': widget.extractedData,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Kako pogosto boste jemali ${widget.medicationName}?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              // Show AI suggestion hint if available
              if (widget.extractedData?.dosageFrequency?.rawText != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.auto_awesome,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Z nalepke: "${widget.extractedData!.dosageFrequency!.rawText}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              Expanded(
                child: ListView.separated(
                  itemCount: FrequencyOption.values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final option = FrequencyOption.values[index];
                    return _FrequencyOptionButton(
                      label: _getFrequencyLabel(option),
                      isSelected: _selectedFrequency == option,
                      isSuggestedByAI: _isSuggestedByAI(option),
                      onTap: () {
                        setState(() {
                          _selectedFrequency = option;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _handleNext,
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: const StepProgressIndicator(
        currentStep: 2,
        totalSteps: 3,
      ),
    );
  }
}

class _FrequencyOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isSuggestedByAI;
  final VoidCallback onTap;

  const _FrequencyOptionButton({
    required this.label,
    required this.isSelected,
    this.isSuggestedByAI = false,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSuggestedByAI)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.auto_awesome, size: 14, color: colors.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
