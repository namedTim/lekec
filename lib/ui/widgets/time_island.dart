import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../database/tables/medications.dart';
import '../../helpers/medication_icon_helper.dart';

class TimeIslandController {
  VoidCallback? _update;

  void update() => _update?.call();
}

class TimeIsland extends StatefulWidget {
  const TimeIsland({
    super.key,
    this.medicationName,
    this.medType,
    required this.totalDuration,
    required this.remainingDuration,
    required this.isOverdue,
    this.controller,
    this.ownerName,
    this.greetingDuration = const Duration(seconds: 5),
  });

  final String? medicationName;
  final MedicationType? medType;
  final Duration totalDuration;
  final Duration remainingDuration;
  final bool isOverdue;
  final TimeIslandController? controller;
  final String? ownerName;
  final Duration greetingDuration;

  @override
  State<TimeIsland> createState() => _TimeIslandState();
}

class _TimeIslandState extends State<TimeIsland>
    with SingleTickerProviderStateMixin {
  late Duration _remaining;
  Timer? _timer;
  Timer? _greetingTimer;
  bool _showGreeting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  bool get _isFinished => widget.isOverdue || _remaining.inSeconds <= 0;
  bool get _hasMedication => widget.medicationName != null;
  bool get _isSoon =>
      _hasMedication &&
      !_isFinished &&
      _remaining.inMinutes < 30;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remainingDuration;
    _showGreeting = widget.ownerName != null && widget.ownerName!.isNotEmpty;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.controller?._update = _update;
    _startTimer();
    _scheduleGreetingDismiss();
    _syncPulse();
  }

  void _scheduleGreetingDismiss() {
    _greetingTimer?.cancel();
    if (!_showGreeting) return;
    _greetingTimer = Timer(widget.greetingDuration, () {
      if (!mounted) return;
      setState(() => _showGreeting = false);
      _syncPulse();
    });
  }

  @override
  void didUpdateWidget(covariant TimeIsland oldWidget) {
    super.didUpdateWidget(oldWidget);

    final ownerArrived = (oldWidget.ownerName == null ||
            oldWidget.ownerName!.isEmpty) &&
        (widget.ownerName != null && widget.ownerName!.isNotEmpty);
    if (ownerArrived) {
      setState(() => _showGreeting = true);
      _scheduleGreetingDismiss();
    }

    if (oldWidget.remainingDuration != widget.remainingDuration ||
        oldWidget.medicationName != widget.medicationName ||
        oldWidget.isOverdue != widget.isOverdue ||
        oldWidget.medType != widget.medType) {
      _update();
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (_remaining.inSeconds <= 0 && !widget.isOverdue) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (!widget.isOverdue) {
          _remaining -= const Duration(seconds: 1);
          if (_remaining.inSeconds <= 0) {
            _timer?.cancel();
          }
        }
      });
      _syncPulse();
    });
  }

  void _update() {
    setState(() {
      _remaining = widget.remainingDuration;
    });
    _startTimer();
    _syncPulse();
  }

  void _syncPulse() {
    if (_isFinished && _hasMedication) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }
  }

  double get _progress {
    if (_isFinished) return 1;
    if (widget.totalDuration.inSeconds == 0) return 0;
    return 1 -
        (_remaining.inSeconds / widget.totalDuration.inSeconds).clamp(0, 1);
  }

  String get _timeText {
    if (!_hasMedication) return '--';
    if (_isFinished) return 'zdaj';

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    if (days > 0) {
      if (hours > 0) return '$days d $hours h';
      return '$days d';
    }
    if (hours > 0) {
      if (minutes > 0) return '$hours h $minutes min';
      return '$hours h';
    }
    if (minutes > 0) return '$minutes min';
    return '${seconds}s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _greetingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  ({Color accent, IconData icon}) _resolveStyle(ColorScheme colors) {
    if (!_hasMedication) {
      return (accent: const Color(0xFF22C55E), icon: Symbols.check_circle);
    }
    if (_isFinished) {
      return (
        accent: const Color(0xFF22C55E),
        icon: Symbols.notifications_active,
      );
    }
    if (widget.medType != null) {
      final s = getMedicationStyle(widget.medType!);
      if (_isSoon) {
        return (accent: const Color(0xFFF59E0B), icon: s.icon);
      }
      return (accent: s.color, icon: s.icon);
    }
    if (_isSoon) {
      return (accent: const Color(0xFFF59E0B), icon: Symbols.schedule);
    }
    return (accent: colors.primary, icon: Symbols.schedule);
  }

  ({String text, Color accent, IconData icon}) _resolveGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return (
        text: 'Dobro jutro',
        accent: const Color(0xFFF59E0B),
        icon: Symbols.wb_sunny,
      );
    }
    if (hour >= 12 && hour < 18) {
      return (
        text: 'Dober dan',
        accent: const Color(0xFFEAB308),
        icon: Symbols.wb_sunny,
      );
    }
    if (hour >= 18 && hour < 22) {
      return (
        text: 'Dober večer',
        accent: const Color(0xFF8B5CF6),
        icon: Symbols.nights_stay,
      );
    }
    return (
      text: 'Dober večer',
      accent: const Color(0xFF6366F1),
      icon: Symbols.bedtime,
    );
  }

  String get _label {
    if (!_hasMedication) return 'Brez načrtovanih zdravil';
    if (_isFinished) return 'Vzemite zdravilo';
    if (_isSoon) return 'Kmalu';
    return 'Naslednje zdravilo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final showGreeting = _showGreeting && widget.ownerName != null;
    final medsStyle = _resolveStyle(colors);
    final greetingStyle = _resolveGreeting();
    final accent = showGreeting ? greetingStyle.accent : medsStyle.accent;
    final pulseEnabled = !showGreeting && _isFinished;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final pulseAlpha = pulseEnabled ? (0.18 + 0.18 * _pulse.value) : 0.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: pulseEnabled
                  ? accent.withOpacity(0.6)
                  : colors.outlineVariant.withOpacity(0.5),
              width: pulseEnabled ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: pulseEnabled
                    ? accent.withOpacity(pulseAlpha)
                    : Colors.black.withOpacity(0.06),
                blurRadius: pulseEnabled ? 18 : 8,
                spreadRadius: pulseEnabled ? 1 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: showGreeting
                  ? _buildGreeting(theme, greetingStyle)
                  : _buildMedsView(theme, colors, medsStyle),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(
    ThemeData theme,
    ({String text, Color accent, IconData icon}) g,
  ) {
    return Row(
      key: const ValueKey('greeting'),
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: g.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(g.icon, size: 26, color: g.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                g.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.ownerName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: g.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedsView(
    ThemeData theme,
    ColorScheme colors,
    ({Color accent, IconData icon}) style,
  ) {
    final accent = style.accent;
    final tileBg = accent.withOpacity(_isFinished ? 0.18 : 0.12);

    return Column(
      key: const ValueKey('meds'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(style.icon, size: 26, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _hasMedication
                        ? widget.medicationName!
                        : 'Vse opravljeno',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _isFinished ? accent : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (_hasMedication) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _timeText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_hasMedication) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 5,
              backgroundColor: accent.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ],
    );
  }
}
