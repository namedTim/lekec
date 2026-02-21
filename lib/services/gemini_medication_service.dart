import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../database/tables/medications.dart';
import '../ui/screens/medication_frequency_selection.dart' show FrequencyOption;
import '../ui/screens/advanced_medication_planning.dart'
    show AdvancedScheduleType;
import '../config/api_keys.dart';

/// Represents the recommended dosage frequency extracted from medication labels
class DosageFrequency {
  /// How many times per day (e.g., 1, 2, 3)
  final int? timesPerDay;

  /// Amount per dose (e.g., 0.5, 1, 2 tablets)
  final double? amountPerDose;

  /// Interval in hours between doses (e.g., 12 for "na 12 ur")
  final int? intervalHours;

  /// Whether it's taken as needed ("po potrebi")
  final bool isAsNeeded;

  /// Whether it's cyclic (e.g., "10 dni jemanja, 20 dni pavze")
  final bool isCyclic;

  /// Days on for cyclic (e.g., 10)
  final int? cyclicDaysOn;

  /// Days off for cyclic (e.g., 20)
  final int? cyclicDaysOff;

  /// Specific days of week (0=Monday, 6=Sunday)
  final List<int>? specificDays;

  /// Raw frequency text from label
  final String? rawText;

  /// Suggested times of day for taking medication (e.g., ["08:00", "14:00", "20:00"])
  final List<String>? suggestedTimes;

  DosageFrequency({
    this.timesPerDay,
    this.amountPerDose,
    this.intervalHours,
    this.isAsNeeded = false,
    this.isCyclic = false,
    this.cyclicDaysOn,
    this.cyclicDaysOff,
    this.specificDays,
    this.rawText,
    this.suggestedTimes,
  });

  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory DosageFrequency.fromJson(Map<String, dynamic> json) {
    return DosageFrequency(
      timesPerDay: _safeInt(json['timesPerDay']),
      amountPerDose: _safeDouble(json['amountPerDose']),
      intervalHours: _safeInt(json['intervalHours']),
      isAsNeeded: json['isAsNeeded'] == true || json['isAsNeeded'] == 'true',
      isCyclic: json['isCyclic'] == true || json['isCyclic'] == 'true',
      cyclicDaysOn: _safeInt(json['cyclicDaysOn']),
      cyclicDaysOff: _safeInt(json['cyclicDaysOff']),
      specificDays: (json['specificDays'] as List<dynamic>?)?.map((e) => _safeInt(e) ?? 0).toList(),
      rawText: json['rawText'] as String?,
      suggestedTimes: (json['suggestedTimes'] as List<dynamic>?)
          ?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'timesPerDay': timesPerDay,
    'amountPerDose': amountPerDose,
    'intervalHours': intervalHours,
    'isAsNeeded': isAsNeeded,
    'isCyclic': isCyclic,
    'cyclicDaysOn': cyclicDaysOn,
    'cyclicDaysOff': cyclicDaysOff,
    'specificDays': specificDays,
    'rawText': rawText,
    'suggestedTimes': suggestedTimes,
  };

  /// Converts to the app's FrequencyOption enum
  FrequencyOption? toFrequencyOption() {
    if (isAsNeeded) return FrequencyOption.asNeeded;
    if (isCyclic || intervalHours != null || specificDays != null) {
      return FrequencyOption.moreOptions;
    }
    if (timesPerDay == 1) return FrequencyOption.onceDaily;
    if (timesPerDay == 2) return FrequencyOption.twiceDaily;
    if (timesPerDay != null && timesPerDay! > 2)
      return FrequencyOption.moreOptions;
    return null;
  }

  /// Converts to AdvancedScheduleType if applicable
  AdvancedScheduleType? toAdvancedScheduleType() {
    if (intervalHours != null) return AdvancedScheduleType.interval;
    if (isCyclic) return AdvancedScheduleType.cyclic;
    if (specificDays != null && specificDays!.isNotEmpty) {
      return AdvancedScheduleType.specificDays;
    }
    if (timesPerDay != null && timesPerDay! > 2) {
      return AdvancedScheduleType.multipleTimes;
    }
    return null;
  }
}

/// Complete medication extraction result from AI
class MedicationExtractionResult {
  // Basic medication info
  final String? medicationName;
  final MedicationType? medicationType;
  final String? pillSize;

  // Quantity and packaging
  final int? quantityInBox;

  // Dosage and frequency
  final DosageFrequency? dosageFrequency;

  // Label info
  final String? pharmacyName;
  final String? patientName;

  // Additional notes
  final String? notes;
  final String? intakeAdvice;

  MedicationExtractionResult({
    this.medicationName,
    this.medicationType,
    this.pillSize,
    this.quantityInBox,
    this.dosageFrequency,
    this.pharmacyName,
    this.patientName,
    this.notes,
    this.intakeAdvice,
  });

