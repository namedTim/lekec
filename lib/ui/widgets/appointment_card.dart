import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A compact appointment card used in the daily timeline view on the dashboard.
/// Visually distinct from medication cards with a calendar icon.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.title,
    this.note,
    required this.appointmentTime,
    this.userName,
    this.showName = false,
    this.isPast = false,
    this.isActive = false,
    this.onTap,
    this.onDelete,
  });

  final String title;
  final String? note;
  final DateTime appointmentTime;
  final String? userName;
  final bool showName;
  final bool isPast;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(
                  color: const Color(0xFF22C55E),
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
            // Calendar icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isPast
                      ? colors.outlineVariant
                      : const Color(0xFF22C55E),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Symbols.calendar_month,
                color: isPast
                    ? colors.onSurfaceVariant
                    : const Color(0xFF22C55E),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPast ? colors.onSurfaceVariant : null,
                    ),
                  ),

                  // Note chip + user name
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (note != null && note!.isNotEmpty)
                              ? (note!.length > 20
                                  ? '${note!.substring(0, 20)}…'
                                  : note!)
                              : 'Ni opombe',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (showName && userName != null) ...[
                        const Spacer(),
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
                              userName!,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A detailed appointment card used in the Termini tab on the meds screen.
/// Shows more info like full date, time, note, and has swipe-to-delete.
class AppointmentDetailsCard extends StatelessWidget {
  const AppointmentDetailsCard({
    super.key,
    required this.title,
    this.note,
    required this.appointmentTime,
    this.userName,
    this.showName = false,
    this.onTap,
    this.onDelete,
  });

  final String title;
  final String? note;
  final DateTime appointmentTime;
  final String? userName;
  final bool showName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  String _formatDate(DateTime dt) {
    const dayNames = [
      'ponedeljek',
      'torek',
      'sreda',
      'četrtek',
      'petek',
      'sobota',
      'nedelja',
    ];
    final dayName = dayNames[dt.weekday - 1];
    return '$dayName, ${dt.day}. ${dt.month}. ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _timeUntilText() {
    final now = DateTime.now();
    final diff = appointmentTime.difference(now);
    if (diff.isNegative) return 'Preteklo';
    if (diff.inDays > 0) {
      return 'čez ${diff.inDays} ${diff.inDays == 1 ? 'dan' : diff.inDays == 2 ? 'dneva' : diff.inDays <= 4 ? 'dni' : 'dni'}';
    }
    if (diff.inHours > 0) {
      return 'čez ${diff.inHours} ${diff.inHours == 1 ? 'uro' : diff.inHours == 2 ? 'uri' : diff.inHours <= 4 ? 'ure' : 'ur'}';
    }
    return 'čez ${diff.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPast = appointmentTime.isBefore(DateTime.now());

    return Dismissible(
      key: Key('appointment_${title}_${appointmentTime.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Izbriši',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Symbols.delete, color: colors.error, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Calendar badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isPast
                        ? colors.outlineVariant
                        : const Color(0xFF22C55E),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appointmentTime.day.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isPast
                            ? colors.onSurfaceVariant
                            : const Color(0xFF22C55E),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      _formatTime(appointmentTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isPast
                            ? colors.onSurfaceVariant
                            : const Color(0xFF22C55E),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPast ? colors.onSurfaceVariant : null,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Date line
                    Row(
                      children: [
                        Icon(
                          Symbols.schedule,
                          size: 14,
                          color: isPast
                              ? colors.onSurfaceVariant
                              : colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(appointmentTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Note
                    if (note != null && note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Time-until chip + user name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPast
                                ? colors.surfaceContainerHighest
                                : colors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _timeUntilText(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPast
                                  ? colors.onSurfaceVariant
                                  : colors.primary,
                            ),
                          ),
                        ),
                        if (showName && userName != null) ...[
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Symbols.person,
                                size: 14,
                                color: colors.primary,
                              ),
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
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Symbols.chevron_right,
                color: colors.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
