import 'package:flutter/material.dart';

/// Semantic accent for a speed-dial action. Each resolves to a circular-button
/// colour pair tuned separately for light and dark mode (light = soft tint +
/// dark icon, dark = deep tint + light icon), so every action has its own
/// colour while the panel and labels stay neutral.
enum SpeedDialAccent { meds, entry, mood, water, appointment }

class _AccentColors {
  final Color bg;
  final Color fg;
  const _AccentColors(this.bg, this.fg);
}

const Map<SpeedDialAccent, _AccentColors> _lightAccents = {
  SpeedDialAccent.meds: _AccentColors(Color(0xFFCDEFCF), Color(0xFF135C2A)),
  SpeedDialAccent.entry: _AccentColors(Color(0xFFBFF1E4), Color(0xFF00513F)),
  SpeedDialAccent.mood: _AccentColors(Color(0xFFFFE6A8), Color(0xFF6F4E00)),
  SpeedDialAccent.water: _AccentColors(Color(0xFFC7E6FF), Color(0xFF0A4B76)),
  SpeedDialAccent.appointment: _AccentColors(
    Color(0xFFF4D7FF),
    Color(0xFF6A1B7A),
  ),
};

const Map<SpeedDialAccent, _AccentColors> _darkAccents = {
  SpeedDialAccent.meds: _AccentColors(Color(0xFF135C2A), Color(0xFFB4E9B9)),
  SpeedDialAccent.entry: _AccentColors(Color(0xFF00513F), Color(0xFFA2E8D5)),
  SpeedDialAccent.mood: _AccentColors(Color(0xFF5E4200), Color(0xFFFFD978)),
  SpeedDialAccent.water: _AccentColors(Color(0xFF0E486F), Color(0xFFBBE0FF)),
  SpeedDialAccent.appointment: _AccentColors(
    Color(0xFF57206A),
    Color(0xFFF0CBFF),
  ),
};

/// A single expandable speed-dial entry: a neutral label next to a circular
/// icon button coloured by its [accent], readable against the [SpeedDialPanel]
/// background in both themes.
class SpeedDialItem extends StatelessWidget {
  const SpeedDialItem({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final SpeedDialAccent accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final c = (isDark ? _darkAccents : _lightAccents)[accent]!;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.fg, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// The expandable panel that hosts the speed-dial [items] above the main FAB.
/// Gives the whole cluster a single rounded background ("the area") that scales
/// and fades in from the FAB corner, driven by the parent's [animation].
class SpeedDialPanel extends StatelessWidget {
  const SpeedDialPanel({
    super.key,
    required this.animation,
    required this.items,
  });

  /// The parent's expand animation (0 = collapsed, 1 = fully open).
  final Animation<double> animation;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Transform.scale(
      scale: animation.value,
      alignment: Alignment.bottomRight,
      child: Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items,
          ),
        ),
      ),
    );
  }
}
