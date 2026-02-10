import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../data/services/period_service.dart';

/// Shows a bottom sheet for logging period data.
/// Returns a map with 'action' ('start'|'end'), 'flowIntensity' (int?), 'note' (String?), or null if cancelled.
Future<Map<String, dynamic>?> showPeriodLoggingSheet({
  required BuildContext context,
  required bool hasActivePeriod,
}) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _PeriodLoggingSheet(hasActivePeriod: hasActivePeriod),
  );
}

class _PeriodLoggingSheet extends StatefulWidget {
  final bool hasActivePeriod;

  const _PeriodLoggingSheet({required this.hasActivePeriod});

  @override
  State<_PeriodLoggingSheet> createState() => _PeriodLoggingSheetState();
}

class _PeriodLoggingSheetState extends State<_PeriodLoggingSheet> {
  int _flowIntensity = 2;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
          // Handle
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
            widget.hasActivePeriod
                ? 'Menstruacija – v teku'
                : 'Zabeleži menstruacijo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.hasActivePeriod
                ? 'Označite konec ali dodajte opombo'
                : 'Označite začetek menstruacije',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          if (!widget.hasActivePeriod) ...[
            // Flow intensity selector (only for start)
            Text(
              'Intenzivnost',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3].map((level) {
                final isSelected = _flowIntensity == level;
                return GestureDetector(
                  onTap: () => setState(() => _flowIntensity = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.errorContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: colors.error, width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          PeriodService.flowIcons[level]!,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PeriodService.flowLabels[level]!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? colors.error
                                : colors.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Optional note
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Opomba (neobvezno)',
              hintText: widget.hasActivePeriod
                  ? 'Simptomi, počutje...'
                  : 'Opombe...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          // Action buttons
          if (widget.hasActivePeriod) ...[
            // End period button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop({
                    'action': 'end',
                    'note': _noteController.text.isEmpty
                        ? null
                        : _noteController.text,
                  });
                },
                icon: const Icon(Symbols.stop_circle),
                label: const Text('Končaj menstruacijo'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ] else ...[
            // Start period button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop({
                    'action': 'start',
                    'flowIntensity': _flowIntensity,
                    'note': _noteController.text.isEmpty
                        ? null
                        : _noteController.text,
                  });
                },
                icon: const Icon(Symbols.play_circle),
                label: const Text('Začni menstruacijo'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
