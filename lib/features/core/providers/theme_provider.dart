import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import 'package:lekec/database/drift_database.dart';
import 'package:lekec/features/core/providers/database_provider.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  Future<ThemeMode> build() async {
    final db = ref.read(databaseProvider);

    final settings = await db.select(db.appSettings).getSingleOrNull();

    if (settings == null) {
      await db.into(db.appSettings).insert(
            AppSettingsCompanion.insert(
              themeMode: const Value('system'),
            ),
          );
      return ThemeMode.system;
    }

    return _parseThemeMode(settings.themeMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final db = ref.read(databaseProvider);
    final modeString = _getThemeModeString(mode);

    // Optimistic update
    state = AsyncData(mode);

    final settings = await db.select(db.appSettings).getSingleOrNull();

    if (settings != null) {
      await (db.update(db.appSettings)
            ..where((t) => t.id.equals(settings.id)))
          .write(
        AppSettingsCompanion(themeMode: Value(modeString)),
      );
    } else {
      await db.into(db.appSettings).insert(
            AppSettingsCompanion.insert(
              themeMode: Value(modeString),
            ),
          );
    }
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _getThemeModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}