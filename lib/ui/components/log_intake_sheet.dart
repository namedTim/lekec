import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/tables/medications.dart';
import '../../helpers/medication_unit_helper.dart';

/// Shows a bottom sheet for logging an as-needed intake.
/// Returns a map with 'time' (TimeOfDay) and 'quantity' (int), or null if cancelled.
Future<Map<String, dynamic>?> showLogIntakeSheet({
  required BuildContext context,
  required String medicationName,
  required MedicationType medType,
  required int defaultQuantity,
}) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _LogIntakeSheet(
      medicationName: medicationName,
      medType: medType,
      defaultQuantity: defaultQuantity,
    ),
  );
}

class _LogIntakeSheet extends StatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final int defaultQuantity;

  const _LogIntakeSheet({
    required this.medicationName,
    required this.medType,
    required this.defaultQuantity,
  });

  @override
  State<_LogIntakeSheet> createState() => _LogIntakeSheetState();
}

class _LogIntakeSheetState extends State<_LogIntakeSheet> {
  late TimeOfDay selectedTime;
  late int quantity;

  @override
  void initState() {
    super.initState();
    selectedTime = TimeOfDay.now();
    quantity = widget.defaultQuantity.clamp(1, 99);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Zabeleži vnos',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.medicationName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Time picker
          Text(
            'Čas zaužitja',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (picked != null) {
                setState(() => selectedTime = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: colors.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Symbols.schedule, color: colors.primary),
                  const SizedBox(width: 12),
                  Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Symbols.edit, size: 20, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quantity
          Text(
            'Količina',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filled(
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                icon: const Icon(Symbols.remove),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHighest,
                  foregroundColor: colors.onSurface,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$quantity ${getMedicationUnitShort(widget.medType, quantity)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: quantity < 99
                    ? () => setState(() => quantity++)
                    : null,
                icon: const Icon(Symbols.add),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHighest,
                  foregroundColor: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop({'time': selectedTime, 'quantity': quantity});
              },
              icon: const Icon(Symbols.check),
              label: const Text('Potrdi'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
