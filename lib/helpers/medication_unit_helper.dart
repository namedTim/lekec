import 'package:lekec/database/tables/medications.dart';

/// Helper function for Slovenian pluralization rules
/// 1 = singular, 2 = dual, 3-4 = plural, 5+ = genitive plural
String pluralizeSlovenian(
  int count,
  String singular,
  String dual,
  String plural,
  String genitivePlural,
) {
  if (count == 1) {
    return singular;
  } else if (count == 2) {
    return dual;
  } else if (count == 3 || count == 4) {
    return plural;
  } else {
    return genitivePlural;
  }
}

/// Get the properly pluralized medication unit based on count
String getMedicationUnit(MedicationType type, int count) {
  switch (type) {
    case MedicationType.pills:
      return pluralizeSlovenian(count, 'tableta', 'tableti', 'tablete', 'tablet');
    case MedicationType.capsules:
      return pluralizeSlovenian(count, 'kapsula', 'kapsuli', 'kapsule', 'kapsul');
    case MedicationType.drops:
      return pluralizeSlovenian(count, 'kapljica', 'kapljici', 'kapljice', 'kapljic');
    case MedicationType.milliliters:
      return 'ml';
    case MedicationType.sprays:
      return pluralizeSlovenian(count, 'brizg', 'brizga', 'brizgi', 'brizgov');
    case MedicationType.injections:
      return pluralizeSlovenian(count, 'injekcija', 'injekciji', 'injekcije', 'injekcij');
    case MedicationType.patches:
      return pluralizeSlovenian(count, 'obliž', 'obliža', 'obliži', 'obližev');
    case MedicationType.puffs:
      return pluralizeSlovenian(count, 'vdih', 'vdiha', 'vdihi', 'vdihov');
    case MedicationType.applications:
      return pluralizeSlovenian(count, 'nanos', 'nanosa', 'nanosi', 'nanosov');
    case MedicationType.ampules:
      return pluralizeSlovenian(count, 'ampula', 'ampuli', 'ampule', 'ampul');
    case MedicationType.grams:
      return pluralizeSlovenian(count, 'gram', 'grama', 'grami', 'gramov');
    case MedicationType.milligrams:
      return 'mg';
    case MedicationType.micrograms:
      return 'mcg';
    case MedicationType.tablespoons:
      return pluralizeSlovenian(count, 'žlička', 'žlički', 'žličke', 'žličk');
    case MedicationType.portions:
      return pluralizeSlovenian(count, 'porcija', 'porciji', 'porcije', 'porcij');
    case MedicationType.pieces:
      return pluralizeSlovenian(count, 'kos', 'kosa', 'kosi', 'kosov');
    case MedicationType.units:
      return pluralizeSlovenian(count, 'enota', 'enoti', 'enote', 'enot');
  }
}

/// Alias for getMedicationUnit for backward compatibility
String getMedicationUnitShort(MedicationType type, int count) {
  return getMedicationUnit(type, count);
}
