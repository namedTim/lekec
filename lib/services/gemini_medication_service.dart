import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

/// Talks to LekecAPI's `/ai/extract-medication` endpoint.
/// The server picks the AI provider (Gemini, OpenRouter, Ollama, …) and
/// returns the parsed result, so the app no longer holds AI keys.
class GeminiMedicationService {
  GeminiMedicationService();

  Future<MedicationExtractionResult> extractMedicationInfo(
    File imageFile,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiKeys.lekecApiBaseUrl}/api/v1/ai/extract-medication',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers['X-API-Key'] = ApiKeys.lekecApiKey
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        return MedicationExtractionResult(
          notes:
              'API napaka (${response.statusCode}): ${response.body}',
        );
      }

      final Map<String, dynamic> data = json.decode(response.body);
      return MedicationExtractionResult.fromJson(data);
    } catch (e) {
      return MedicationExtractionResult(
        notes: 'Napaka pri klicu API-ja: $e',
      );
    }
  }
}
