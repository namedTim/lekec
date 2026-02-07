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

  /// Amount per dose (e.g., 1, 2 tablets)
  final int? amountPerDose;

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

  factory DosageFrequency.fromJson(Map<String, dynamic> json) {
    return DosageFrequency(
      timesPerDay: json['timesPerDay'] as int?,
      amountPerDose: json['amountPerDose'] as int?,
      intervalHours: json['intervalHours'] as int?,
      isAsNeeded: json['isAsNeeded'] == true || json['isAsNeeded'] == 'true',
      isCyclic: json['isCyclic'] == true || json['isCyclic'] == 'true',
      cyclicDaysOn: json['cyclicDaysOn'] as int?,
      cyclicDaysOff: json['cyclicDaysOff'] as int?,
      specificDays: (json['specificDays'] as List<dynamic>?)?.cast<int>(),
      rawText: json['rawText'] as String?,
      suggestedTimes: (json['suggestedTimes'] as List<dynamic>?)
          ?.cast<String>(),
    );
  }

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
Analyze this medication packaging/label image and extract the following information.
The label may be in Slovenian or English.

Extract:
1. Medication name (brand name or generic name visible on the box/label)
2. Type of medication (tablets/tablete, capsules/kapsule, drops/kapljice, ampules/ampule, injections/injekcije, sprays/pršila, patches/obliži, puffs, syrup/sirup, etc.)
3. Pill/dosage strength (e.g., "500mg", "10mg", "2.5ml", etc.)
4. Quantity in box/package (number of pills, ampules, ml, etc.)
5. Pharmacy name if visible (lekarna)
6. Patient name if this is a prescription label
7. Recommended dosage frequency - parse carefully:
   - "enkrat dnevno" / "1x daily" = once daily
   - "dvakrat dnevno" / "2x daily" = twice daily  
   - "3x na dan" / "3x dnevno" = 3 times per day
   - "po potrebi" / "as needed" / "ob bolečini" = as needed
   - "na X ur" / "every X hours" = interval based (extract X)
   - "ciklično" / cyclic patterns like "10 dni jemanja, 20 dni pavze" = cyclic
   - specific days mentioned = specific days
8. Amount per dose (e.g., "2 tableti", "1 kapsula" = how many to take each time)
9. Intake advice (pred obrokom/before meal, z obrokom/with meal, po obroku/after meal, na tešče/empty stomach)
10. Suggested times of day - Based on the dosage frequency and any specific timing instructions (zjutraj/morning, zvečer/evening, pred spanjem/before sleep, etc.), suggest appropriate times in 24h format. Use sensible defaults:
    - 1x daily: ["08:00"] (morning) unless label says evening/pred spanjem then ["20:00"]
    - 2x daily: ["08:00", "20:00"] (morning and evening)
    - 3x daily: ["08:00", "14:00", "20:00"] (morning, afternoon, evening)
    - 4x daily: ["08:00", "12:00", "16:00", "20:00"]
    - If specific times mentioned on label (e.g., "ob 8h in 20h"), use those exact times
11. Any other important notes

Respond ONLY in valid JSON format:
{
  "medicationName": "string or null",
  "medicationType": "string or null",
  "pillSize": "string or null",
  "quantityInBox": number or null,
  "pharmacyName": "string or null",
  "patientName": "string or null",
  "intakeAdvice": "string or null",
  "dosageFrequency": {
    "timesPerDay": number or null,
    "amountPerDose": number or null,
    "intervalHours": number or null,
    "isAsNeeded": boolean,
    "isCyclic": boolean,
    "cyclicDaysOn": number or null,
    "cyclicDaysOff": number or null,
    "specificDays": [array of day numbers 0-6] or null,
    "rawText": "original frequency text from label or null",
    "suggestedTimes": ["HH:MM", "HH:MM", ...] array of suggested times in 24h format or null
  },
  "notes": "any additional important notes or null"
}

Use null for fields you cannot identify. Do not include any text outside the JSON.
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
