import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../database/tables/medications.dart' as db;

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
    required this.medType,
    this.status = MedicationStatus.upcoming,
    this.onStatusChanged,
    this.isOneTimeEntry = false,
    this.onDelete,
    this.enableLeftSwipe = true,
    this.enableRightSwipe = true,
    this.isNextMedication = false,
    this.onTap,
  });

  final String medName;
  final String dosage;
  final String medicineRemaining;
  final int pillCount;
  final bool showName;
  final String username;
  final String userId;
  final db.MedicationType medType;
  final MedicationStatus status;
  final Function(MedicationStatus)? onStatusChanged;
  final bool isOneTimeEntry;
  final VoidCallback? onDelete;
  final bool enableLeftSwipe;
  final bool enableRightSwipe;
  final bool isNextMedication;
  final VoidCallback? onTap;

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

({IconData icon, Color color}) _medicationStyle(db.MedicationType type) {
  switch (type) {
    case db.MedicationType.pills:
      return (icon: Symbols.pill, color: const Color(0xFF6366F1));
    case db.MedicationType.capsules:
      return (icon: Symbols.medication, color: const Color(0xFF8B5CF6));
    case db.MedicationType.drops:
      return (icon: Symbols.water_drop, color: const Color(0xFF06B6D4));
    case db.MedicationType.milliliters:
      return (icon: Symbols.medication_liquid, color: const Color(0xFF0EA5E9));
    case db.MedicationType.sprays:
      return (icon: Symbols.airwave, color: const Color(0xFF14B8A6));
    case db.MedicationType.injections:
      return (icon: Symbols.vaccines, color: const Color(0xFFEC4899));
    case db.MedicationType.patches:
      return (icon: Symbols.healing, color: const Color(0xFFF59E0B));
    case db.MedicationType.puffs:
      return (icon: Symbols.pulmonology, color: const Color(0xFF38BDF8));
    case db.MedicationType.applications:
      return (icon: Symbols.healing, color: const Color(0xFFF97316));
    case db.MedicationType.ampules:
      return (icon: Symbols.science, color: const Color(0xFFA855F7));
    case db.MedicationType.grams:
    case db.MedicationType.milligrams:
    case db.MedicationType.micrograms:
      return (icon: Symbols.scale, color: const Color(0xFF64748B));
    case db.MedicationType.tablespoons:
      return (icon: Symbols.restaurant, color: const Color(0xFFEAB308));
    case db.MedicationType.portions:
      return (icon: Symbols.restaurant_menu, color: const Color(0xFFD97706));
    case db.MedicationType.pieces:
      return (icon: Symbols.category, color: const Color(0xFF10B981));
    case db.MedicationType.units:
      return (icon: Symbols.inventory_2, color: const Color(0xFF22C55E));
  }
}

class _MedicationCardState extends State<MedicationCard> {
  DismissDirection _getDismissDirection() {
    if (widget.enableLeftSwipe && widget.enableRightSwipe) {
      return DismissDirection.horizontal;
    } else if (widget.enableLeftSwipe) {
      return DismissDirection.startToEnd;
    } else if (widget.enableRightSwipe) {
      return DismissDirection.endToStart;
    } else {
      return DismissDirection.none;
    }
  }

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
      key: ValueKey('${widget.medName}_${widget.userId}_${widget.status.name}'),
      direction: _getDismissDirection(),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      resizeDuration: null,
      background: widget.enableLeftSwipe
          ? _buildSwipeBackground(colors, isLeft: true)
          : null,
      secondaryBackground: widget.enableRightSwipe
          ? _buildSwipeBackground(colors, isLeft: false)
          : null,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart &&
            widget.enableRightSwipe) {
          // Swipe from right - mark as taken
          widget.onStatusChanged?.call(MedicationStatus.taken);
        } else if (direction == DismissDirection.startToEnd &&
            widget.enableLeftSwipe) {
          // Swipe from left - delete one-time entry or mark as not taken
          if (widget.isOneTimeEntry) {
            widget.onDelete?.call();
          } else {
            widget.onStatusChanged?.call(MedicationStatus.notTaken);
          }
        }
        return false; // Don't actually dismiss the card
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: widget.isNextMedication
                ? Border.all(
                    color: const Color(0xFF22C55E), // Green color
                    width: 3,
                  )
                : Border.all(
                    color: colors.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTypeIcon(),
              const SizedBox(width: 14),
              // Left content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Medicine name and dosage in same row
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.medName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.dosage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // Remaining pills / info chip
                    if (widget.medicineRemaining.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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

                    // Username row
                    if (widget.showName) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.person,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.username,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status indicator icon
              _buildStatusIcon(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    final style = _medicationStyle(widget.medType);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(style.icon, size: 26, color: style.color),
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

    return GestureDetector(
      onTap: () {
        // Toggle between taken and not taken
        if (widget.status == MedicationStatus.taken) {
          widget.onStatusChanged?.call(MedicationStatus.notTaken);
        } else if (widget.status == MedicationStatus.notTaken ||
            widget.status == MedicationStatus.upcoming) {
          widget.onStatusChanged?.call(MedicationStatus.taken);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 36),
      ),
    );
  }

  Widget _buildSwipeBackground(ColorScheme colors, {required bool isLeft}) {
    final backgroundColor = isLeft
        ? Colors.red.shade100
        : Colors.green.shade100;
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
      child: Icon(icon, color: iconColor, size: 36),
    );
  }
}
