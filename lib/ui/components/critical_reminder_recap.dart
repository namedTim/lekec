import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A recap card shown at the last step of adding a medication,
/// allowing the user to enable critical reminders (full-screen alarm).
class CriticalReminderRecap extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const CriticalReminderRecap({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: enabled
            ? colors.errorContainer.withOpacity(0.3)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? colors.error.withOpacity(0.5)
              : colors.outlineVariant.withOpacity(0.5),
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.alarm,
                color: enabled ? colors.error : colors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kritični opomniki',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            enabled
                ? 'Telefon bo glasno zvonil in vibriral na celotnem zaslonu ob vsakem opomniku za to zdravilo – tudi če je telefon utišan.'
                : 'Omogočite, da bo telefon glasno zvonil in vibriral na celotnem zaslonu ob vsakem opomniku – tudi če je telefon utišan.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Symbols.settings,
                size: 16,
                color: colors.onSurfaceVariant.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Melodijo in vibracijo lahko spremenite v nastavitvah.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