  factory MedicationExtractionResult.fromJson(Map<String, dynamic> json) {
    return MedicationExtractionResult(
      medicationName: json['medicationName'] as String?,
      medicationType: _parseMedicationType(json['medicationType'] as String?),
      pillSize: json['pillSize'] as String?,
      quantityInBox: _parseInt(json['quantityInBox']),
      dosageFrequency: json['dosageFrequency'] != null
          ? DosageFrequency.fromJson(
              json['dosageFrequency'] as Map<String, dynamic>,
            )
          : null,
      pharmacyName: json['pharmacyName'] as String?,
      patientName: json['patientName'] as String?,
      notes: json['notes'] as String?,
      intakeAdvice: json['intakeAdvice'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'medicationName': medicationName,
    'medicationType': medicationType?.name,
    'pillSize': pillSize,
    'quantityInBox': quantityInBox,
    'dosageFrequency': dosageFrequency?.toJson(),
    'pharmacyName': pharmacyName,
    'patientName': patientName,
    'notes': notes,
    'intakeAdvice': intakeAdvice,
  };

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static MedicationType? _parseMedicationType(String? type) {
    if (type == null) return null;

    final lowerType = type.toLowerCase();
    if (lowerType.contains('tablet') ||
        lowerType.contains('pill') ||
        lowerType.contains('tableta')) {
      return MedicationType.pills;
    } else if (lowerType.contains('capsul') || lowerType.contains('kapsul')) {
      return MedicationType.capsules;
    } else if (lowerType.contains('drop') || lowerType.contains('kapljic')) {
      return MedicationType.drops;
    } else if (lowerType.contains('ampul')) {
      return MedicationType.ampules;
    } else if (lowerType.contains('inject') || lowerType.contains('injekcij')) {
      return MedicationType.injections;
    } else if (lowerType.contains('spray') || lowerType.contains('pršil')) {
      return MedicationType.sprays;
    } else if (lowerType.contains('patch') || lowerType.contains('obliž')) {
      return MedicationType.patches;
    } else if (lowerType.contains('puff') || lowerType.contains('vdih')) {
      return MedicationType.puffs;
    } else if (lowerType.contains('sirup') ||
        lowerType.contains('ml') ||
        lowerType.contains('mililiter')) {
      return MedicationType.milliliters;
    } else if (lowerType.contains('gram') &&
        !lowerType.contains('mili') &&
        !lowerType.contains('mikro')) {
      return MedicationType.grams;
    } else if (lowerType.contains('miligram') || lowerType.contains('mg')) {
      return MedicationType.milligrams;
    } else if (lowerType.contains('mikrogram') ||
        lowerType.contains('mcg') ||
        lowerType.contains('μg')) {
      return MedicationType.micrograms;
    }

    return MedicationType.pills; // Default
  }

  /// Get best matching intake advice from extracted data
  String? getIntakeAdvice() {
    if (intakeAdvice != null) return intakeAdvice;

    // Try to parse from notes
    if (notes != null) {
      final lowerNotes = notes!.toLowerCase();
      if (lowerNotes.contains('pred obrokom') ||
          lowerNotes.contains('pred jedjo') ||
          lowerNotes.contains('na tešče')) {
        return 'Pred obrokom';
      } else if (lowerNotes.contains('z obrokom') ||
          lowerNotes.contains('med jedjo') ||
          lowerNotes.contains('ob hrani')) {
        return 'Z obrokom';
      } else if (lowerNotes.contains('po obroku') ||
          lowerNotes.contains('po jedi')) {
        return 'Po obroku';
      }
    }

    return null;
  }
}

class GeminiMedicationService {
  late final GenerativeModel _model;

  GeminiMedicationService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiKeys.geminiApiKey,
    );
  }

