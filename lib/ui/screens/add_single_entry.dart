import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/tables/medications.dart';

class AddSingleEntryScreen extends ConsumerStatefulWidget {
  const AddSingleEntryScreen({super.key});

  @override
  ConsumerState<AddSingleEntryScreen> createState() =>
      _AddSingleEntryScreenState();
}

class _AddSingleEntryScreenState extends ConsumerState<AddSingleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  MedicationType _selectedType = MedicationType.pills;

  @override
  void dispose() {
    _medicationNameController.dispose();
    super.dispose();
  }

  String _getMedicationTypeLabel(MedicationType type) {
    switch (type) {
      case MedicationType.pills:
        return 'Tablete';
      case MedicationType.ampules:
        return 'Ampule';
      case MedicationType.applications:
        return 'Nanosi';
      case MedicationType.capsules:
        return 'Kapsule';
      case MedicationType.drops:
        return 'Kapljice';
      case MedicationType.grams:
        return 'Grami';
      case MedicationType.injections:
        return 'Injekcije';
      case MedicationType.milligrams:
        return 'Miligrami';
      case MedicationType.milliliters:
        return 'Mililiter';
      case MedicationType.patches:
        return 'Obliži';
      case MedicationType.pieces:
        return 'Kosi';
      case MedicationType.portions:
        return 'Porcije';
      case MedicationType.puffs:
        return 'Puhljaji';
      case MedicationType.sprays:
        return 'Pršila';
      case MedicationType.tablespoons:
        return 'Žličke';
      case MedicationType.units:
        return 'Enote';
      case MedicationType.micrograms:
        return 'Mikrogrami';
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      context.push(
        '/add-single-entry/quantity',
        extra: {
          'name': _medicationNameController.text.trim(),
          'medType': _selectedType,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => context.pop(),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Katero zdravilo ste vzeli?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Name Input
                TextFormField(
                  controller: _medicationNameController,
                  decoration: InputDecoration(
                    labelText: 'Ime zdravila',
                    hintText: 'Vnesite ime zdravila',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vnesite ime zdravila';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Dropdown - Type selector
                DropdownButtonFormField<MedicationType>(
                  value: _selectedType,
                  isExpanded: true,
                  menuMaxHeight: 400,
                  alignment: Alignment.center,
                  decoration: InputDecoration(
                    labelText: 'Vrsta zdravila',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  selectedItemBuilder: (BuildContext context) {
                    return MedicationType.values.map<Widget>((
                      MedicationType type,
                    ) {
                      return Center(
                        child: Text(
                          _getMedicationTypeLabel(type),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList();
                  },
                  items: MedicationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: screenWidth * 0.6,
                        child: Text(
                          _getMedicationTypeLabel(type),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),

                const SizedBox(height: 48),

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
      ),
    );
  }
}
