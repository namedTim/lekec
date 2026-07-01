import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../utils/gender_guesser.dart';

class UserSetupScreen extends StatefulWidget {
  /// Reports the people to create. The first entry is the app owner (the row
  /// the dashboard greeting reads); any further entries are additional people
  /// (family members, patients, …) the user chose to add.
  final Function(
    List<String> userNames,
    List<int?> userAges,
    List<String?> userGenders,
  )
  onNext;

  const UserSetupScreen({
    super.key,
    required this.onNext,
  });

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _userNameController = TextEditingController();
  final _userNameFocusNode = FocusNode();
  final List<String> _userNames = [];
  final List<int?> _userAges = [];
  final List<String?> _userGenders = [];
  int? _selectedBirthYear;
  String? _selectedGender;
  bool _manualGenderSelection = false;

  @override
  void initState() {
    super.initState();
    _userNameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (!_manualGenderSelection) {
      final guess = guessGenderFromName(_userNameController.text);
      if (guess != _selectedGender) {
        _selectedGender = guess;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userNameFocusNode.dispose();
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
    if (mounted) _userNameFocusNode.unfocus();
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
        _userGenders.add(_selectedGender);
        _userNameController.clear();
        _selectedBirthYear = null;
        _selectedGender = null;
        _manualGenderSelection = false;
      });
    }
  }

  void _removeUser(int index) {
    setState(() {
      _userNames.removeAt(index);
      _userAges.removeAt(index);
      _userGenders.removeAt(index);
    });
  }

  // The first person added is the app owner (greeting target); at least one
  // person is required to continue.
  bool get _canContinue => _userNames.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text(''), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
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

                    // User Name Input
                    TextField(
                      controller: _userNameController,
                      focusNode: _userNameFocusNode,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: _getInputLabel(),
                        hintText: _userNames.isEmpty
                            ? 'Vnesite svoje ime'
                            : 'Vnesite še eno ime',
                        prefixIcon: const Icon(Symbols.person_add),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Gender Picker
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spol (neobvezno)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
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
                                selected: _selectedGender != null
                                    ? {_selectedGender!}
                                    : {},
                                onSelectionChanged: (selected) {
                                  setState(() {
                                    _manualGenderSelection = true;
                                    _selectedGender = selected.isEmpty
                                        ? null
                                        : selected.first;
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

                    // Once the owner is added, hint that more people can be added
                    if (_userNames.isNotEmpty) ...[
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
                              subtitle: _buildUserSubtitle(index),
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
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton(
                onPressed: _canContinue
                    ? () {
                        widget.onNext(
                          List<String>.from(_userNames),
                          List<int?>.from(_userAges),
                          List<String?>.from(_userGenders),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
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

  String _getTitle() => _userNames.isEmpty
      ? 'Vnesite vaše ime'
      : 'Odlično, ${_userNames[0]}!';

  String _getInputLabel() =>
      _userNames.isEmpty ? 'Vaše ime' : 'Ime dodatne osebe';

  String _getSubtitle() => _userNames.isEmpty
      ? 'Vnesite svoje ime za personalizirano izkušnjo'
      : 'Če želite, lahko dodate še druge osebe (npr. družinski člani ali osebe, za katere skrbite)';

  Widget? _buildUserSubtitle(int index) {
    final parts = <String>[];
    if (_userAges[index] != null) parts.add('${_userAges[index]} let');
    if (_userGenders[index] != null)
      parts.add(_genderLabel(_userGenders[index]!));
    return parts.isNotEmpty ? Text(parts.join(' · ')) : null;
  }

  String _genderLabel(String gender) {
    switch (gender) {
      case 'female':
        return 'Ženski';
      case 'male':
        return 'Moški';
      default:
        return gender;
    }
  }
}
