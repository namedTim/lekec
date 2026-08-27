import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// How a medication plan should stop being scheduled.
///
/// - [StopMode.never]: the plan has no end date (keeps generating indefinitely).
/// - [StopMode.afterDays]: stop after taking it for [days] calendar days
///   (counted inclusively from the plan's start date).
/// - [StopMode.onDate]: stop after a specific last day ([date]).
enum StopMode { never, afterDays, onDate }

class StopCondition {
  final StopMode mode;

  /// Number of days for [StopMode.afterDays]. Null otherwise.
  final int? days;

  /// Last intake day for [StopMode.onDate]. Only the date part matters.
  final DateTime? date;

  const StopCondition.never() : mode = StopMode.never, days = null, date = null;

  const StopCondition.afterDays(this.days)
    : mode = StopMode.afterDays,
      date = null;

  const StopCondition.onDate(this.date) : mode = StopMode.onDate, days = null;
}

/// Resolves the concrete end date (inclusive) to persist on a plan, given the
/// chosen [condition] and the plan's [startDate].
///
/// The intake schedule generator treats the plan end date as exclusive at the
/// instant level (it keeps doses whose time `isBefore(end)`), so we anchor the
/// end at 23:59:59 of the last intake day. That makes the final day inclusive
/// for any time-of-day.
DateTime? resolveEndDate(StopCondition condition, DateTime startDate) {
  switch (condition.mode) {
    case StopMode.never:
      return null;
    case StopMode.afterDays:
      final n = condition.days;
      if (n == null || n <= 0) return null;
      // N calendar days inclusive of the start day => last day is start + (N-1).
      final lastDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: n - 1));
      return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
    case StopMode.onDate:
      final d = condition.date;
      if (d == null) return null;
      return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }
}

/// Human-readable summary of [condition] for the card value, relative to
/// [startDate] (used to show the resolved last day for the "after N days" mode).
String stopConditionLabel(StopCondition condition, DateTime startDate) {
  switch (condition.mode) {
    case StopMode.never:
      return 'Brez konca';
    case StopMode.afterDays:
      final n = condition.days ?? 0;
      final end = resolveEndDate(condition, startDate);
      final endStr = end != null ? ' (do ${_fmtDate(end)})' : '';
      return 'Po $n dneh$endStr';
    case StopMode.onDate:
      final d = condition.date;
      return d != null ? 'Do ${_fmtDate(d)}' : 'Izberite datum';
  }
}

String _fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

/// A tappable card (matching the planning screens' card style) that lets the
/// user pick when a medication plan should stop. Drop it into any planning
/// flow; it owns its picker UI and reports the chosen [StopCondition] via
/// [onChanged].
class StopDateCard extends StatelessWidget {
  final StopCondition condition;

  /// The plan's start date, used to resolve and display "after N days".
  final DateTime startDate;
  final ValueChanged<StopCondition> onChanged;

  const StopDateCard({
    super.key,
    required this.condition,
    required this.startDate,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showStopConditionSheet(
      context,
      initial: condition,
      startDate: startDate,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: () => _open(context),
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
            Icon(Symbols.event_busy, color: colors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konec jemanja',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stopConditionLabel(condition, startDate),
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

/// Shows the modal picker and returns the chosen [StopCondition], or null if
/// the user dismissed it without confirming.
Future<StopCondition?> showStopConditionSheet(
  BuildContext context, {
  required StopCondition initial,
  required DateTime startDate,
}) {
  return showModalBottomSheet<StopCondition>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) =>
        _StopConditionSheet(initial: initial, startDate: startDate),
  );
}

class _StopConditionSheet extends StatefulWidget {
  final StopCondition initial;
  final DateTime startDate;

  const _StopConditionSheet({required this.initial, required this.startDate});

  @override
  State<_StopConditionSheet> createState() => _StopConditionSheetState();
}

class _StopConditionSheetState extends State<_StopConditionSheet> {
  late StopMode _mode;
  late int _days;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _mode = widget.initial.mode;
    _days = widget.initial.days ?? 10;
    _date = widget.initial.date;
  }

  Future<void> _pickDate() async {
    final firstDate = DateTime(
      widget.startDate.year,
      widget.startDate.month,
      widget.startDate.day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? firstDate.add(const Duration(days: 10)),
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  StopCondition _build() {
    switch (_mode) {
      case StopMode.never:
        return const StopCondition.never();
      case StopMode.afterDays:
        return StopCondition.afterDays(_days);
      case StopMode.onDate:
        return StopCondition.onDate(_date);
    }
  }

  bool get _canConfirm {
    if (_mode == StopMode.onDate && _date == null) return false;
    if (_mode == StopMode.afterDays && _days <= 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Konec jemanja',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          RadioListTile<StopMode>(
            value: StopMode.never,
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
            contentPadding: EdgeInsets.zero,
            title: const Text('Brez konca'),
            subtitle: const Text('Opomniki tečejo, dokler zdravila ne ustavite'),
          ),
          RadioListTile<StopMode>(
            value: StopMode.afterDays,
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
            contentPadding: EdgeInsets.zero,
            title: const Text('Po številu dni'),
          ),
          if (_mode == StopMode.afterDays)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _days > 1
                        ? () => setState(() => _days--)
                        : null,
                    icon: const Icon(Symbols.remove),
                  ),
                  Expanded(
                    child: Text(
                      '$_days dni',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _days < 3650
                        ? () => setState(() => _days++)
                        : null,
                    icon: const Icon(Symbols.add),
                  ),
                ],
              ),
            ),
          RadioListTile<StopMode>(
            value: StopMode.onDate,
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
            contentPadding: EdgeInsets.zero,
            title: const Text('Do določenega datuma'),
          ),
          if (_mode == StopMode.onDate)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Symbols.calendar_today, size: 18),
                  label: Text(
                    _date != null ? _fmtDate(_date!) : 'Izberite datum',
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canConfirm
                ? () => Navigator.of(context).pop(_build())
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Potrdi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
