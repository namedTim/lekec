import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Result returned from AddUserDialog containing the user's name and optional age.
class AddUserResult {
  final String name;
  final int? age;

  AddUserResult({required this.name, this.age});
}

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Starost (neobvezno)',
                hintText: 'Vnesite starost',
                prefixIcon: const Icon(Symbols.cake),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final age = int.tryParse(value.trim());
                  if (age == null || age < 0 || age > 150) {
                    return 'Vnesite veljavno starost';
                  }
                }
                return null;
              },
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
              final ageText = _ageController.text.trim();
              final age = ageText.isNotEmpty ? int.tryParse(ageText) : null;
              Navigator.of(context).pop(
                AddUserResult(
                  name: _nameController.text.trim(),
                  age: age,
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
