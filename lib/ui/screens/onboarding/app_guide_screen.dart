import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppGuideScreen extends StatefulWidget {
  final String? userName;
  final VoidCallback onComplete;

  const AppGuideScreen({
    super.key,
    this.userName,
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
    if (_currentPage < 6) {
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
    final greeting = widget.userName != null
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
                    children: List.generate(7, (index) {
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
                        'Določite vrsto zdravila, odmero in navodila za jemanje. '
                        'Izberite med preprostimi ali naprednimi urniki: '
                        'dnevno, intervalsko, specifični dnevi, ciklično in več.',
                    colors: colors,
                  ),
                  _GuidePage(
                    icon: Symbols.photo_camera,
                    title: 'AI branje zdravil',
                    description:
                        'Slikajte recept zdravila s kamero – '
                        'umetna inteligenca bo samodejno prebrala ime, '
                        'odmero, pogostost jemanja in število v škatli. '
                        'Podatki se izpolnijo avtomatsko, vi pa jih le potrdite.',
                    colors: colors,
                  ),
                  _GuidePage(
                    icon: Symbols.notifications,
                    title: 'Potisna obvestila',
                    description:
                        'Ob vsakem opomniku prejmete potisno obvestilo na telefon. '
                        'Obvestilo se prikaže v vrstici z obvestili – '
                        'tapnite ga, da potrdite jemanje ali ga odložite.',
                    colors: colors,
                  ),
                  _GuidePage(
                    icon: Symbols.alarm,
                    title: 'Kritični opomniki',
                    description:
                        'Za najpomembnejša zdravila omogočite kritične opomnike. '
                        'Telefon bo glasno zvonil in vibriral ter prikazal obvestilo na zaslonu – '
                        'tudi ko je zaslon ugasnjen ali telefon utišan (ne v načinu Ne moti). '
                        'Melodijo in vibracijo lahko spremenite v nastavitvah.',
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
                  _GuidePage(
                    icon: Symbols.mood,
                    title: 'Beleženje razpoloženja',
                    description:
                        'Vsak dan zabeležite, kako se počutite – '
                        'izberite med petimi razpoloženji od odličnega do slabega. '
                        'Dodajte opombo in spremljajte svoje počutje skozi čas '
                        'v profilu vsakega uporabnika.',
                    colors: colors,
                  ),
                  _GuidePage(
                    icon: Symbols.water_drop,
                    title: 'Spremljanje hidracije',
                    description:
                        'Beležite popito vodo čez dan in spremljajte napredek '
                        'proti dnevnemu cilju. '
                        'Nastavite lahko opomnike za pitje, cilj pa se prilagodi '
                        'vsakemu uporabniku.',
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
                child: const Text(
                  'Naprej',
                  style: TextStyle(
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
              border: Border.all(color: colors.primary, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, size: 64, color: colors.primary, fill: 1),
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
