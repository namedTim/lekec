import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = await (db.select(db.onboardingSettings)..limit(1)).getSingleOrNull();
  return settings?.isCompleted ?? false;
});
