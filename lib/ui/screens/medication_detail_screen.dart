import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import '../../helpers/medication_unit_helper.dart';
import '../components/confirmation_dialog.dart';
import '../../main.dart' show db;
import '../../data/services/notification_service.dart';

class MedicationDetailScreen extends StatefulWidget {
  final int medicationId;
  final String medicationName;
  final MedicationType medType;
  final int pillsRemaining;
  final double dosageAmount;
  final String frequency;
  final List<String> times;
  final String? intakeAdvice;
  final bool criticalReminder;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const MedicationDetailScreen({
    super.key,
    required this.medicationId,
    required this.medicationName,
    required this.medType,
    required this.pillsRemaining,
    required this.dosageAmount,
    required this.frequency,
    required this.times,
    this.intakeAdvice,
    required this.criticalReminder,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  late bool _criticalReminder;

  @override
  void initState() {
    super.initState();
    _criticalReminder = widget.criticalReminder;
  }

  Future<void> _toggleCriticalReminder(bool value) async {
    try {
      await (db.update(db.medications)
            ..where((t) => t.id.equals(widget.medicationId)))
          .write(MedicationsCompanion(criticalReminder: drift.Value(value)));

      setState(() {
        _criticalReminder = value;
      });

      // Reschedule notifications to apply the new alarm/notification type
      final notificationService = NotificationService();
      await notificationService.scheduleAllUpcomingNotifications(db);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Kritični opomniki so omogočeni'
                  : 'Kritični opomniki so onemogočeni',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dosageCount = widget.dosageAmount.toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Podrobnosti zdravila'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Name Card
                _DetailCard(
                  icon: Symbols.medication,
                  title: 'Ime zdravila',
                  child: Text(
                    widget.medicationName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Intake Advice Card
                _DetailCard(
                  icon: Symbols.info,
                  title: 'Priporočilo pred zaužitjem',
                  child: Text(
                    widget.intakeAdvice?.isEmpty ?? true
                        ? 'Ni podatka'
                        : widget.intakeAdvice!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: widget.intakeAdvice?.isEmpty ?? true
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: widget.intakeAdvice?.isEmpty ?? true
                          ? colors.onSurfaceVariant.withOpacity(0.6)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Critical Reminder Card
                _DetailCard(
                  icon: Symbols.alarm,
                  title: 'Kritični opomniki',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Uporabi alarm',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Telefon bo glasno zvonil in vibriral na ves zaslon',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _criticalReminder,
                            onChanged: _toggleCriticalReminder,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stock/Supply Card
                _DetailCard(
                  icon: Symbols.inventory_2,
                  title: 'Zaloga',
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.pill,
                            size: 20,
                            color: colors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'še ${widget.pillsRemaining} ${getMedicationUnitShort(widget.medType, widget.pillsRemaining)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Dosage Card
                _DetailCard(
                  icon: Symbols.science,
                  title: 'Odmerek',
                  child: Text(
                    '$dosageCount ${getMedicationUnit(widget.medType, dosageCount)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reminders/Schedule Card
                _DetailCard(
                  icon: Symbols.schedule,
                  title: 'Opomniki',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.frequency,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.times.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.times.map((time) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                time,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colors.onSecondaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => ConfirmationDialog(
                    title: 'Izbriši zdravilo?',
                    message:
                        'Ali ste prepričani, da želite izbrisati zdravilo "${widget.medicationName}"?',
                    confirmText: 'Izbriši',
                    cancelText: 'Prekliči',
                  ),
                );
                if (confirmed == true && context.mounted) {
                  widget.onDelete();
                  Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Symbols.delete),
              label: const Text('Izbriši zdravilo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
