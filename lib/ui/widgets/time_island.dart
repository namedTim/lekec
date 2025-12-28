import 'dart:async';
import 'package:flutter/material.dart';

class TimeIslandController {
  VoidCallback? _restart;

  void restart() => _restart?.call();
}

class TimeIsland extends StatefulWidget {
  const TimeIsland({
    super.key,
    required this.totalDuration,
    required this.remainingDuration,
    this.controller,
  });

  final Duration totalDuration;
  final Duration remainingDuration;
  final TimeIslandController? controller;

  @override
  State<TimeIsland> createState() => _TimeIslandState();
}

class _TimeIslandState extends State<TimeIsland> {
  late Duration _remaining;
  Timer? _timer;

  bool get _isFinished => _remaining.inSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remainingDuration;

    widget.controller?._restart = _restart;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant TimeIsland oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.remainingDuration != widget.remainingDuration) {
      _restart();
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (_remaining.inSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.inSeconds <= 0) {
          _timer?.cancel();
        }
      });
    });
  }

  void _restart() {
    setState(() {
      _remaining = widget.remainingDuration;
    });
    _startTimer();
  }

  double get _progress {
    if (_isFinished) return 1;
    return 1 -
        (_remaining.inSeconds / widget.totalDuration.inSeconds)
            .clamp(0, 1);
  }

  String get _timeText {
    if (_isFinished) return 'Vzemite zdravilo';

    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

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
          Text(
            _isFinished
                ? 'Čas za zdravilo'
                : 'Čas do naslednjega zdravila',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _timeText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _isFinished ? colors.primary : colors.onSurface,
            ),
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isFinished ? colors.primary : colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
