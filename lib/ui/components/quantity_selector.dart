import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class QuantitySelector extends StatefulWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final String label;

  const QuantitySelector({
    super.key,
    this.initialValue = 1,
    this.minValue = 1,
    this.maxValue = 99,
    this.label = 'Količina',
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _increment() {
    if (_value < widget.maxValue) {
      setState(() => _value++);
    }
  }

  void _decrement() {
    if (_value > widget.minValue) {
      setState(() => _value--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge,
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _value > widget.minValue ? _decrement : null,
              icon: const Icon(Symbols.remove),
              style: IconButton.styleFrom(
                backgroundColor: colors.surfaceContainerHighest,
                disabledBackgroundColor: colors.surfaceContainerHighest
                    .withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 24),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text(
                _value.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              onPressed: _value < widget.maxValue ? _increment : null,
              icon: const Icon(Symbols.add),
              style: IconButton.styleFrom(
                backgroundColor: colors.surfaceContainerHighest,
                disabledBackgroundColor: colors.surfaceContainerHighest
                    .withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Prekliči'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('V redu'),
        ),
      ],
    );
  }
}

Future<int?> showQuantitySelector(
  BuildContext context, {
  int initialValue = 1,
  int minValue = 1,
  int maxValue = 99,
  String label = 'Količina',
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => QuantitySelector(
      initialValue: initialValue,
      minValue: minValue,
      maxValue: maxValue,
      label: label,
    ),
  );
}
