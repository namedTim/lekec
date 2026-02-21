import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../database/drift_database.dart';
import '../../database/tables/medications.dart';
import '../../helpers/medication_unit_helper.dart';
import '../components/confirmation_dialog.dart';
import '../../main.dart' show db, homePageKey;
import '../../data/services/notification_service.dart';
import '../../data/services/intake_log_service.dart';
import '../../data/services/intake_schedule_generator.dart';
import '../components/log_intake_sheet.dart';
import '../components/quantity_selector.dart';

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
  final bool isAsNeeded;
  final int? planId;
  final int? userId;

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
    this.isAsNeeded = false,
    this.planId,
    this.userId,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  late bool _criticalReminder;
  late int _pillsRemaining;
  late double _dosageAmount;
  late List<String> _times;
  late String? _intakeAdvice;

  @override
  void initState() {
    super.initState();
    _criticalReminder = widget.criticalReminder;
    _pillsRemaining = widget.pillsRemaining;
    _dosageAmount = widget.dosageAmount;
    _times = List.from(widget.times);
    _intakeAdvice = widget.intakeAdvice;
  }

  Future<void> _editInventory() async {
    final quantity = await showQuantitySelector(
      context,
      initialValue: 0,
      minValue: -_pillsRemaining.toDouble(),
      maxValue: 9999,
      step: 1,
      label: 'Dodaj/odstrani zalogo',
    );
    if (quantity != null && quantity != 0 && mounted) {
      try {
        final newRemaining = (_pillsRemaining + quantity.toInt()).clamp(0, 99999);
        await (db.update(
          db.medications,
        )..where((t) => t.id.equals(widget.medicationId))).write(
          MedicationsCompanion(
            dosagesRemaining: drift.Value(newRemaining.toDouble()),
          ),
        );

        setState(() {
          _pillsRemaining = newRemaining;
        });

        widget.onRefresh();

        if (mounted) {
          final absQuantity = quantity.abs().toInt();
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                quantity >= 0
                    ? 'Dodal ${quantity.toInt()} ${getMedicationUnitShort(widget.medType, quantity.toInt())}'
                    : 'Odstranil $absQuantity ${getMedicationUnitShort(widget.medType, absQuantity)}',
              ),
              backgroundColor: quantity >= 0 ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _editDosage() async {
    final quantity = await showQuantitySelector(
      context,
      initialValue: _dosageAmount,
      minValue: 0.5,
      maxValue: 99,
      label: 'Odmerek (${getMedicationUnitShort(widget.medType, 2)})',
    );
    if (quantity != null && mounted) {
      try {
        // Update dosageAmount in the plan
        if (widget.planId != null) {
          await (db.update(
            db.medicationPlans,
          )..where((t) => t.id.equals(widget.planId!))).write(
            MedicationPlansCompanion(
              dosageAmount: drift.Value(quantity),
            ),
          );
        }

        setState(() {
          _dosageAmount = quantity;
        });

        widget.onRefresh();

        if (mounted) {
          final displayQty = quantity == quantity.roundToDouble() ? quantity.toInt().toString() : quantity.toString();
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Odmerek posodobljen na $displayQty ${getMedicationUnitShort(widget.medType, quantity.ceil())}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _editTime(int index) async {
    final currentTime = _parseTime(_times[index]);
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    if (picked != null && mounted) {
      await _updateTimes(() {
        _times[index] = _formatTime(picked);
      });
    }
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      await _updateTimes(() {
        _times.add(_formatTime(picked));
        _times.sort();
      });
    }
  }

  Future<void> _deleteTime(int index) async {
    if (_times.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mora biti vsaj en čas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await _updateTimes(() {
      _times.removeAt(index);
    });
  }

  Future<void> _updateTimes(VoidCallback modifier) async {
    try {
      modifier();

      // Update timesOfDay in the schedule rule
      if (widget.planId != null) {
        await (db.update(
          db.medicationScheduleRules,
        )..where((t) => t.planId.equals(widget.planId!))).write(
          MedicationScheduleRulesCompanion(
            timesOfDay: drift.Value(jsonEncode(_times)),
          ),
        );

        // Regenerate intake schedule and notifications
        final scheduleGenerator = IntakeScheduleGenerator(db);
        await scheduleGenerator.regeneratePlanSchedule(widget.planId!);

        final notificationService = NotificationService();
        await notificationService.scheduleAllUpcomingNotifications(db);

        homePageKey.currentState?.loadTodaysIntakes(autoScroll: false);
      }

      setState(() {});
      widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Časi posodobljeni'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editIntakeAdvice() async {
    final controller = TextEditingController(text: _intakeAdvice ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Priporočilo pred zaužitjem'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'npr. Vzemi z jedjo, Na prazen želodec...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Prekliči'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Shrani'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      try {
        final advice = result.isEmpty ? null : result;
        await (db.update(db.medications)
              ..where((t) => t.id.equals(widget.medicationId)))
            .write(MedicationsCompanion(intakeAdvice: drift.Value(advice)));

        setState(() {
          _intakeAdvice = advice;
        });

        widget.onRefresh();

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Priporočilo posodobljeno'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Napaka: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showLogIntakeSheet() async {
    final result = await showLogIntakeSheet(
      context: context,
      medicationName: widget.medicationName,
      medType: widget.medType,
      defaultQuantity: widget.dosageAmount.toInt(),
    );

    if (result != null && mounted) {
      final time = result['time'] as TimeOfDay;
      final qty = result['quantity'] as int;
      final now = DateTime.now();
      final takenTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      try {
        final intakeService = IntakeLogService(db);
        await intakeService.logAsNeededIntake(
          planId: widget.planId!,
          medicationId: widget.medicationId,
          userId: widget.userId!,
          dosageAmount: qty.toDouble(),
          takenTime: takenTime,
        );

        setState(() {
          _pillsRemaining = (_pillsRemaining - qty).clamp(0, 99999);
        });

        widget.onRefresh();
        homePageKey.currentState?.loadTodaysIntakes(autoScroll: false);

        if (mounted) {
          final colors = Theme.of(context).colorScheme;
          final timeStr =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ $qty ${getMedicationUnitShort(widget.medType, qty)} ob $timeStr',
                style: TextStyle(color: colors.onSurface),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: colors.surfaceContainerHighest,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Napaka: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
    final dosageCount = _dosageAmount.toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Podrobnosti zdravila'),
        centerTitle: true,
        actions: [
          IconButton(
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
            icon: Icon(Symbols.delete, color: colors.error),
            tooltip: 'Izbriši zdravilo',
          ),
          const SizedBox(width: 4),
        ],
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
                _EditableDetailCard(
                  icon: Symbols.info,
                  title: 'Priporočilo pred zaužitjem',
                  onTap: _editIntakeAdvice,
                  child: Text(
                    _intakeAdvice?.isEmpty ?? true
                        ? 'Ni podatka'
                        : _intakeAdvice!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: _intakeAdvice?.isEmpty ?? true
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: _intakeAdvice?.isEmpty ?? true
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
                _EditableDetailCard(
                  icon: Symbols.inventory_2,
                  title: 'Zaloga',
                  onTap: _editInventory,
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
                            'še $_pillsRemaining ${getMedicationUnitShort(widget.medType, _pillsRemaining)}',
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
                _EditableDetailCard(
                  icon: Symbols.science,
                  title: 'Odmerek',
                  onTap: widget.planId != null ? _editDosage : null,
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
                      if (_times.isNotEmpty && !widget.isAsNeeded) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._times.asMap().entries.map((entry) {
                              final index = entry.key;
                              final time = entry.value;
                              return GestureDetector(
                                onTap: () => _editTime(index),
                                onLongPress: () => _deleteTime(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        time,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  colors.onSecondaryContainer,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Symbols.edit,
                                        size: 14,
                                        color: colors.onSecondaryContainer
                                            .withOpacity(0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            // Add time button
                            GestureDetector(
                              onTap: _addTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Symbols.add,
                                      size: 16,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Dodaj',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: colors.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tapni za urejanje, dolg pritisk za brisanje',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.isAsNeeded &&
              widget.planId != null &&
              widget.userId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: _showLogIntakeSheet,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Symbols.add_circle),
                label: const Text('Zabeleži vnos'),
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

class _EditableDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onTap;

  const _EditableDetailCard({
    required this.icon,
    required this.title,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Symbols.edit,
                      size: 18,
                      color: colors.onSurfaceVariant.withOpacity(0.5),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
