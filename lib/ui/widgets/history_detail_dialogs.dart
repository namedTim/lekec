import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/drift_database.dart';
import '../../data/services/mood_service.dart';
import '../../helpers/medication_icon_helper.dart';
import '../../helpers/medication_unit_helper.dart';
import '../../helpers/user_color_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

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

Widget _buildNoteRow(BuildContext context, IconData icon, String label,
    String value) {
  final colors = Theme.of(context).colorScheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: colors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildUserRow(BuildContext context, int userId, String name) {
  final accent = getUserColor(userId: userId, name: name);
  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
  final colors = Theme.of(context).colorScheme;
  return Row(
    children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        'Uporabnik:',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
          textAlign: TextAlign.end,
        ),
      ),
    ],
  );
}

Widget _buildIconTile({
  required IconData icon,
  required Color accent,
  double size = 48,
  double iconSize = 28,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: accent, size: iconSize),
  );
}

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _formatDateTime(DateTime dt) {
  const months = [
    '', 'jan', 'feb', 'mar', 'apr', 'maj', 'jun',
    'jul', 'avg', 'sep', 'okt', 'nov', 'dec',
  ];
  return '${dt.day}. ${months[dt.month]} ${dt.year}  ${_formatTime(dt)}';
}

Widget _buildHeader({
  required BuildContext context,
  required Widget iconWidget,
  required String title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Medication intake detail dialog
// ─────────────────────────────────────────────────────────────────────────────

class HistoryIntakeDetailDialog extends StatelessWidget {
  final MedicationIntakeLog intake;
  final Medication medication;
  final MedicationPlan? plan;
  final String? userName;

  const HistoryIntakeDetailDialog({
    super.key,
    required this.intake,
    required this.medication,
    this.plan,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final dosageAmount = intake.dosageAmount ?? plan?.dosageAmount ?? 1.0;
    final dosageCount = dosageAmount.toInt();
    final dosageStr =
        '$dosageCount ${getMedicationUnit(medication.medType, dosageCount)}';
    final wasTaken = intake.wasTaken;
    final medStyle = getMedicationStyle(medication.medType);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            context: context,
            iconWidget: _buildIconTile(
              icon: medStyle.icon,
              accent: medStyle.color,
            ),
            title: medication.name,
            subtitle: dosageStr,
          ),

          // Status badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: wasTaken
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        wasTaken ? Symbols.check_circle : Symbols.cancel,
                        size: 16,
                        color: wasTaken
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        wasTaken ? 'Vzeto' : 'Izpuščeno',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: wasTaken
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildRow(context, Symbols.schedule, 'Čas',
                    _formatTime(intake.scheduledTime)),
                if (intake.takenTime != null) ...[
                  const SizedBox(height: 14),
                  _buildRow(context, Symbols.done_all, 'Vzeto ob',
                      _formatTime(intake.takenTime!)),
                ],
                const SizedBox(height: 14),
                _buildRow(context, Symbols.science, 'Odmerek', dosageStr),
                if (userName != null) ...[
                  const SizedBox(height: 14),
                  _buildUserRow(context, intake.userId, userName!),
                ],
                if (medication.intakeAdvice != null &&
                    medication.intakeAdvice!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildNoteRow(context, Symbols.info, 'Navodilo',
                      medication.intakeAdvice!),
                ],
                if (medication.notes != null &&
                    medication.notes!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildNoteRow(
                      context, Symbols.edit_note, 'Opomba', medication.notes!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Appointment detail dialog
// ─────────────────────────────────────────────────────────────────────────────

class HistoryAppointmentDetailDialog extends StatelessWidget {
  final Appointment appointment;
  final String? userName;

  const HistoryAppointmentDetailDialog({
    super.key,
    required this.appointment,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            context: context,
            iconWidget: _buildIconTile(
              icon: Symbols.calendar_month,
              accent: const Color(0xFF22C55E),
            ),
            title: appointment.title,
            subtitle: _formatDateTime(appointment.appointmentTime),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildRow(context, Symbols.schedule, 'Datum in čas',
                    _formatDateTime(appointment.appointmentTime)),
                if (userName != null) ...[
                  const SizedBox(height: 14),
                  _buildUserRow(context, appointment.userId, userName!),
                ],
                if (appointment.note != null &&
                    appointment.note!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildNoteRow(context, Symbols.edit_note, 'Opomba',
                      appointment.note!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Mood detail dialog
// ─────────────────────────────────────────────────────────────────────────────

class HistoryMoodDetailDialog extends StatelessWidget {
  final MoodEntry mood;
  final String? userName;

  const HistoryMoodDetailDialog({
    super.key,
    required this.mood,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final emoji = MoodService.moodEmojis[mood.moodLevel] ?? '😐';
    final label = MoodService.moodLabels[mood.moodLevel] ?? '';

    const moodAccent = Color(0xFF8B5CF6);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            context: context,
            iconWidget: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: moodAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            title: label,
            subtitle: _formatDateTime(mood.createdAt),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildRow(context, Symbols.schedule, 'Čas',
                    _formatTime(mood.createdAt)),
                // Mood level bar
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Symbols.mood, size: 20, color: moodAccent),
                    const SizedBox(width: 10),
                    Text(
                      'Nivo:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(5, (i) {
                          final level = i + 1;
                          return Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: level <= mood.moodLevel
                                    ? moodAccent
                                    : colors.surfaceContainerHighest,
                                border: Border.all(
                                  color: colors.outlineVariant,
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                if (userName != null) ...[
                  const SizedBox(height: 14),
                  _buildUserRow(context, mood.userId, userName!),
                ],
                if (mood.note != null && mood.note!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildNoteRow(
                      context, Symbols.edit_note, 'Opomba', mood.note!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
