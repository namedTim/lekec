import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../components/quantity_selector.dart';
import '../../database/tables/medications.dart';
import '../../helpers/medication_unit_helper.dart';

class MedicationDetailsCard extends StatelessWidget {
  const MedicationDetailsCard({
    super.key,
    required this.medName,
    required this.dosage,
    required this.pillsRemaining,
    required this.frequency,
    required this.times,
    required this.medType,
    this.userName,
    this.onAddMedication,
    this.onDelete,
    this.isAsNeeded = false,
    this.onLogIntake,
  });

  final String medName;
  final String? userName;
  final String dosage;
  final int pillsRemaining;
  final String frequency;
  final List<String> times;
  final MedicationType medType;
  final Function(double)? onAddMedication;
  final VoidCallback? onDelete;
  final bool isAsNeeded;
  final VoidCallback? onLogIntake;

  Color _getPillCountColor(int count) {
    if (count >= 20) {
      return const Color(0xFF22C55E); // Green - plenty
    } else if (count >= 15) {
      return const Color(0xFF84CC16); // Lime - good
    } else if (count >= 10) {
      return const Color(0xFFFBBF24); // Yellow - moderate
    } else if (count >= 5) {
      return const Color(0xFFFB923C); // Orange - low
    } else if (count >= 2) {
      return const Color(0xFFF87171); // Red-orange - very low
    } else {
      return const Color(0xFFEF4444); // Red - critical
    }
  }

  String _getTimesText() {
    if (times.isEmpty) return '';

    // For interval medications (Vsakih X ur/dni), show next time only
    if (frequency.startsWith('Vsakih')) {
      return times.isNotEmpty ? 'naslednjič ob ${times[0]}' : '';
    }

    // For other medications, use "in" for the last item
    if (times.length == 1) {
      return 'ob ${times[0]}';
    }
    final allButLast = times.sublist(0, times.length - 1).join(', ');
    return 'ob $allButLast in ${times.last}';
  }

  Future<void> _handleAddMedication(BuildContext context) async {
    final quantity = await showQuantitySelector(
      context,
      initialValue: 1,
      minValue: -pillsRemaining.toDouble(),
      maxValue: 99999,
      step: 1,
      label: 'Število ${getMedicationUnitShort(medType, 5)}',
    );
    if (quantity != null) {
      onAddMedication?.call(quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dismissible(
      key: Key('medication_$medName${DateTime.now().millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Symbols.delete, color: colors.onError, size: 36),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
        return false; // Don't actually dismiss, let parent handle it
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine name + dosage
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          medName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dosage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Frequency and times
                  Row(
                    children: [
                      Icon(Symbols.schedule, size: 16, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          frequency.startsWith('Vsakih') &&
                                  _getTimesText().isNotEmpty
                              ? '$frequency, ${_getTimesText()}'
                              : '$frequency ${_getTimesText()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Remaining pills chip + user name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getPillCountColor(pillsRemaining),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pillsRemaining preostalo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (userName != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Symbols.person, size: 14, color: colors.primary),
                            const SizedBox(width: 4),
                            Text(
                              userName!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAsNeeded && onLogIntake != null)
                  Container(
                    margin: const EdgeInsets.only(left: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onLogIntake,
                      icon: const Icon(Symbols.add_circle),
                      color: colors.onPrimary,
                      tooltip: 'Zabeleži vnos',
                      iconSize: 22,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _handleAddMedication(context),
                    icon: const Icon(Symbols.add),
                    color: colors.onSurfaceVariant,
                    tooltip: 'Upravljaj zalogo',
                    iconSize: 22,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
