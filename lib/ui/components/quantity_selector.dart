import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Formats a double for display: shows "0.5", "1", "2" (no trailing .0)
String _formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  // Show at most 2 decimal places, strip trailing zeros
  final s = value.toStringAsFixed(2);
  // Remove trailing zeros after decimal point
  if (s.contains('.')) {
    final trimmed = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return trimmed;
  }
  return s;
}

/// Parses a number string, treating comma as decimal separator
double? _parseNumber(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  return double.tryParse(normalized);
}

class QuantitySelector extends StatefulWidget {
  final double initialValue;
  final double minValue;
  final double maxValue;
  final double step;
  final String label;

  const QuantitySelector({
    super.key,
    this.initialValue = 1,
    this.minValue = 0.5,
    this.maxValue = 99,
    this.step = 1,
    this.label = 'Količina',
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _increment() {
    if (_value < widget.maxValue) {
      final raw = _value + widget.step;
      // Round to 2 decimal places to avoid floating point drift
      final rounded = (raw * 100).round() / 100;
      setState(() => _value = rounded.clamp(widget.minValue, widget.maxValue));
    }
  }

  void _decrement() {
    if (_value > widget.minValue) {
      final raw = _value - widget.step;
      final rounded = (raw * 100).round() / 100;
      setState(() => _value = rounded.clamp(widget.minValue, widget.maxValue));
    }
  }

  Future<void> _showManualInput() async {
    final controller = TextEditingController(text: _formatQuantity(_value));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vnesi količino'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: '${_formatQuantity(widget.minValue)} - ${_formatQuantity(widget.maxValue)}',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final parsed = _parseNumber(value);
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
              final parsed = _parseNumber(controller.text);
              if (parsed != null &&
                  parsed >= widget.minValue &&
                  parsed <= widget.maxValue) {
                Navigator.of(context).pop(parsed);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Vnesi število med ${_formatQuantity(widget.minValue)} in ${_formatQuantity(widget.maxValue)}',
                    ),
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
                // FittedBox keeps long values (e.g. "9999") inside the
                // 60-wide box by scaling them down, so the +/- buttons
                // never get pushed out of the dialog.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatQuantity(_value),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
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

Future<double?> showQuantitySelector(
  BuildContext context, {
  double initialValue = 1,
  double minValue = 0.5,
  double maxValue = 99,
  double step = 1,
  String label = 'Količina',
}) {
  return showDialog<double>(
    context: context,
    builder: (context) => QuantitySelector(
      initialValue: initialValue,
      minValue: minValue,
      maxValue: maxValue,
      step: step,
      label: label,
    ),
  );
}
