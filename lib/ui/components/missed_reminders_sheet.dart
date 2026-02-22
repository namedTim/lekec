import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../data/services/missed_reminder_service.dart';
import '../../helpers/medication_unit_helper.dart';

/// A bottom sheet that displays missed critical medication reminders
/// and upcoming/missed appointment reminders so the user can act on them.
class MissedRemindersSheet extends StatefulWidget {
  final List<MissedMedicationReminder> missedMedications;
  final List<MissedAppointmentReminder> missedAppointments;
  final Future<void> Function(int intakeId) onMarkTaken;
  final Future<void> Function(int intakeId) onDismiss;
  final VoidCallback? onAllHandled;

  const MissedRemindersSheet({
    super.key,
    required this.missedMedications,
    required this.missedAppointments,
    required this.onMarkTaken,
    required this.onDismiss,
    this.onAllHandled,
  });

  @override
  State<MissedRemindersSheet> createState() => _MissedRemindersSheetState();
}

class _MissedRemindersSheetState extends State<MissedRemindersSheet> {
  late List<MissedMedicationReminder> _remainingMeds;
  late List<MissedAppointmentReminder> _remainingAppts;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _remainingMeds = List.from(widget.missedMedications);
    _remainingAppts = List.from(widget.missedAppointments);
  }

  String _formatOverdue(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final mins = duration.inMinutes % 60;
      if (mins > 0) {
        return 'Pred ${hours}h ${mins}min';
      }
      return 'Pred ${hours}h';
    }
    return 'Pred ${duration.inMinutes} min';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _checkIfAllHandled() {
    if (_remainingMeds.isEmpty && _remainingAppts.isEmpty) {
      Navigator.of(context).pop();
      widget.onAllHandled?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final totalItems = _remainingMeds.length + _remainingAppts.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Warning icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Symbols.notification_important,
                  color: colors.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zamujeni opomniki',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$totalItems ${_pluralizeReminders(totalItems)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.outlineVariant),
          const SizedBox(height: 8),
          // List of missed reminders
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // Missed medications
                ..._remainingMeds.map((reminder) {
                  final dosageCount = reminder.plan.dosageAmount.toInt();
                  final dosageText =
                      '$dosageCount ${getMedicationUnit(reminder.medication.medType, dosageCount)}';
                  final isProcessing =
                      _processingIds.contains(reminder.intake.id);

                  return _MissedMedicationTile(
                    medicationName: reminder.medication.name,
                    dosage: dosageText,
                    scheduledTime: _formatTime(reminder.intake.scheduledTime),
                    overdueText: _formatOverdue(reminder.overdueBy),
                    isProcessing: isProcessing,
                    onTaken: () async {
                      setState(() => _processingIds.add(reminder.intake.id));
                      await widget.onMarkTaken(reminder.intake.id);
                      if (mounted) {
                        setState(() {
                          _remainingMeds.remove(reminder);
                          _processingIds.remove(reminder.intake.id);
                        });
                        _checkIfAllHandled();
                      }
                    },
                    onDismiss: () async {
                      setState(() => _processingIds.add(reminder.intake.id));
                      await widget.onDismiss(reminder.intake.id);
                      if (mounted) {
                        setState(() {
                          _remainingMeds.remove(reminder);
                          _processingIds.remove(reminder.intake.id);
                        });
                        _checkIfAllHandled();
                      }
                    },
                  );
                }),
                // Missed/upcoming appointments
                ..._remainingAppts.map((reminder) {
                  return _MissedAppointmentTile(
                    title: reminder.appointment.title,
                    time: _formatTime(reminder.appointment.appointmentTime),
                    isUpcoming: reminder.isUpcoming,
                    note: reminder.appointment.note,
                    onAcknowledge: () {
                      setState(() {
                        _remainingAppts.remove(reminder);
                      });
                      _checkIfAllHandled();
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Dismiss all button
          if (totalItems > 1)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  // Dismiss all medications
                  for (final med in List.from(_remainingMeds)) {
                    await widget.onDismiss(med.intake.id);
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                    widget.onAllHandled?.call();
                  }
                },
                child: const Text('Opusti vse'),
              ),
            ),
        ],
      ),
    );
  }

  String _pluralizeReminders(int count) {
    if (count == 1) return 'zamujeni opomnik';
    if (count == 2) return 'zamujena opomnika';
    if (count == 3 || count == 4) return 'zamujeni opomniki';
    return 'zamujenih opomnikov';
  }
}

class _MissedMedicationTile extends StatelessWidget {
  final String medicationName;
  final String dosage;
  final String scheduledTime;
  final String overdueText;
  final bool isProcessing;
  final VoidCallback onTaken;
  final VoidCallback onDismiss;

  const _MissedMedicationTile({
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    required this.overdueText,
    required this.isProcessing,
    required this.onTaken,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: colors.errorContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.pill, color: colors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    medicationName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    overdueText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                '$dosage · Ob $scheduledTime',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isProcessing ? null : onDismiss,
                  child: Text(
                    'Opusti',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: isProcessing ? null : onTaken,
                  icon: isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Icon(Symbols.check, size: 18),
                  label: const Text('Sem vzel/a'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissedAppointmentTile extends StatelessWidget {
  final String title;
  final String time;
  final bool isUpcoming;
  final String? note;
  final VoidCallback onAcknowledge;

  const _MissedAppointmentTile({
    required this.title,
    required this.time,
    required this.isUpcoming,
    this.note,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: colors.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.calendar_today, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isUpcoming ? 'Kmalu' : 'Zamujeno',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                'Ob $time${note != null ? ' · $note' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonal(
                  onPressed: onAcknowledge,
                  child: const Text('Razumem'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the missed reminders bottom sheet.
/// Returns true if any reminders were shown.
Future<bool> showMissedRemindersSheet({
  required BuildContext context,
  required List<MissedMedicationReminder> missedMedications,
  required List<MissedAppointmentReminder> missedAppointments,
  required Future<void> Function(int intakeId) onMarkTaken,
  required Future<void> Function(int intakeId) onDismiss,
  VoidCallback? onAllHandled,
}) async {
  if (missedMedications.isEmpty && missedAppointments.isEmpty) {
    return false;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => MissedRemindersSheet(
      missedMedications: missedMedications,
      missedAppointments: missedAppointments,
      onMarkTaken: onMarkTaken,
      onDismiss: onDismiss,
      onAllHandled: onAllHandled,
    ),
  );

  return true;
}
