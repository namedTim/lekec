import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/medication_service.dart';
import '../../../data/services/mock_data_service.dart';
import '../../core/providers/database_provider.dart';

const bool useMock = true;

final medicationServiceProvider = Provider<dynamic>((ref) {
  final db = ref.watch(databaseProvider);

  if (useMock) {
    return MockDataService(db);
  }

  return MedicationService(db);
});
