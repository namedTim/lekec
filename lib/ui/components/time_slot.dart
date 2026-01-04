import 'package:flutter/material.dart';

class TimeSlot extends StatelessWidget {
  final String time;

  const TimeSlot({
    super.key,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
