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

  Future<void> _showManualInput() async {
    final controller = TextEditingController(text: _value.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vnesi količino'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: '${widget.minValue} - ${widget.maxValue}',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final parsed = int.tryParse(value);
            if (parsed != null &&
                parsed >= widget.minValue &&
                parsed <= widget.maxValue) {
              Navigator.of(context).pop(parsed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Prekliči'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null &&
                  parsed >= widget.minValue &&
                  parsed <= widget.maxValue) {
                Navigator.of(context).pop(parsed);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Vnesi število med ${widget.minValue} in ${widget.maxValue}'),
                  ),
                );
              }
            },
            child: const Text('V redu'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _value = result);
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
            InkWell(
              onTap: _showManualInput,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.outline.withOpacity(0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _value.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
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
