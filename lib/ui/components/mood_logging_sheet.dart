import 'package:flutter/material.dart';
import '../../data/services/mood_service.dart';

/// Shows a bottom sheet for logging mood.
/// Returns the selected mood level (1-5), or null if cancelled.
Future<Map<String, dynamic>?> showMoodLoggingSheet({
  required BuildContext context,
  int? existingMoodLevel,
}) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        _MoodLoggingSheet(existingMoodLevel: existingMoodLevel),
  );
}

class _MoodLoggingSheet extends StatefulWidget {
  final int? existingMoodLevel;

  const _MoodLoggingSheet({this.existingMoodLevel});

  @override
  State<_MoodLoggingSheet> createState() => _MoodLoggingSheetState();
}

class _MoodLoggingSheetState extends State<_MoodLoggingSheet> {
  int? _selectedMood;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.existingMoodLevel;
  }

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
            'Kako se počutite?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Izberite razpoloženje za danes',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Mood emoji selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final moodLevel = index + 1;
              final isSelected = _selectedMood == moodLevel;

              return GestureDetector(
                onTap: () => setState(() => _selectedMood = moodLevel),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: colors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        MoodService.moodEmojis[moodLevel]!,
                        style: TextStyle(fontSize: isSelected ? 32 : 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MoodService.moodLabels[moodLevel]!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? colors.primary
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
            }),
          ),
          const SizedBox(height: 20),

          // Optional note
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Opomba (neobvezno)',
              hintText: 'Kako se počutite...',
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

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedMood != null
                  ? () {
                      Navigator.of(context).pop({
                        'moodLevel': _selectedMood,
                        'note': _noteController.text.isEmpty
                            ? null
                            : _noteController.text,
                      });
                    }
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Potrdi'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
