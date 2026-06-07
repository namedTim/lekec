import 'package:flutter/cupertino.dart' show CupertinoTimerPicker, CupertinoTimerPickerMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../features/core/providers/database_provider.dart';
import '../../data/services/appointment_service.dart';
import '../../database/drift_database.dart';
import '../../main.dart' show userDetailsPageKey;
import '../../ui/components/critical_reminder_recap.dart';

/// Screen for creating or editing an appointment.
///
/// Pass an [Appointment] via `existingAppointment` to edit; omit it to create.
class AddAppointmentScreen extends ConsumerStatefulWidget {
  final int userId;
  final Appointment? existingAppointment;

  const AddAppointmentScreen({
    super.key,
    required this.userId,
    this.existingAppointment,
  });

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _titleFocusNode = FocusNode();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _criticalReminder = false;
  bool _isSaving = false;

  /// Minutes before the appointment when the full-screen alarm should ring.
  int _reminderMinutesBefore = 120;

  bool get _isEditing => widget.existingAppointment != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final appt = widget.existingAppointment!;
      _titleController.text = appt.title;
      _noteController.text = appt.note ?? '';
      _criticalReminder = appt.criticalReminder;
      _reminderMinutesBefore = appt.reminderMinutesBefore;
      _selectedDate = DateTime(
        appt.appointmentTime.year,
        appt.appointmentTime.month,
        appt.appointmentTime.day,
      );
      _selectedTime = TimeOfDay(
        hour: appt.appointmentTime.hour,
        minute: appt.appointmentTime.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // Unfocus any text fields to prevent auto-focus after time picker
    _titleFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      // Automatically open time picker after date is selected
      await _pickTime();
    }
  }

  Future<void> _pickTime() async {
    // Unfocus any text fields to prevent auto-focus after picker closes
    _titleFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vnesite naslov termina')),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izberite datum in čas')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final appointmentTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      final db = ref.read(databaseProvider);
      final service = AppointmentService(db);
      final note = _noteController.text.trim();

      if (_isEditing) {
        await service.updateAppointment(
          id: widget.existingAppointment!.id,
          title: title,
          note: note.isEmpty ? null : note,
          appointmentTime: appointmentTime,
          criticalReminder: _criticalReminder,
          reminderMinutesBefore: _reminderMinutesBefore,
        );
      } else {
        await service.createAppointment(
          userId: widget.userId,
          title: title,
          note: note.isEmpty ? null : note,
          appointmentTime: appointmentTime,
          criticalReminder: _criticalReminder,
          reminderMinutesBefore: _reminderMinutesBefore,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Termin posodobljen' : 'Termin dodan'),
            backgroundColor: Colors.green,
          ),
        );
        // If the user details screen is alive in another tab branch
        // (e.g. user opened it, switched to dashboard, then added a termin
        // via the speed dial) refresh it so the appointment shows up without
        // an app restart. Harmless no-op when nothing is listening.
        userDetailsPageKey.currentState?.refresh();
        Navigator.of(context).pop(true); // return true to signal refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izbriši termin'),
        content: Text('Ali želite izbrisati termin "${widget.existingAppointment!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Prekliči'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Izbriši', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final database = ref.read(databaseProvider);
      final service = AppointmentService(database);
      await service.deleteAppointment(widget.existingAppointment!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Termin izbrisan'),
            backgroundColor: Colors.green,
          ),
        );
        userDetailsPageKey.currentState?.refresh();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Compact digit-style label, e.g. "2h", "1h 30min", "45min".
  String _offsetLabel() {
    final m = _reminderMinutesBefore;
    if (m <= 0) return 'ob terminu';
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '${min}min';
    if (min == 0) return '${h}h';
    return '${h}h ${min}min';
  }

  /// "DD.MM.YYYY ob HH:MM" — when the full-screen alarm will ring.
  /// Null until both date and time have been picked.
  String? _ringDateTimeStr() {
    if (_selectedDate == null || _selectedTime == null) return null;
    final appt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final ring = appt.subtract(Duration(minutes: _reminderMinutesBefore));
    final dd = ring.day.toString().padLeft(2, '0');
    final mm = ring.month.toString().padLeft(2, '0');
    final hh = ring.hour.toString().padLeft(2, '0');
    final mn = ring.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${ring.year} ob $hh:$mn';
  }

  /// Wheel duration picker (hours + minutes). Returns the chosen offset
  /// in minutes; null if the user cancels.
  Future<void> _pickOffset() async {
    _titleFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    int draft = _reminderMinutesBefore;

    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colors = theme.colorScheme;
        return SafeArea(
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Koliko prej naj zazvoni alarm',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(minutes: draft),
                    minuteInterval: 1,
                    onTimerDurationChanged: (d) => draft = d.inMinutes,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Prekliči'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(draft),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                          ),
                          child: const Text('Potrdi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected >= 0) {
      setState(() => _reminderMinutesBefore = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final dateStr = _selectedDate != null
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
        : 'Izberite datum';
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : 'Izberite čas';
    final ringStr = _ringDateTimeStr();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Uredi termin' : 'Nov termin'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _isSaving ? null : _delete,
              icon: Icon(Symbols.delete, color: colors.error),
              tooltip: 'Izbriši termin',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Naslov',
                hintText: 'npr. Pregled pri zdravniku',
                prefixIcon: const Icon(Symbols.event),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Note
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Opomba (neobvezno)',
                hintText: 'Dodatne podrobnosti …',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Symbols.sticky_note_2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date picker card
            _PickerCard(
              icon: Symbols.calendar_today,
              label: 'Datum',
              value: dateStr,
              onTap: _pickDate,
              colors: colors,
              theme: theme,
            ),
            const SizedBox(height: 12),

            // Time picker card
            _PickerCard(
              icon: Symbols.schedule,
              label: 'Ura',
              value: timeStr,
              onTap: _pickTime,
              colors: colors,
              theme: theme,
            ),
            const SizedBox(height: 16),

            // Critical Reminder
            CriticalReminderRecap(
              enabled: _criticalReminder,
              onChanged: (value) => setState(() => _criticalReminder = value),
            ),
            const SizedBox(height: 12),

            // Reminder offset picker
            _PickerCard(
              icon: Symbols.alarm,
              label: 'Alarm pred terminom',
              value: _offsetLabel(),
              onTap: _pickOffset,
              colors: colors,
              theme: theme,
            ),
            const SizedBox(height: 12),

            // Info box — shows when notifications will fire.
            _ReminderInfoBox(
              ringStr: ringStr,
              colors: colors,
              theme: theme,
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Symbols.check),
              label: Text(_isEditing ? 'Posodobi' : 'Shrani'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Delete button (only when editing)
            if (_isEditing) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _delete,
                icon: Icon(Symbols.delete, color: colors.error),
                label: Text(
                  'Izbriši termin',
                  style: TextStyle(color: colors.error),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final ColorScheme colors;
  final ThemeData theme;

  const _PickerCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Symbols.arrow_forward_ios,
                color: colors.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Info box that summarises the two reminder events.
/// Shows a placeholder with muted style when date/time aren't picked yet.
class _ReminderInfoBox extends StatelessWidget {
  const _ReminderInfoBox({
    required this.ringStr,
    required this.colors,
    required this.theme,
  });

  final String? ringStr;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hasData = ringStr != null;
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    final lineStyle = theme.textTheme.bodyMedium?.copyWith(
      color: hasData ? colors.onSurface : colors.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontStyle: hasData ? FontStyle.normal : FontStyle.italic,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.notifications_active, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OPOMNIKI', style: headerStyle),
                const SizedBox(height: 8),
                _line(
                  Symbols.schedule,
                  hasData
                      ? 'Tihi opomnik: 1 dan prej'
                      : 'Tihi opomnik 1 dan prej',
                  lineStyle,
                ),
                const SizedBox(height: 4),
                _line(
                  Symbols.alarm,
                  hasData
                      ? 'Alarm: $ringStr'
                      : 'Alarm — izberite datum in uro termina',
                  lineStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, TextStyle? style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
