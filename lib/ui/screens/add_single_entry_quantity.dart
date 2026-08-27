import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import '../../features/core/providers/database_provider.dart';
import '../../helpers/medication_unit_helper.dart';
import '../../main.dart' show homePageKey;
import '../../data/services/medication_service.dart';
import '../../data/services/intake_log_service.dart';
import '../../data/services/notification_service.dart';
import '../components/critical_reminder_recap.dart';

class AddSingleEntryQuantityScreen extends ConsumerStatefulWidget {
  final String medicationName;
  final MedicationType medType;
  final int userId;

  const AddSingleEntryQuantityScreen({
    super.key,
    required this.medicationName,
    required this.medType,
    required this.userId,
  });

  @override
  ConsumerState<AddSingleEntryQuantityScreen> createState() =>
      _AddSingleEntryQuantityScreenState();
}

class _AddSingleEntryQuantityScreenState
    extends ConsumerState<AddSingleEntryQuantityScreen> {
  int _quantity = 1;
  final _textController = TextEditingController(text: '1');
  final _focusNode = FocusNode();

  /// false = log the intake as taken now (original behaviour);
  /// true = schedule a one-time reminder for a chosen time instead.
  bool _reminderMode = false;
  DateTime _reminderDate = DateTime.now();
  TimeOfDay _reminderTime = TimeOfDay.now();

  /// Within reminder mode: true = critical full-screen alarm, false = plain
  /// notification.
  bool _critical = true;
  bool _isSaving = false;

  DateTime get _reminderDateTime => DateTime(
        _reminderDate.year,
        _reminderDate.month,
        _reminderDate.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final value = int.tryParse(_textController.text);
      if (value != null && value >= 1 && value <= 9999) {
        setState(() => _quantity = value);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    if (_quantity < 999999) {
      setState(() {
        _quantity++;
        _textController.text = _quantity.toString();
      });
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _textController.text = _quantity.toString();
      });
    }
  }

  Future<void> _selectReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _reminderDate = date);
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) {
      setState(() => _reminderTime = time);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    // Reminder mode requires a time in the future.
    if (_reminderMode && !_reminderDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izberite čas v prihodnosti')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final db = ref.read(databaseProvider);
    final medicationService = MedicationService(db);
    final intakeLogService = IntakeLogService(db);

    try {
      // Each one-time entry creates its own medication row (plain insert, not
      // dedup), so setting criticalReminder here is safe and per-entry.
      final medicationId = await medicationService.createMedication(
        MedicationsCompanion(
          name: drift.Value(widget.medicationName),
          medType: drift.Value(widget.medType),
          criticalReminder: drift.Value(_reminderMode && _critical),
        ),
      );

      if (_reminderMode) {
        // Schedule a one-time future reminder instead of logging now.
        await intakeLogService.createOneTimeReminder(
          medicationId: medicationId,
          userId: widget.userId,
          dosageAmount: _quantity.toDouble(),
          scheduledTime: _reminderDateTime,
        );
        // (Re)schedule notifications/alarms; honours medication.criticalReminder.
        await NotificationService().scheduleAllUpcomingNotifications(db);
      } else {
        // Original behaviour: record the intake as taken right now.
        await intakeLogService.createOneTimeEntry(
          medicationId: medicationId,
          userId: widget.userId,
          dosageAmount: _quantity.toDouble(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _reminderMode
                  ? 'Opomnik nastavljen za ${_reminderDate.day}.${_reminderDate.month}. ob ${_reminderTime.format(context)}'
                  : 'Vnos zabeležen: $_quantity ${getMedicationUnitShort(widget.medType, _quantity.toInt())}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh home page
        homePageKey.currentState?.loadTodaysIntakes();

        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              const SizedBox(height: 16),
              Text(
                widget.medicationName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vnesite število ${getMedicationUnitShort(widget.medType, 5)} za vnos',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Quantity selector
              Center(
                child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 28,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Decrement button
                    Container(
                      decoration: BoxDecoration(
                        color: _quantity > 1
                            ? colors.primary
                            : colors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _quantity > 1 ? _decrement : null,
                        icon: const Icon(Symbols.remove),
                        color: _quantity > 1
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                        iconSize: 22,
                      ),
                    ),
                    const SizedBox(width: 28),

                    // Editable number
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed < 1) {
                            _textController.text = '1';
                          } else if (parsed > 9999) {
                            _textController.text = '9999';
                          }
                          _focusNode.unfocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 28),

                    // Increment button
                    Container(
                      decoration: BoxDecoration(
                        color: _quantity < 9999
                            ? colors.primary
                            : colors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _quantity < 9999 ? _increment : null,
                        icon: const Icon(Symbols.add),
                        color: _quantity < 9999
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                        iconSize: 22,
                      ),
                    ),
                  ],
                ),
                ),
              ),

              const SizedBox(height: 24),

              // Mode: log now vs schedule a one-time reminder.
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Zabeleži zdaj'),
                    icon: Icon(Symbols.check),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Opomni me'),
                    icon: Icon(Symbols.notifications),
                  ),
                ],
                selected: {_reminderMode},
                onSelectionChanged: (sel) =>
                    setState(() => _reminderMode = sel.first),
              ),

              if (_reminderMode) ...[
                const SizedBox(height: 16),
                _PickerCard(
                  icon: Symbols.calendar_today,
                  label: 'Datum',
                  value:
                      '${_reminderDate.day}.${_reminderDate.month}.${_reminderDate.year}',
                  onTap: _selectReminderDate,
                ),
                const SizedBox(height: 12),
                _PickerCard(
                  icon: Symbols.schedule,
                  label: 'Čas',
                  value: _reminderTime.format(context),
                  onTap: _selectReminderTime,
                ),
                const SizedBox(height: 16),
                CriticalReminderRecap(
                  enabled: _critical,
                  onChanged: (v) => setState(() => _critical = v),
                ),
              ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: _isSaving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Shrani',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable card showing a label + current value, used for the reminder
/// date/time pickers. Mirrors the planning-screen card styling.
class _PickerCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
