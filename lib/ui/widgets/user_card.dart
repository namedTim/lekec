import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/user_color_helper.dart';

class UserCard extends StatelessWidget {
  final String userName;
  final int? userAge;
  final int? userId;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.userName,
    this.userAge,
    this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    final accent = getUserColor(userId: userId, name: userName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (userAge != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$userAge let',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Symbols.chevron_right,
                color: colors.onSurfaceVariant.withOpacity(0.6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
