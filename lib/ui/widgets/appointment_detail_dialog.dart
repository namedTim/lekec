import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppointmentDetailDialog extends StatelessWidget {
  final String title;
  final DateTime appointmentTime;
  final String? note;
  final String userName;
  final VoidCallback onDelete;

  const AppointmentDetailDialog({
    super.key,
    required this.title,
    required this.appointmentTime,
    required this.userName,
    this.note,
    required this.onDelete,
  });

  String _timeStr() =>
      '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';

  String _dateStr() =>
      '${appointmentTime.day.toString().padLeft(2, '0')}.${appointmentTime.month.toString().padLeft(2, '0')}.${appointmentTime.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const accent = Color(0xFF3B82F6);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Symbols.calendar_month,
                    color: accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Termin',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Zapri',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildRow(context, Symbols.calendar_today, 'Datum', _dateStr()),
                const SizedBox(height: 16),
                _buildRow(context, Symbols.schedule, 'Čas', _timeStr()),
                const SizedBox(height: 16),
                _buildRow(context, Symbols.person, 'Uporabnik', userName),
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildRow(
                    context,
                    Symbols.info,
                    'Opomba',
                    note!.length > 60 ? '${note!.substring(0, 60)}…' : note!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Symbols.close, size: 18),
                    label: const Text('Zapri'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      side: BorderSide(
                        color: colors.outlineVariant,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Symbols.delete, size: 18),
                    label: const Text('Izbriši termin'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
