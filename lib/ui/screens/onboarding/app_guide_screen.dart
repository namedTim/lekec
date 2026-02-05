import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../database/tables/onboarding_settings.dart';

class AppGuideScreen extends StatefulWidget {
  final String? userName;
  final UserType? userType;
  final VoidCallback onComplete;

  const AppGuideScreen({
    super.key,
    this.userName,
    this.userType,
    required this.onComplete,
  });

  @override
  State<AppGuideScreen> createState() => _AppGuideScreenState();
}

class _AppGuideScreenState extends State<AppGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skipToEnd() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final greeting = widget.userType == UserType.personal && widget.userName != null
        ? 'Pozdravljeni, ${widget.userName}!'
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 80), // Spacer for center alignment
                  // Page Indicator
                  Row(
                    children: List.generate(4, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colors.primary
                              : colors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: _skipToEnd,
                    child: const Text('Preskoči'),
                  ),
                ],
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _GuidePage(
                    greeting: greeting,
                    icon: Symbols.medication,
                    title: 'Dodajte zdravila',
                    description:
                        'Preprosto dodajte zdravila, ki jih jemljete. '
                        'Določite vrsto zdravila, odmero in navodila za jemanje.',
                    colors: colors,
                  ),
                  _GuidePage(
                    icon: Symbols.schedule,
                    title: 'Nastavite urnike',
                    description:
                        'Prilagodite urnik jemanja po svojih potrebah. '
                        'Izberite med preprostimi ali naprednimi možnostmi: '
                        'dnevno, intervalsko, specifični dnevi, ciklično in več.',
                    colors: colors,
                  ),
                  _GuidePage(
                    icon: Symbols.notifications_active,
                    title: 'Prejmite opomnike',
                    description:
                        'Aplikacija vas bo opozorila, ko pride čas za jemanje zdravil. '
                        'Potrdite jemanje ali ga odložite. Za kritična zdravila '
                        'lahko omogočite kritične opomnike z zvonenjem in vibriranjem '
                        '(spremenljivo v nastavitvah).',
                    colors: colors,
                  ),
                  _GuidePage(
                    icon: Symbols.history,
                    title: 'Spremljajte zgodovino',
                    description:
                        'Pregledujte zgodovino jemanja zdravil in ostanke zalog. '
                        'Dodajajte opombe in sledite napredku pri rednem jemanju.',
                    colors: colors,
                  ),
                ],
              ),
            ),
            
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton(
                onPressed: _nextPage,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentPage < 3 ? 'Naprej' : 'Začnimo!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  final String? greeting;
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colors;

  const _GuidePage({
    this.greeting,
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (greeting != null) ...[
            Text(
              greeting!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
          
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: colors.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 64,
              color: colors.primary,
              fill: 1,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
