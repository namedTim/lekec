import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../utils/gender_guesser.dart';

/// Result returned from AddUserDialog containing the user's name and optional age.
class AddUserResult {
  final String name;
  final int? age;
  final String? gender;

  AddUserResult({required this.name, this.age, this.gender});
}

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _birthYear;
  String? _selectedGender;
  bool _manualGenderSelection = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_manualGenderSelection) return;
    final guess = guessGenderFromName(_nameController.text);
    if (guess != _selectedGender) {
      setState(() => _selectedGender = guess);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthYear() async {
    final now = DateTime.now();
    final initialDate = _birthYear != null
        ? DateTime(_birthYear!)
        : DateTime(now.year - 18);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Izberite leto rojstva',
      cancelText: 'Prekliči',
      confirmText: 'Potrdi',
    );

    if (picked != null) {
      setState(() {
        _birthYear = picked.year;
      });
    }
    if (mounted) FocusScope.of(context).unfocus();
  }

  int? _calculateAge() {
    if (_birthYear == null) return null;
    final now = DateTime.now();
    return now.year - _birthYear!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final age = _calculateAge();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Symbols.person_add, color: colors.primary, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Dodaj uporabnika',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Ime uporabnika',
                hintText: 'Vnesite ime',
                prefixIcon: const Icon(Symbols.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Prosim vnesite ime';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectBirthYear,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Leto rojstva (neobvezno)',
                  prefixIcon: const Icon(Symbols.cake),
                  suffixIcon: const Icon(Symbols.calendar_month),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _birthYear != null
                      ? '$_birthYear (${age} let)'
                      : 'Tapnite za izbiro',
                  style: TextStyle(
                    color: _birthYear != null
                        ? null
                        : colors.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Gender picker
            Text(
              'Spol (neobvezno)',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'male',
                  label: Text('Moški'),
                  icon: Icon(Symbols.male),
                ),
                ButtonSegment<String>(
                  value: 'female',
                  label: Text('Ženski'),
                  icon: Icon(Symbols.female),
                ),
              ],
              selected: _selectedGender != null ? {_selectedGender!} : {},
              onSelectionChanged: (selected) {
                setState(() {
                  _manualGenderSelection = true;
                  _selectedGender = selected.isEmpty ? null : selected.first;
                });
              },
              emptySelectionAllowed: true,
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                visualDensity: VisualDensity.comfortable,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Prekliči'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                AddUserResult(
                  name: _nameController.text.trim(),
                  age: _calculateAge(),
                  gender: _selectedGender,
                ),
              );
            }
          },
          child: const Text('Dodaj'),
        ),
      ],
    );
  }
}
