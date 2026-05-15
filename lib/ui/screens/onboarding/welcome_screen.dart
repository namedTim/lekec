import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const SizedBox(height: 24),

                      // App Icon/Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.primary, width: 2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Symbols.medication,
                          size: 64,
                          color: colors.primary,
                          fill: 1,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Welcome Title
                      Text(
                        'Pozdravljeni v Lekec',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'Vaš osebni pomočnik za spremljanje jemanja zdravil',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Features List
                      _FeatureItem(
                        icon: Symbols.photo_camera,
                        title: 'AI branje zdravil',
                        description:
                            'Slikajte recept zdravila in podatki se samodejno izpolnijo',
                        colors: colors,
                      ),

                      const SizedBox(height: 20),

                      _FeatureItem(
                        icon: Symbols.alarm,
                        title: 'Pametni opomniki',
                        description:
                            'Obvestila in kritični alarmi ob pravem času',
                        colors: colors,
                      ),

                      const SizedBox(height: 20),

                      _FeatureItem(
                        icon: Symbols.calendar_month,
                        title: 'Prilagodljivi urnik',
                        description:
                            'Načrtujte jemanje zdravil po svojih potrebah',
                        colors: colors,
                      ),

                      const SizedBox(height: 20),

                      _FeatureItem(
                        icon: Symbols.group,
                        title: 'Več uporabnikov',
                        description:
                            'Upravljajte zdravila za celo družino ali skrbite za druge',
                        colors: colors,
                      ),

                      const SizedBox(height: 20),

                      _FeatureItem(
                        icon: Symbols.mood,
                        title: 'Razpoloženje & menstruacija',
                        description:
                            'Beležite počutje in spremljajte menstrualni cikel',
                        colors: colors,
                      ),

                      const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Get Started Button
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Začnimo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colors;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: colors.primary, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
