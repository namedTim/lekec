import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import '../../features/core/providers/database_provider.dart';
import '../components/step_progress_indicator.dart';
import '../components/confirmation_dialog.dart';
import 'dart:developer' as developer;

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _customIntakeAdviceController = TextEditingController();
  MedicationType _selectedType = MedicationType.pills;
  String _selectedIntakeAdvice = 'Ni posebnosti';
  bool _showCustomAdviceField = false;
  List<User> _users = [];
  int? _selectedUserId;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _customIntakeAdviceController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final db = ref.read(databaseProvider);
    
    // Get all users
    final users = await db.select(db.users).get();
    
    // If no users exist, create default "jaz" user
    if (users.isEmpty) {
      final id = await db.into(db.users).insert(
        UsersCompanion.insert(name: 'jaz'),
      );
      final jazUser = await (db.select(db.users)..where((u) => u.id.equals(id))).getSingle();
      users.add(jazUser);
    }
    
    // Find "jaz" user or use first user as default
    final jazUser = users.firstWhere(
      (u) => u.name.toLowerCase() == 'jaz',
      orElse: () => users.first,
    );
    
    setState(() {
      _users = users;
      _selectedUserId = jazUser.id;
      _isLoadingUsers = false;
    });
  }

  Future<void> _showAddUserDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj novega uporabnika'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ime uporabnika',
            hintText: 'Vnesite ime',
          ),
          autofocus: true,
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context, true);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Prekliči'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final userName = controller.text.trim();
      final db = ref.read(databaseProvider);
      final id = await db.into(db.users).insert(
        UsersCompanion.insert(name: userName),
      );
      final newUser = await (db.select(db.users)..where((u) => u.id.equals(id))).getSingle();
      
      setState(() {
        _users.add(newUser);
        _selectedUserId = newUser.id;
      });
    }
  }

  Future<void> _showDeleteUserDialog(User user) async {
    // Don't allow deleting the "jaz" user
    if (user.name.toLowerCase() == 'jaz') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privzeti uporabnik se ne more izbrisati')),
      );
      return;
    }

    final result = await showConfirmationDialog(
      context,
      title: 'Izbriši uporabnika',
      message: 'Ali ste prepričani, da želite izbrisati uporabnika "${user.name}"?',
      confirmText: 'Izbriši',
      cancelText: 'Prekliči',
    );

    if (result) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.users)..where((u) => u.id.equals(user.id))).go();
      
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
        
        // If the deleted user was selected, select "jaz" or first available user
        if (_selectedUserId == user.id) {
          final jazUser = _users.firstWhere(
            (u) => u.name.toLowerCase() == 'jaz',
            orElse: () => _users.first,
          );
          _selectedUserId = jazUser.id;
        }
      });
    }
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
        return 'Žlice';
      case MedicationType.units:
        return 'Enote';
      case MedicationType.micrograms:
        return 'Mikrogrami';
    }
  }

  Future<void> _handleNext() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izberite uporabnika')),
        );
        return;
      }

      // Determine final intake advice
      final intakeAdvice = _selectedIntakeAdvice == 'Po meri'
          ? _customIntakeAdviceController.text.trim()
          : _selectedIntakeAdvice;

      if (mounted) {
        context.push(
          '/add-medication/frequency',
          extra: {
            'name': _medicationNameController.text,
            'medType': _selectedType,
            'intakeAdvice': intakeAdvice,
            'userId': _selectedUserId,
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

                  // 2. Center the selected item text
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

                const SizedBox(height: 24),

                // Intake Advice Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedIntakeAdvice,
                  isExpanded: true,
                  alignment: Alignment.center,
                  decoration: InputDecoration(
                    labelText: 'Priporočilo pred zaužitjem',
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
                    return [
                      'Ni posebnosti',
                      'Pred obrokom',
                      'Z obrokom',
                      'Po obroku',
                      'Po meri',
                    ].map<Widget>((String value) {
                      return Center(
                        child: Text(value, textAlign: TextAlign.center),
                      );
                    }).toList();
                  },
                  items:
                      [
                        'Ni posebnosti',
                        'Pred obrokom',
                        'Z obrokom',
                        'Po obroku',
                        'Po meri',
                      ].map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: screenWidth * 0.6,
                            child: Text(value, textAlign: TextAlign.center),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedIntakeAdvice = value;
                        _showCustomAdviceField = value == 'Po meri';
                      });
                    }
                  },
                ),

                // Custom advice text field (shown when "Po meri" is selected)
                if (_showCustomAdviceField) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customIntakeAdviceController,
                    decoration: InputDecoration(
                      labelText: 'Prilagojeno priporočilo',
                      hintText: 'Vnesite svoje priporočilo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    validator: (value) {
                      if (_selectedIntakeAdvice == 'Po meri' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Vnesite priporočilo';
                      }
                      return null;
                    },
                    maxLines: 2,
                  ),
                ],

                const SizedBox(height: 40),

                // User Selection
                if (_isLoadingUsers)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Text(
                    'Kdo bo vzel zdravilo?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._users.map((user) => GestureDetector(
                        onLongPress: () => _showDeleteUserDialog(user),
                        child: ChoiceChip(
                          label: Text(user.name),
                          selected: _selectedUserId == user.id,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedUserId = user.id);
                            }
                          },
                        ),
                      )),
                      ActionChip(
                        avatar: const Icon(Symbols.add, size: 18),
                        label: const Text('Dodaj'),
                        onPressed: _showAddUserDialog,
                      ),
                    ],
                  ),
                ],

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
      bottomNavigationBar: const StepProgressIndicator(
        currentStep: 1,
        totalSteps: 3,
      ),
    );
  }
}
