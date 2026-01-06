import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lekec/database/drift_database.dart';
import 'package:lekec/database/tables/medications.dart';
import 'package:lekec/features/core/providers/database_provider.dart';
import 'package:lekec/utils/medication_utils.dart';
import 'package:lekec/main.dart' show homePageKey;

class AddSingleEntryQuantityScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;

  const AddSingleEntryQuantityScreen({
    super.key,
    required this.medicationName,
    required this.medType,
  });

  @override
  ConsumerState<AddSingleEntryQuantityScreen> createState() =>
      _AddSingleEntryQuantityScreenState();
}

class _AddSingleEntryQuantityScreenState
    extends ConsumerState<AddSingleEntryQuantityScreen> {
  int _quantity = 1;
  final _textController = TextEditingController(text: '1');
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final value = int.tryParse(_textController.text);
      if (value != null && value >= 1 && value <= 99) {
        setState(() => _quantity = value);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    if (_quantity < 99) {
      setState(() {
        _quantity++;
        _textController.text = _quantity.toString();
      });
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _textController.text = _quantity.toString();
      });
    }
  }

  Future<void> _handleSave() async {
    final db = ref.read(databaseProvider);

    try {
      // Find existing medication or create new one
      final existingMeds = await (db.select(db.medications)
            ..where((m) => m.name.equals(widget.medicationName))
            ..where((m) => m.medType.equalsValue(widget.medType)))
          .get();

      int medicationId;
      if (existingMeds.isNotEmpty) {
        medicationId = existingMeds.first.id;
      } else {
        // Create new medication
        medicationId = await db.into(db.medications).insert(
              MedicationsCompanion(
                name: drift.Value(widget.medicationName),
                medType: drift.Value(widget.medType),
              ),
            );
      }

      // Create a one-time intake log entry
      await db.into(db.medicationIntakeLogs).insert(
            MedicationIntakeLogsCompanion(
              userId: const drift.Value(1), // TODO: Get from current user
              medicationId: drift.Value(medicationId),
              planId: const drift.Value(0), // No plan for one-time entries
              scheduledTime: drift.Value(DateTime.now()),
              wasTaken: const drift.Value(true),
              takenTime: drift.Value(DateTime.now()),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vnos zabeležen: $_quantity ${getMedicationUnitShort(widget.medType)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh home page
        homePageKey.currentState?.loadTodaysIntakes();

        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Napaka: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                widget.medicationName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Vnesite število ${getMedicationUnitShort(widget.medType)} za vnos',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),

              // Quantity selector
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Decrement button
                    Container(
                      decoration: BoxDecoration(
                        color: _quantity > 1 ? colors.primary : colors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _quantity > 1 ? _decrement : null,
                        icon: const Icon(Symbols.remove),
                        color: _quantity > 1 ? colors.onPrimary : colors.onSurfaceVariant,
                        iconSize: 28,
                      ),
                    ),
                    const SizedBox(width: 48),

                    // Editable number
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed < 1) {
                            _textController.text = '1';
                          } else if (parsed > 99) {
                            _textController.text = '99';
                          }
                          _focusNode.unfocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 48),

                    // Increment button
                    Container(
                      decoration: BoxDecoration(
                        color: _quantity < 99 ? colors.primary : colors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _quantity < 99 ? _increment : null,
                        icon: const Icon(Symbols.add),
                        color: _quantity < 99 ? colors.onPrimary : colors.onSurfaceVariant,
                        iconSize: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: _handleSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Shrani',
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
}