  Future<MedicationExtractionResult> extractMedicationInfo(
    File imageFile,
  ) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
Analiziraj sliko embalaže/nalepke zdravila in izvleci naslednje informacije.
Nalepka je lahko v slovenščini ali angleščini, vendar MORAŠ odgovoriti IZKLJUČNO V SLOVENŠČINI.

Izvleci:
1. Ime zdravila z jakostjo (npr. "Lekadol 500 mg", "Metamizol STADA 500 mg", "Aspirin 100 mg") - VEDNO vključi mg/ml jakost v imenu, če je vidna
2. Oblika zdravila (tablete, kapsule, kapljice, ampule, injekcije, pršila, obliži, puff, sirup, itd.)
3. Jakost (npr. "500 mg", "10 mg", "2.5 ml", itd.) - to je ločeno polje
4. Količina v škatli/pakiranju (število tablet, ampul, ml, itd.)
5. Ime lekarne, če je vidno
6. Ime pacienta, če je to receptna nalepka
7. Priporočena pogostost jemanja - natančno razčleni:
   - "enkrat dnevno" / "1x daily" = enkrat dnevno
   - "dvakrat dnevno" / "2x daily" = dvakrat dnevno  
   - "3x na dan" / "3x dnevno" = 3-krat dnevno
   - "po potrebi" / "as needed" / "ob bolečini" = po potrebi
   - "na X ur" / "every X hours" = interval (izvleci X)
   - "ciklično" npr. "10 dni jemanja, 20 dni pavze" = ciklično
   - omenjeni specifični dnevi = specifični dnevi
8. Količina na odmerek (npr. "2 tableti", "1 kapsula", "polovica tablete" = 0.5 = koliko vzeti vsak odmerek, podpiraj decimalna števila kot 0.5 za polovico)
9. Nasveti za jemanje - ZDRUŽI VSE nasvete v eno polje, vključno z:
   - Čas jemanja: "pred obrokom", "z obrokom", "po jedi", "na tešče", "pred spanjem"
   - Opozorila in omejitve: "NE SKUPAJ Z ...", "brez alkohola", "ne z mlekom"
   - Primer: če piše "2 x 1 kapsulo po jedi, NE SKUPAJ Z ANALGINOM" naj bo intakeAdvice: "Po jedi. Ne jemati skupaj z analginom."
   - Vse nasvete prevedi v slovenščino!
10. Predlagani časi jemanja - na podlagi pogostosti in navodil predlagaj primerne čase v 24-urnem formatu:
    - 1x dnevno: ["08:00"] (zjutraj) razen če piše zvečer/pred spanjem potem ["20:00"]
    - 2x dnevno: ["08:00", "20:00"] (zjutraj in zvečer)
    - 3x dnevno: ["08:00", "14:00", "20:00"] (zjutraj, popoldne, zvečer)
    - 4x dnevno: ["08:00", "12:00", "16:00", "20:00"]
    - Če so navedeni specifični časi (npr. "ob 8h in 20h"), uporabi te
11. Morebitne druge pomembne opombe

Odgovori IZKLJUČNO v veljavnem JSON formatu:
{
  "medicationName": "ime z jakostjo npr. Lekadol 500 mg ali null",
  "medicationType": "oblika v slovenščini ali null",
  "pillSize": "jakost ali null",
  "quantityInBox": število ali null,
  "pharmacyName": "ime lekarne ali null",
  "patientName": "ime pacienta ali null",
  "intakeAdvice": "vsi nasveti za jemanje v slovenščini ali null",
  "dosageFrequency": {
    "timesPerDay": število ali null,
    "amountPerDose": število (decimalno, npr. 0.5 za polovico, 1, 2) ali null,
    "intervalHours": število ali null,
    "isAsNeeded": boolean,
    "isCyclic": boolean,
    "cyclicDaysOn": število ali null,
    "cyclicDaysOff": število ali null,
    "specificDays": [seznam dni 0-6] ali null,
    "rawText": "originalno besedilo pogostosti ali null",
    "suggestedTimes": ["HH:MM", "HH:MM", ...] predlagani časi v 24-urnem formatu ali null
  },
  "notes": "dodatne pomembne opombe v slovenščini ali null"
}

Uporabi null za polja, ki jih ne moreš identificirati. Ne vključi nobenega besedila izven JSON-a.
VSE vrednosti morajo biti v SLOVENŠČINI, tudi če je nalepka v angleščini!
''';

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return MedicationExtractionResult();
      }

      // Try to parse JSON from response
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        return MedicationExtractionResult(
          notes:
              'Could not extract structured data. Raw response: \$responseText',
        );
      }

      final jsonStr = responseText.substring(jsonStart, jsonEnd + 1);

      try {
        final Map<String, dynamic> jsonData = json.decode(jsonStr);
        return MedicationExtractionResult.fromJson(jsonData);
      } catch (e) {
        // Fallback to simple parsing if JSON decode fails
        return _parseSimpleJson(jsonStr);
      }
    } catch (e) {
      return MedicationExtractionResult(
        notes: 'Error extracting medication info: \$e',
      );
    }
  }

  /// Fallback simple JSON parsing
  MedicationExtractionResult _parseSimpleJson(String jsonStr) {
    final Map<String, dynamic> jsonData = {};

    final lines = jsonStr.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.contains(':')) {
        final colonIndex = line.indexOf(':');
        var key = line
            .substring(0, colonIndex)
            .replaceAll('"', '')
            .replaceAll('{', '')
            .trim();
        var value = line
            .substring(colonIndex + 1)
            .replaceAll('"', '')
            .replaceAll(',', '')
            .replaceAll('}', '')
            .trim();

        if (value.toLowerCase() == 'null' || value.isEmpty) {
          continue;
        }

        // Try to parse as number
        final intVal = int.tryParse(value);
        if (intVal != null) {
          jsonData[key] = intVal;
        } else if (value == 'true') {
          jsonData[key] = true;
        } else if (value == 'false') {
          jsonData[key] = false;
        } else if (key.isNotEmpty) {
          jsonData[key] = value;
        }
      }
    }

    return MedicationExtractionResult.fromJson(jsonData);
  }
}
