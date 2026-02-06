import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class MedicationDetailDialog extends StatelessWidget {
  final String medName;
  final String dosage;
  final DateTime scheduledTime;
  final double dosageAmount;
  final int? pillsRemaining;
  final String userName;

  const MedicationDetailDialog({
    super.key,
    required this.medName,
    required this.dosage,
    required this.scheduledTime,
    required this.dosageAmount,
    required this.pillsRemaining,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.medication, color: colors.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  medName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildDetailRow(
            context: context,
            icon: Symbols.schedule,
            label: 'Čas',
            value: '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            context: context,
            icon: Symbols.science,
            label: 'Odmerek',
            value: dosage,
          ),
          if (pillsRemaining != null) ...[
            const SizedBox(height: 24),
            _buildDetailRow(
              context: context,
              icon: Symbols.inventory_2,
              label: 'Preostalo po odmeru',
              value: '$pillsRemaining',
            ),
          ],
          const SizedBox(height: 24),
          _buildDetailRow(
            context: context,
            icon: Symbols.person,
            label: 'Uporabnik',
            value: userName,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zapri'),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colors.primary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
