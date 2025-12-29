import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lekec/database/tables/medications.dart';

enum FrequencyOption {
  onceDaily,
  twiceDaily,
  asNeeded,
  moreOptions,
}

class MedicationFrequencySelectionScreen extends StatefulWidget {
  final String medicationName;
  final MedicationType medType;

  const MedicationFrequencySelectionScreen({
    super.key,
    required this.medicationName,
    required this.medType,
  });

  @override
  State<MedicationFrequencySelectionScreen> createState() =>
      _MedicationFrequencySelectionScreenState();
}

class _MedicationFrequencySelectionScreenState
    extends State<MedicationFrequencySelectionScreen> {
  FrequencyOption? _selectedFrequency;

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

  void _handleNext() {
    if (_selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izberite možnost')),
      );
      return;
    }

    if (_selectedFrequency == FrequencyOption.moreOptions) {
      // TODO: Navigate to complex medication planning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Napredne možnosti - kmalu')),
      );
    } else {
      context.push(
        '/add-medication/simple-planning',
        extra: {
          'name': widget.medicationName,
          'medType': widget.medType,
          'frequency': _selectedFrequency,
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
              const SizedBox(height: 48),
              Expanded(
                child: ListView.separated(
                  itemCount: FrequencyOption.values.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final option = FrequencyOption.values[index];
                    return _FrequencyOptionButton(
                      label: _getFrequencyLabel(option),
                      isSelected: _selectedFrequency == option,
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

class _FrequencyOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyOptionButton({
    required this.label,
    required this.isSelected,
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
          ],
        ),
      ),
    );
  }
}
