import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/services/water_service.dart';

/// Bottom sheet for logging a water intake.
///
/// Returns `{ 'amountMl': int }` on confirm, or `null` if dismissed.
/// Shape mirrors `mood_logging_sheet.dart` so the two log flows feel the
/// same to the user.
Future<Map<String, dynamic>?> showWaterLoggingSheet({
  required BuildContext context,
  int defaultAmountMl = 250,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _WaterLoggingSheet(defaultAmountMl: defaultAmountMl),
  );
}

class _WaterLoggingSheet extends StatefulWidget {
  final int defaultAmountMl;

  const _WaterLoggingSheet({required this.defaultAmountMl});

  @override
  State<_WaterLoggingSheet> createState() => _WaterLoggingSheetState();
}

class _WaterLoggingSheetState extends State<_WaterLoggingSheet> {
  late int _amountMl;

  static const _waterBlue = Color(0xFF38BDF8);

  @override
  void initState() {
    super.initState();
    _amountMl = widget.defaultAmountMl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Zabeleži hidracijo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Izberite količino popite vode',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // ── Quick-add preset chips ─────────────────────────────────────
          Row(
            children: [
              for (final preset in WaterService.quickAddPresetsMl) ...[
                Expanded(child: _presetChip(preset, theme, colors)),
                if (preset != WaterService.quickAddPresetsMl.last)
                  const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // ── Custom amount slider ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: _waterBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _waterBlue.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Symbols.water_drop, color: _waterBlue, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Količina',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_amountMl ml',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _waterBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _waterBlue,
                    thumbColor: _waterBlue,
                    inactiveTrackColor: _waterBlue.withOpacity(0.2),
                    overlayColor: _waterBlue.withOpacity(0.15),
                  ),
                  child: Slider(
                    min: 50,
                    max: 1000,
                    divisions: 19, // 50 ml steps
                    value: _amountMl.clamp(50, 1000).toDouble(),
                    onChanged: (v) => setState(() => _amountMl = v.round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Confirm ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop({'amountMl': _amountMl}),
              icon: const Icon(Symbols.check),
              label: Text('Dodaj $_amountMl ml'),
              style: FilledButton.styleFrom(
                backgroundColor: _waterBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(int ml, ThemeData theme, ColorScheme colors) {
    final isSelected = _amountMl == ml;
    final label = ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)} l' : '$ml ml';
    // Tier shortcut hints — kozarec / vrč / plastenka, matching the
    // everyday vessels users measure their water with.
    final hint = ml <= 200
        ? 'kozarec'
        : ml <= 350
            ? 'vrč'
            : 'plastenka';

    return GestureDetector(
      onTap: () => setState(() => _amountMl = ml),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _waterBlue.withOpacity(0.15)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _waterBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Symbols.water_drop,
              color: isSelected ? _waterBlue : colors.onSurfaceVariant,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? _waterBlue : null,
              ),
            ),
            Text(
              hint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
