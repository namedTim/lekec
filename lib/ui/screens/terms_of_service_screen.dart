import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pogoji uporabe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pogoji uporabe aplikacije Lekec',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Zadnja posodobitev: april 2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              '1. Sprejem pogojev',
              'Z uporabo aplikacije Lekec se strinjate s temi pogoji uporabe. '
                  'Če se s pogoji ne strinjate, aplikacije ne uporabljajte.',
            ),
            _buildSection(
              theme,
              '2. Opis storitve',
              'Lekec je aplikacija za opominjanje na jemanje zdravil in termine. '
                  'Aplikacija NI medicinski pripomoček in NE nadomešča '
                  'strokovnega zdravstvenega mnenja ali nasveta.',
            ),
            _buildSection(
              theme,
              '3. Omejitev odgovornosti',
              'Aplikacija je ponujena "kot je" (as-is), brez kakršnihkoli jamstev. '
                  'Razvijalec ne prevzema nobene odgovornosti za:\n\n'
                  '\u2022 Zamujene ali neuspele opomnike zaradi tehničnih napak, '
                  'izpraznjenega baterije, sistemskih omejitev ali kakršnihkoli drugih razlogov\n'
                  '\u2022 Posledice jemanja ali nejemanja zdravil na podlagi opomnikov aplikacije\n'
                  '\u2022 Izgubo podatkov shranjenih v aplikaciji\n'
                  '\u2022 Kakršnokoli škodo, ki bi nastala kot posledica uporabe ali nezmožnosti uporabe aplikacije\n\n'
                  'Uporabnik je v celoti odgovoren za pravilno jemanje zdravil '
                  'po navodilih zdravnika ali farmacevta.',
            ),
            _buildSection(
              theme,
              '4. Zdravstveno opozorilo',
              'Lekec NI nadomestilo za strokovno medicinsko pomoč. '
                  'Za vse odločitve glede zdravljenja se vedno posvetujte z '
                  'zdravnikom ali farmacevtom. V nujnih primerih pokličite 112.',
            ),
            _buildSection(
              theme,
              '5. Zasebnost podatkov',
              'Vsi podatki (zdravila, termini, osebe) so shranjeni izključno '
                  'lokalno na vaši napravi. Aplikacija ne pošilja vaših podatkov '
                  'na nobene strežnike. Ob izbrisu aplikacije se vsi podatki izgubijo.',
            ),
            _buildSection(
              theme,
              '6. Pravice intelektualne lastnine',
              'Vse pravice intelektualne lastnine v aplikaciji pripadajo razvijalcu. '
                  'Aplikacijo smete uporabljati samo za osebne, nekomercialne namene.',
            ),
            _buildSection(
              theme,
              '7. Spremembe pogojev',
              'Razvijalec si pridržuje pravico do spremembe teh pogojev kadarkoli. '
                  'Nadaljna uporaba aplikacije po spremembi pomeni sprejem novih pogojev.',
            ),
            _buildSection(
              theme,
              '8. Prenehanje uporabe',
              'Aplikacijo lahko kadarkoli prenehate uporabljati tako, da jo '
                  'odstranite iz naprave.',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Kontakt: tim.robavs@gmail.com',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
