import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lekec/database/drift_database.dart';
import 'package:lekec/database/tables/medications.dart';
import 'package:lekec/features/core/providers/database_provider.dart';
import 'dart:developer' as developer;

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
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
      case MedicationType.pills: return 'Tablete';
      case MedicationType.ampules: return 'Ampule';
      case MedicationType.applications: return 'Aplikacije';
      case MedicationType.capsules: return 'Kapsule';
      case MedicationType.drops: return 'Kapljice';
      case MedicationType.grams: return 'Grami';
      case MedicationType.injections: return 'Injekcije';
      case MedicationType.milligrams: return 'Miligrami';
      case MedicationType.milliliters: return 'Mililiter';
      case MedicationType.patches: return 'Obliži';
      case MedicationType.pieces: return 'Kosi';
      case MedicationType.portions: return 'Porcije';
      case MedicationType.puffs: return 'Puhljaji';
      case MedicationType.sprays: return 'Pršila';
      case MedicationType.tablespoons: return 'Žlice';
      case MedicationType.units: return 'Enote';
      case MedicationType.micrograms: return 'Mikrogrami';
    }
  }

  Future<void> _handleNext() async {
    if (_formKey.currentState!.validate()) {
      // final db = ref.read(databaseProvider);
      // 
      // final medicationCompanion = MedicationsCompanion(
      //   name: drift.Value(_medicationNameController.text),
      //   medType: drift.Value(_selectedType),
      // );
      //
      // try {
      //   final id = await db.into(db.medications).insert(medicationCompanion);
      //   developer.log('Medication added', name: 'AddMedication');
      // } catch (e) {
      //   developer.log('Error adding medication', name: 'AddMedication', error: e);
      // }

      if (mounted) {
        context.push(
          '/add-medication/frequency',
          extra: {
            'name': _medicationNameController.text,
            'medType': _selectedType,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get screen width to calculate the 60% constraint
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
                  'Katero zdravilo želite dodati?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Name Input - Full Width
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

                // Dropdown - Button is Full Width, Content is Centered
                DropdownButtonFormField<MedicationType>(
                  value: _selectedType,
                  isExpanded: true,
                  menuMaxHeight: 400,
                  // 1. Center the text in the button itself
                  alignment: Alignment.center, 
                  decoration: InputDecoration(
                    labelText: 'Vrsta zdravila',
                    // Center the label if possible, or leave default
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  
                  // 2. Center the selected item text
                  selectedItemBuilder: (BuildContext context) {
                    return MedicationType.values.map<Widget>((MedicationType type) {
                      return Center(
                        child: Text(
                          _getMedicationTypeLabel(type),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList();
                  },

                  // 3. Constrain the Popup Menu Items to 60% Width and Center them
                  items: MedicationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      alignment: Alignment.center, // Aligns item in the menu
                      child: SizedBox(
                        // This forces the text content to be max 60% of screen width
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