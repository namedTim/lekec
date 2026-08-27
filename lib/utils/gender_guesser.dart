/// Guesses gender ('male' or 'female') from a first name,
/// using common Slovenian names + suffix heuristics.
/// Returns null if undetermined.
String? guessGenderFromName(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  // Check explicit lists first
  if (_femaleNames.contains(normalized)) return 'female';
  if (_maleNames.contains(normalized)) return 'male';

  // Slovenian heuristic: names ending in -a are almost always female,
  // with some male exceptions
  if (_maleEndingInA.contains(normalized)) return 'male';
  if (normalized.endsWith('a')) return 'female';

  // Names ending in common male suffixes
  if (normalized.endsWith('o') ||
      normalized.endsWith('e') ||
      normalized.endsWith('k') ||
      normalized.endsWith('n') ||
      normalized.endsWith('r') ||
      normalized.endsWith('j') ||
      normalized.endsWith('š') ||
      normalized.endsWith('ž') ||
      normalized.endsWith('č') ||
      normalized.endsWith('c') ||
      normalized.endsWith('t') ||
      normalized.endsWith('d') ||
      normalized.endsWith('l') ||
      normalized.endsWith('b') ||
      normalized.endsWith('m') ||
      normalized.endsWith('p') ||
      normalized.endsWith('s')) {
    return 'male';
  }

  return null;
}

/// Common male Slovenian/international names
const _maleNames = <String>{
  // Most popular Slovenian male names
  'luka', 'jan', 'mark', 'filip', 'jakob', 'nik', 'žan', 'tim', 'vid',
  'anže', 'matic', 'nejc', 'žiga', 'gal', 'rok', 'jure', 'blaž', 'miha',
  'matej', 'andrej', 'gregor', 'peter', 'tomaž', 'simon', 'david', 'marko',
  'janez', 'franc', 'ivan', 'anton', 'jožef', 'rudolf', 'karl', 'matjaž',
  'bojan', 'dejan', 'igor', 'aleš', 'robert', 'primož', 'boštjan', 'martin',
  'aljaž', 'urban', 'tilen', 'nace', 'marcel', 'boris', 'milan', 'leon',
  'aleksander', 'sebastjan', 'benjamin', 'gabriel', 'rafael', 'henrik',
  'dominik', 'patrik', 'denis', 'erik', 'kevin', 'kristjan', 'damjan',
  'samo', 'tadej', 'jurij', 'gašper', 'lovro', 'oskar', 'rene', 'tine',
  'sašo', 'tone', 'jaka', 'bine', 'cene', 'domen', 'klemen', 'svit',
  'maj', 'črt', 'nal', 'lukas', 'maksimiljan', 'abel', 'elias',
  'daniel', 'manuel', 'nicolas', 'noah', 'tobias', 'valentin', 'viktor',
  'edo', 'ivo', 'miro', 'hugo', 'bruno', 'oto', 'alex',
  'adam', 'aron', 'tian', 'ian', 'enej', 'tai', 'neo', 'kim',
};

/// Common female Slovenian/international names
const _femaleNames = <String>{
  // Most popular Slovenian female names
  'nina', 'ana', 'maja', 'eva', 'sara', 'lana', 'nika', 'zala', 'hana',
  'ema', 'julija', 'lara', 'lea', 'neža', 'taja', 'tina', 'petra', 'masa',
  'anja', 'katja', 'urška', 'mojca', 'barbara', 'irena', 'nataša', 'vesna',
  'marija', 'tatjana', 'mateja', 'simona', 'alenka', 'sonja', 'marta',
  'vida', 'ivana', 'milena', 'helena', 'marina', 'kristina', 'tamara',
  'nada', 'olga', 'dragica', 'lidija', 'jelka', 'slavka', 'branka',
  'valentina', 'polonca', 'renata', 'suzana', 'mija', 'klara', 'iris',
  'ajda', 'neja', 'pia', 'ela', 'zoja', 'alja', 'gaja', 'lina', 'kaja',
  'iza', 'živa', 'špela', 'maša', 'tia', 'vita', 'brina', 'mila',
  'sofija', 'izabela', 'lucija', 'adriana', 'aleksandra', 'dominika',
  'gabriela', 'patricija', 'monika', 'veronika', 'danica', 'marjeta',
  'janja', 'polona', 'manca', 'nuša', 'ula', 'lili', 'ines',
  'nastja', 'katarina', 'karmen', 'dijana', 'jasna', 'andreja',
  'alma', 'cvetka', 'frančiška', 'mihaela', 'danijela', 'brigita',
  'sabina', 'darja', 'saša', 'romana', 'magda',
};

/// Male names that end in -a (exceptions to the suffix heuristic)
const _maleEndingInA = <String>{
  'luka',
  'jaka',
  'blaža',
  'matija',
  'ilija',
  'nikita',
  'miha',
  'saša',
  'nikola',
  'kosma',
  'jeremija',
  'izaija',
};
