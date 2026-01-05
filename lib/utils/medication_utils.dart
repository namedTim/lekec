import 'package:lekec/database/tables/medications.dart';

String getMedicationUnit(MedicationType type) {
  switch (type) {
    case MedicationType.pills:
      return 'tableto/e';
    case MedicationType.capsules:
      return 'kapsulo/e';
    case MedicationType.drops:
      return 'kapljic/o';
    case MedicationType.milliliters:
      return 'ml';
    case MedicationType.sprays:
      return 'brizgov/a';
    case MedicationType.injections:
      return 'injekcijo/e';
    case MedicationType.patches:
      return 'obliž/ev';
    case MedicationType.puffs:
      return 'vdihov/a';
    case MedicationType.applications:
      return 'nanosov/a';
    case MedicationType.ampules:
      return 'ampulo/e';
    case MedicationType.grams:
      return 'gramov/a';
    case MedicationType.milligrams:
      return 'mg';
    case MedicationType.micrograms:
      return 'mcg';
    case MedicationType.tablespoons:
      return 'žličk/o';
    case MedicationType.portions:
      return 'porcijo/e';
    case MedicationType.pieces:
      return 'kos/ov';
    case MedicationType.units:
      return 'enot/o';
  }
}

String getMedicationUnitShort(MedicationType type) {
  switch (type) {
    case MedicationType.pills:
      return 'tablet';
    case MedicationType.capsules:
      return 'kapsul';
    case MedicationType.drops:
      return 'kapljic';
    case MedicationType.milliliters:
      return 'ml';
    case MedicationType.sprays:
      return 'brizgov';
    case MedicationType.injections:
      return 'injekcij';
    case MedicationType.patches:
      return 'obližev';
    case MedicationType.puffs:
      return 'vdihov';
    case MedicationType.applications:
      return 'nanosov';
    case MedicationType.ampules:
      return 'ampul';
    case MedicationType.grams:
      return 'gramov';
    case MedicationType.milligrams:
      return 'mg';
    case MedicationType.micrograms:
      return 'mcg';
    case MedicationType.tablespoons:
      return 'žličk';
    case MedicationType.portions:
      return 'porcij';
    case MedicationType.pieces:
      return 'kosov';
    case MedicationType.units:
      return 'enot';
  }
}
