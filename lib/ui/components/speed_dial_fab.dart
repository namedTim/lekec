import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SpeedDialOption {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String heroTag;

  const SpeedDialOption({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.heroTag,
  });
}

class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({
    super.key,
    required this.options,
    this.mainIcon = Symbols.pill,
    this.tooltip = 'Dodaj',
  });

  final List<SpeedDialOption> options;
  final IconData mainIcon;
  final String tooltip;

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleOptionPressed(VoidCallback onPressed) {
    _toggleSpeedDial();
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speed dial options
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            if (!_isExpanded && _animation.value == 0) {
              return const SizedBox.shrink();
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.options.reversed.map((option) {
                return Transform.scale(
                  scale: _animation.value,
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: _animation.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                option.label,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FloatingActionButton(
                            heroTag: option.heroTag,
                            mini: true,
                            onPressed: () =>
                                _handleOptionPressed(option.onPressed),
                            child: Icon(option.icon),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        // Main FAB
        FloatingActionButton(
          heroTag: 'main_speed_dial_fab',
          onPressed: _toggleSpeedDial,
          tooltip: widget.tooltip,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              bottomLeft: Radius.circular(32),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(widget.mainIcon),
          ),
        ),
      ],
    );
  }
}
