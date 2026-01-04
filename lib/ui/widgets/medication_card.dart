import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum MedicationStatus {
  notTaken,
  taken,
  upcoming, // Not yet time to take
}

class MedicationCard extends StatefulWidget {
  const MedicationCard({
    super.key,
    required this.medName,
    required this.dosage,
    required this.medicineRemaining,
    required this.pillCount,
    required this.showName,
    required this.username,
    required this.userId,
    this.status = MedicationStatus.upcoming,
    this.onStatusChanged,
  });

  final String medName;
  final String dosage;
  final String medicineRemaining;
  final int pillCount;
  final bool showName;
  final String username;
  final String userId;
  final MedicationStatus status;
  final Function(MedicationStatus)? onStatusChanged;

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dismissible(
      key: Key('${widget.medName}_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}'),
      background: _buildSwipeBackground(colors, isLeft: true),
      secondaryBackground: _buildSwipeBackground(colors, isLeft: false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe from right - mark as taken
          widget.onStatusChanged?.call(MedicationStatus.taken);
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe from left - mark as not taken
          widget.onStatusChanged?.call(MedicationStatus.notTaken);
        }
        return false; // Don't actually dismiss the card
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🧾 Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine name
                  Text(
                    widget.medName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Dosage
                  Text(
                    widget.dosage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Remaining pills / info chip
                  if (widget.medicineRemaining.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPillCountColor(widget.pillCount),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.medicineRemaining,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Status indicator icon
            _buildStatusIcon(colors),

            // 👤 User badge
            if (widget.showName)
              Container(
                margin: const EdgeInsets.only(left: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.username,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colors) {
    IconData icon;
    Color iconColor;

    switch (widget.status) {
      case MedicationStatus.taken:
        icon = Symbols.check_circle;
        iconColor = Colors.green;
        break;
      case MedicationStatus.notTaken:
        icon = Symbols.cancel;
        iconColor = Colors.red;
        break;
      case MedicationStatus.upcoming:
        icon = Symbols.schedule;
        iconColor = colors.onSurfaceVariant;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(left: 12),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: iconColor,
        size: 36,
      ),
    );
  }

  Widget _buildSwipeBackground(ColorScheme colors, {required bool isLeft}) {
    final backgroundColor = isLeft ? Colors.red.shade100 : Colors.green.shade100;
    final iconColor = isLeft ? Colors.red : Colors.green;
    final icon = isLeft ? Symbols.cancel : Symbols.check_circle;
    final alignment = isLeft ? Alignment.centerLeft : Alignment.centerRight;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(
        icon,
        color: iconColor,
        size: 36,
      ),
    );
  }
}
