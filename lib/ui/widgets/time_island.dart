import 'dart:async';
import 'package:flutter/material.dart';

class TimeIslandController {
  VoidCallback? _update;

  void update() => _update?.call();
}

class TimeIsland extends StatefulWidget {
  const TimeIsland({
    super.key,
    this.medicationName,
    required this.totalDuration,
    required this.remainingDuration,
    required this.isOverdue,
    this.controller,
  });

  final String? medicationName;
  final Duration totalDuration;
  final Duration remainingDuration;
  final bool isOverdue;
  final TimeIslandController? controller;

  @override
  State<TimeIsland> createState() => _TimeIslandState();
}

class _TimeIslandState extends State<TimeIsland> {
  late Duration _remaining;
  Timer? _timer;

  bool get _isFinished => widget.isOverdue || _remaining.inSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remainingDuration;

    widget.controller?._update = _update;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant TimeIsland oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.remainingDuration != widget.remainingDuration ||
        oldWidget.medicationName != widget.medicationName ||
        oldWidget.isOverdue != widget.isOverdue) {
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
    });
  }

  void _update() {
    setState(() {
      _remaining = widget.remainingDuration;
    });
    _startTimer();
  }

  double get _progress {
    if (_isFinished) return 1;
    return 1 -
        (_remaining.inSeconds / widget.totalDuration.inSeconds).clamp(0, 1);
  }

  String get _timeText {
    if (widget.medicationName == null) return '--';
    if (_isFinished) return 'Vzemite zdravilo';

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    if (days > 0) {
      if (hours > 0) {
        return '$days d $hours h';
      }
      return '$days d';
    }

    if (hours > 0) {
      if (minutes > 0) {
        return '$hours h $minutes min';
      }
      return '$hours h';
    }

    if (minutes > 0) {
      return '$minutes min';
    }

    return '${seconds}s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show label first
          Text(
            _isFinished ? 'Vzemite zdravilo' : 'Naslednje zdravilo',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: _isFinished ? colors.primary : null,
            ),
          ),

          const SizedBox(height: 6),

          // Show medication name or time
          Text(
            _isFinished ? (widget.medicationName ?? '--') : _timeText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _isFinished ? colors.primary : colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
