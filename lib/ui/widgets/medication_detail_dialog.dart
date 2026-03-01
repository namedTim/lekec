import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class MedicationDetailDialog extends StatelessWidget {
  final String medName;
  final String dosage;
  final DateTime scheduledTime;
  final double dosageAmount;
  final int? pillsRemaining;
  final String userName;
  final String? intakeAdvice;
  /// Called when user taps "Sem vzel". If null the action row is hidden.
  final VoidCallback? onTake;
  /// Called when user taps "Nisem vzel".
  final VoidCallback? onNotTake;

  const MedicationDetailDialog({
    super.key,
    required this.medName,
    required this.dosage,
    required this.scheduledTime,
    required this.dosageAmount,
    required this.pillsRemaining,
    required this.userName,
    this.intakeAdvice,
    this.onTake,
    this.onNotTake,
  });

  String _timeStr() =>
      '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasActions = onTake != null || onNotTake != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header with icon, name, and close button ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Symbols.medication,
                      color: colors.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dosage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // X close button — same line on the right
                IconButton(
                  icon: const Icon(Symbols.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Zapri',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Detail rows ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildRow(context, Symbols.schedule, 'Čas', _timeStr()),
                const SizedBox(height: 16),
                _buildRow(context, Symbols.science, 'Odmerek', dosage),
                if (pillsRemaining != null) ...[
                  const SizedBox(height: 16),
                  _buildRow(context, Symbols.inventory_2,
                      'Preostalo po odmeru', '$pillsRemaining'),
                ],
                const SizedBox(height: 16),
                _buildRow(context, Symbols.person, 'Uporabnik', userName),
                if (intakeAdvice != null && intakeAdvice!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildRow(
                    context,
                    Symbols.info,
                    'Opomba',
                    intakeAdvice!.length > 60
                        ? '${intakeAdvice!.substring(0, 60)}…'
                        : intakeAdvice!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Action buttons ──────────────────────────────────────────────
          if (hasActions) ...[
            // Take / Don't-take row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Ne vzamem — left
                  if (onNotTake != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNotTake,
                        icon: const Icon(Symbols.close, size: 18),
                        label: const Text('Nisem vzel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                          side: BorderSide(color: colors.error.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  if (onNotTake != null && onTake != null)
                    const SizedBox(width: 12),
                  // Vzamem — right (primary, filled)
                  if (onTake != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onTake,
                        icon: const Icon(Symbols.check, size: 18),
                        label: const Text('Sem vzel'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
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
          ] else
            const SizedBox(height: 16),
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
