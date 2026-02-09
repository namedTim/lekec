import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../database/tables/onboarding_settings.dart';

class UserSetupScreen extends StatefulWidget {
  final UserType userType;
  final Function(
    String? familyName,
    List<String> userNames,
    List<int?> userAges,
  )
  onNext;

  const UserSetupScreen({
    super.key,
    required this.userType,
    required this.onNext,
  });

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _familyNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final List<String> _userNames = [];
  final List<int?> _userAges = [];
  int? _selectedBirthYear;

  @override
  void dispose() {
    _familyNameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthYear() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthYear != null
        ? DateTime(_selectedBirthYear!)
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
        _selectedBirthYear = picked.year;
      });
    }
  }

  int? _calculateAge() {
    if (_selectedBirthYear == null) return null;
    final now = DateTime.now();
    return now.year - _selectedBirthYear!;
  }

  void _addUser() {
    final name = _userNameController.text.trim();
    if (name.isNotEmpty && !_userNames.contains(name)) {
      setState(() {
        _userNames.add(name);
        _userAges.add(_calculateAge());
        _userNameController.clear();
        _selectedBirthYear = null;
      });
    }
  }

  void _removeUser(int index) {
    setState(() {
      _userNames.removeAt(index);
      _userAges.removeAt(index);
    });
  }

  bool get _canContinue {
    if (widget.userType == UserType.personal) {
      return _userNames.isNotEmpty;
    } else {
      return _userNames.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(''), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),

                    Text(
                      _getTitle(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _getSubtitle(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Family Name (only for family type)
                    if (widget.userType == UserType.family) ...[
                      TextField(
                        controller: _familyNameController,
                        decoration: InputDecoration(
                          labelText: 'Priimek družine (neobvezno)',
                          hintText: 'npr. Novak',
                          prefixIcon: const Icon(Symbols.family_restroom),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // User Name Input
                    TextField(
                      controller: _userNameController,
                      decoration: InputDecoration(
                        labelText: _getInputLabel(),
                        hintText: widget.userType == UserType.personal
                            ? (_userNames.isEmpty
                                  ? 'Vnesite svoje ime'
                                  : 'Vnesite še eno ime')
                            : widget.userType == UserType.family
                            ? 'Ime'
                            : 'Ime',
                        prefixIcon: const Icon(Symbols.person_add),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _addUser(),
                    ),

                    const SizedBox(height: 12),

                    // Birth Year Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
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
                                _selectedBirthYear != null
                                    ? '$_selectedBirthYear (${_calculateAge()} let)'
                                    : 'Tapnite za izbiro',
                                style: TextStyle(
                                  color: _selectedBirthYear != null
                                      ? null
                                      : colors.onSurfaceVariant.withOpacity(
                                          0.6,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _userNameController.text.trim().isNotEmpty
                              ? _addUser
                              : null,
                          icon: const Icon(Symbols.add),
                          label: const Text('Dodaj'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info box for personal mode after first user added
                    if (widget.userType == UserType.personal &&
                        _userNames.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Symbols.info, color: colors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Po potrebi lahko dodate še druge osebe (npr. družinski člani)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Users List
                    if (_userNames.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Symbols.group, color: colors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Uporabniki (${_userNames.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_userNames.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colors.primaryContainer,
                                child: Text(
                                  _userNames[index][0].toUpperCase(),
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(_userNames[index]),
                              subtitle: _userAges[index] != null
                                  ? Text('${_userAges[index]} let')
                                  : null,
                              trailing: IconButton(
                                icon: Icon(Symbols.delete, color: colors.error),
                                onPressed: () => _removeUser(index),
                              ),
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Symbols.person_add,
                              size: 48,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dodajte vsaj enega uporabnika',
                              style: TextStyle(color: colors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton(
                onPressed: _canContinue
                    ? () {
                        widget.onNext(
                          widget.userType == UserType.family
                              ? _familyNameController.text.trim().isEmpty
                                    ? null
                                    : _familyNameController.text.trim()
                              : null,
                          _userNames,
                          _userAges,
                        );
                      }
                    : null,
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
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.userType) {
      case UserType.personal:
        return _userNames.isEmpty
            ? 'Vnesite vaše ime'
            : 'Odlično, ${_userNames[0]}!';
      case UserType.family:
        return 'Kdo bo uporabljal aplikacijo?';
      case UserType.caregiver:
        return 'Dodajte osebe, za katere skrbite';
    }
  }

  String _getInputLabel() {
    switch (widget.userType) {
      case UserType.personal:
        return _userNames.isEmpty ? 'Vaše ime' : 'Ime dodatne osebe';
      case UserType.family:
        return 'Ime člana družine';
      case UserType.caregiver:
        return 'Ime pacienta';
    }
  }

  String _getSubtitle() {
    switch (widget.userType) {
      case UserType.personal:
        return _userNames.isEmpty
            ? 'Vnesite svoje ime za personalizirano izkušnjo'
            : 'Če želite, lahko dodate še druge osebe';
      case UserType.family:
        return 'Dodajte družinske člane, ki bodo uporabljali aplikacijo';
      case UserType.caregiver:
        return 'Dodajte imena oseb, katerim pomagate pri jemanju zdravil';
    }
  }
}
