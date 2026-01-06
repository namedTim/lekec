import 'package:lekec/database/tables/medications.dart';

String _pluralizeSlovenian(int count, String singular, String dual, String plural, String genitivePlural) {
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

String getMedicationUnit(MedicationType type, int count) {
  switch (type) {
    case MedicationType.pills:
      return _pluralizeSlovenian(count, 'tableta', 'tableti', 'tablete', 'tablet');
    case MedicationType.capsules:
      return _pluralizeSlovenian(count, 'kapsula', 'kapsuli', 'kapsule', 'kapsul');
    case MedicationType.drops:
      return _pluralizeSlovenian(count, 'kapljica', 'kapljici', 'kapljice', 'kapljic');
    case MedicationType.milliliters:
      return 'ml';
    case MedicationType.sprays:
      return _pluralizeSlovenian(count, 'brizg', 'brizga', 'brizgi', 'brizgov');
    case MedicationType.injections:
      return _pluralizeSlovenian(count, 'injekcija', 'injekciji', 'injekcije', 'injekcij');
    case MedicationType.patches:
      return _pluralizeSlovenian(count, 'obliž', 'obliža', 'obliži', 'obližev');
    case MedicationType.puffs:
      return _pluralizeSlovenian(count, 'vdih', 'vdiha', 'vdihi', 'vdihov');
    case MedicationType.applications:
      return _pluralizeSlovenian(count, 'nanos', 'nanosa', 'nanosi', 'nanosov');
    case MedicationType.ampules:
      return _pluralizeSlovenian(count, 'ampula', 'ampuli', 'ampule', 'ampul');
    case MedicationType.grams:
      return _pluralizeSlovenian(count, 'gram', 'grama', 'grami', 'gramov');
    case MedicationType.milligrams:
      return 'mg';
    case MedicationType.micrograms:
      return 'mcg';
    case MedicationType.tablespoons:
      return _pluralizeSlovenian(count, 'žlička', 'žlički', 'žličke', 'žličk');
    case MedicationType.portions:
      return _pluralizeSlovenian(count, 'porcija', 'porciji', 'porcije', 'porcij');
    case MedicationType.pieces:
      return _pluralizeSlovenian(count, 'kos', 'kosa', 'kosi', 'kosov');
    case MedicationType.units:
      return _pluralizeSlovenian(count, 'enota', 'enoti', 'enote', 'enot');
  }
}
