import 'package:flutter/material.dart';

class TimeSlot extends StatelessWidget {
  final String time;
  final bool isPast;

  const TimeSlot({super.key, required this.time, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Past dosages: grey, Upcoming: green
    final backgroundColor = isPast
        ? colors.surfaceContainerHighest
        : Colors.green;

    final textColor = isPast ? colors.onSurfaceVariant : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
