import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../database/tables/medications.dart';

/// Preset medication data for common medications in Slovenia
class MedicationPreset {
  final String name;
  final MedicationType type;
  final String? intakeAdvice;
  final IconData icon;

  const MedicationPreset({
    required this.name,
    required this.type,
    this.intakeAdvice,
    this.icon = Symbols.pill,
  });
}

/// Common medications used in Slovenia
const List<MedicationPreset> slovenianMedicationPresets = [
  // Pain relievers / Fever reducers
  MedicationPreset(
    name: 'Lekadol',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti s kozarcem vode',
    icon: Symbols.pill,
  ),
  MedicationPreset(
    name: 'Nalgesin',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti po obroku',
    icon: Symbols.pill,
  ),
  MedicationPreset(
    name: 'Ibuprofen',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti po obroku',
    icon: Symbols.pill,
  ),
  MedicationPreset(
    name: 'Aspirin',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti s kozarcem vode',
    icon: Symbols.pill,
  ),
  MedicationPreset(
    name: 'Paracetamol',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti s kozarcem vode',
    icon: Symbols.pill,
  ),

  // Blood pressure
  MedicationPreset(
    name: 'Enap',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti zjutraj',
    icon: Symbols.cardiology,
  ),
  MedicationPreset(
    name: 'Lorista',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti zjutraj',
    icon: Symbols.cardiology,
  ),
  MedicationPreset(
    name: 'Concor',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti zjutraj',
    icon: Symbols.cardiology,
  ),
  MedicationPreset(
    name: 'Amlodipin',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti ob istem času vsak dan',
    icon: Symbols.cardiology,
  ),

  // Cholesterol
  MedicationPreset(
    name: 'Atoris',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti zvečer',
    icon: Symbols.water_drop,
  ),
  MedicationPreset(
    name: 'Crestor',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti zvečer',
    icon: Symbols.water_drop,
  ),

  // Diabetes
  MedicationPreset(
    name: 'Metformin',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti z obrokom',
    icon: Symbols.glucose,
  ),
  MedicationPreset(
    name: 'Glucophage',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti z obrokom',
    icon: Symbols.glucose,
  ),

  // Stomach / Digestion
  MedicationPreset(
    name: 'Controloc',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti 30 min pred obrokom',
    icon: Symbols.gastroenterology,
  ),
  MedicationPreset(
    name: 'Nolpaza',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti 30 min pred obrokom',
    icon: Symbols.gastroenterology,
  ),
  MedicationPreset(
    name: 'Ranital',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti pred obrokom',
    icon: Symbols.gastroenterology,
  ),

  // Thyroid
  MedicationPreset(
    name: 'Euthyrox',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti na tešče, 30 min pred zajtrkom',
    icon: Symbols.endocrinology,
  ),

  // Antibiotics
  MedicationPreset(
    name: 'Amoksiklav',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti na začetku obroka',
    icon: Symbols.medication,
  ),
  MedicationPreset(
    name: 'Sumamed',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti 1 uro pred ali 2 uri po obroku',
    icon: Symbols.medication,
  ),

  // Vitamins & Supplements
  MedicationPreset(
    name: 'Vitamin D',
    type: MedicationType.drops,
    intakeAdvice: 'Zaužiti z mastnim obrokom',
    icon: Symbols.sunny,
  ),
  MedicationPreset(
    name: 'Vitamin C',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti s kozarcem vode',
    icon: Symbols.eco,
  ),
  MedicationPreset(
    name: 'Magnezij',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti zvečer',
    icon: Symbols.exercise,
  ),
  MedicationPreset(
    name: 'Železo',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti na tešče s sokom pomaranče',
    icon: Symbols.water_drop,
  ),

  // Allergy
  MedicationPreset(
    name: 'Claritine',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti enkrat dnevno',
    icon: Symbols.allergy,
  ),
  MedicationPreset(
    name: 'Aerius',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti enkrat dnevno',
    icon: Symbols.allergy,
  ),

  // Sleep / Anxiety
  MedicationPreset(
    name: 'Sanval',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti pred spanjem',
    icon: Symbols.bedtime,
  ),
  MedicationPreset(
    name: 'Lexaurin',
    type: MedicationType.pills,
    intakeAdvice: 'Zaužiti po navodilih zdravnika',
    icon: Symbols.psychology,
  ),

  // Asthma / Respiratory
  MedicationPreset(
    name: 'Berodual',
    type: MedicationType.puffs,
    intakeAdvice: 'Inhalirati po potrebi',
    icon: Symbols.pulmonology,
  ),
  MedicationPreset(
    name: 'Symbicort',
    type: MedicationType.puffs,
    intakeAdvice: 'Inhalirati zjutraj in zvečer',
    icon: Symbols.pulmonology,
  ),

  // Eye drops
  MedicationPreset(
    name: 'Systane',
    type: MedicationType.drops,
    intakeAdvice: 'Kapljati v oči po potrebi',
    icon: Symbols.visibility,
  ),
];

/// An expandable panel showing medication presets for quick addition
class MedicationPresetsPanel extends StatefulWidget {
  final bool initiallyExpanded;
  final VoidCallback? onPresetSelected;

  const MedicationPresetsPanel({
    super.key,
    this.initiallyExpanded = false,
    this.onPresetSelected,
  });

  @override
  State<MedicationPresetsPanel> createState() => _MedicationPresetsPanelState();
}

class _MedicationPresetsPanelState extends State<MedicationPresetsPanel>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MedicationPresetsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      if (widget.initiallyExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      _isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _selectPreset(MedicationPreset preset) async {
    await context.push(
      '/add-medication',
      extra: {
        'presetName': preset.name,
        'presetTypeIndex': preset.type.index,
        'presetIntakeAdvice': preset.intakeAdvice,
      },
    );
    // Call refresh after returning from add medication screen
    widget.onPresetSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar and header
          GestureDetector(
            onTap: _toggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Symbols.instant_mix,
                            color: colors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Priljubljena zdravila',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Symbols.keyboard_arrow_up,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightFactor.value,
                  child: child,
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxHeight: 350),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hitro dodaj pogosto uporabljeno zdravilo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slovenianMedicationPresets.map((preset) {
                        return _PresetChip(
                          preset: preset,
                          onTap: () => _selectPreset(preset),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final MedicationPreset preset;
  final VoidCallback onTap;

  const _PresetChip({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: 0.8),
            colors.secondaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(preset.icon, size: 14, color: colors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  preset.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
