import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Collapsible 7-day date picker that lives at the top of the dashboard.
///
/// Renders a button showing the currently selected day. Tapping the button
/// expands a horizontally-paged week strip; each page is one Monday→Sunday
/// week and the user can swipe between weeks or tap a day to select it.
/// Forward navigation is capped at one month past today.
class WeekStrip extends StatefulWidget {
  const WeekStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.activeDateKeys = const <String>{},
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Keys (yyyy-MM-dd) of days that have at least one intake or appointment.
  /// A small dot is drawn on those day cells.
  final Set<String> activeDateKeys;

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip>
    with SingleTickerProviderStateMixin {
  static const _weekdayLabels = ['P', 'T', 'S', 'Č', 'P', 'S', 'N'];
  static const _monthNames = [
    'Januar',
    'Februar',
    'Marec',
    'April',
    'Maj',
    'Junij',
    'Julij',
    'Avgust',
    'September',
    'Oktober',
    'November',
    'December',
  ];

  // Pick a reference Monday far enough in the past so the page index can
  // grow without ever going negative; ~10 years of weeks is plenty.
  static const int _epochYearsBack = 10;

  late final DateTime _epochMonday;
  late PageController _pageController;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _epochMonday = _mondayOf(
      DateTime(today.year - _epochYearsBack, today.month, today.day),
    );
    _pageController = PageController(
      initialPage: _weekIndexFor(widget.selectedDate),
    );
  }

  @override
  void didUpdateWidget(covariant WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final target = _weekIndexFor(widget.selectedDate);
      if (_pageController.hasClients &&
          _pageController.page?.round() != target) {
        _pageController.jumpToPage(target);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _mondayOf(DateTime d) {
    final day = _dateOnly(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _weekIndexFor(DateTime date) {
    final monday = _mondayOf(date);
    return monday.difference(_epochMonday).inDays ~/ 7;
  }

  DateTime get _today => _dateOnly(DateTime.now());
  DateTime get _maxSelectableDate {
    final t = _today;
    return DateTime(t.year, t.month + 1, t.day);
  }

  int get _maxWeekIndex => _weekIndexFor(_maxSelectableDate);

  String _formatSelectedLabel() {
    final d = widget.selectedDate;
    if (_isSameDay(d, _today)) return 'Danes';
    if (_isSameDay(d, _today.subtract(const Duration(days: 1)))) return 'Včeraj';
    if (_isSameDay(d, _today.add(const Duration(days: 1)))) return 'Jutri';
    return '${d.day}. ${_monthNames[d.month - 1]} ${d.year}';
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToggleButton(theme, colors),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildWeekPager(theme, colors),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildToggleButton(ThemeData theme, ColorScheme colors) {
    final isToday = _isSameDay(widget.selectedDate, _today);
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                Symbols.calendar_today,
                size: 20,
                color: colors.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatSelectedLabel(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isToday)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _GoToTodayButton(onPressed: _goToToday),
                ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Symbols.expand_more,
                  size: 22,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToToday() {
    final today = _today;
    if (_isSameDay(widget.selectedDate, today)) return;
    widget.onDateSelected(today);
  }

  Widget _buildWeekPager(ThemeData theme, ColorScheme colors) {
    return SizedBox(
      height: 76,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _maxWeekIndex + 1,
        itemBuilder: (context, weekIndex) {
          final mondayOfWeek =
              _epochMonday.add(Duration(days: weekIndex * 7));
          return _WeekPage(
            mondayOfWeek: mondayOfWeek,
            selectedDate: widget.selectedDate,
            today: _today,
            maxSelectable: _maxSelectableDate,
            weekdayLabels: _weekdayLabels,
            activeDateKeys: widget.activeDateKeys,
            onDayTap: (date) => widget.onDateSelected(date),
          );
        },
      ),
    );
  }
}

class _WeekPage extends StatelessWidget {
  const _WeekPage({
    required this.mondayOfWeek,
    required this.selectedDate,
    required this.today,
    required this.maxSelectable,
    required this.weekdayLabels,
    required this.activeDateKeys,
    required this.onDayTap,
  });

  final DateTime mondayOfWeek;
  final DateTime selectedDate;
  final DateTime today;
  final DateTime maxSelectable;
  final List<String> weekdayLabels;
  final Set<String> activeDateKeys;
  final ValueChanged<DateTime> onDayTap;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _keyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final date = mondayOfWeek.add(Duration(days: i));
        final isSelected = _isSameDay(date, selectedDate);
        final isToday = _isSameDay(date, today);
        final isLocked = date.isAfter(maxSelectable);
        final hasActivity = activeDateKeys.contains(_keyFor(date));
        return Expanded(
          child: _DayCell(
            date: date,
            weekdayLabel: weekdayLabels[i],
            isSelected: isSelected,
            isToday: isToday,
            isLocked: isLocked,
            hasActivity: hasActivity,
            onTap: isLocked ? null : () => onDayTap(date),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.weekdayLabel,
    required this.isSelected,
    required this.isToday,
    required this.isLocked,
    required this.hasActivity,
    required this.onTap,
  });

  final DateTime date;
  final String weekdayLabel;
  final bool isSelected;
  final bool isToday;
  final bool isLocked;
  final bool hasActivity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Color bg;
    Color labelColor;
    Color dayColor;
    BoxBorder? border;
    if (isSelected) {
      bg = colors.primary;
      labelColor = colors.onPrimary.withValues(alpha: 0.85);
      dayColor = colors.onPrimary;
      border = null;
    } else if (isToday) {
      bg = colors.primaryContainer;
      labelColor = colors.onPrimaryContainer.withValues(alpha: 0.8);
      dayColor = colors.onPrimaryContainer;
      border = Border.all(color: colors.primary, width: 1.5);
    } else {
      bg = colors.surfaceContainerHighest;
      labelColor = colors.onSurfaceVariant;
      dayColor = colors.onSurface;
      border = null;
    }
    if (isLocked) {
      bg = colors.surfaceContainerHighest.withValues(alpha: 0.4);
      labelColor = colors.onSurfaceVariant.withValues(alpha: 0.35);
      dayColor = colors.onSurface.withValues(alpha: 0.35);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: border,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdayLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: dayColor,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 5,
                  width: 5,
                  child: hasActivity && !isLocked
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? colors.onPrimary
                                : (isToday
                                    ? colors.onPrimaryContainer
                                    : colors.primary),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoToTodayButton extends StatelessWidget {
  const _GoToTodayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.primary, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.today, size: 14, color: colors.primary),
              const SizedBox(width: 4),
              Text(
                'Danes',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
