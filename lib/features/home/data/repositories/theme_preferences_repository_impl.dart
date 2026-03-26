import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/theme_preferences_repository.dart';

class ThemePreferencesRepositoryImpl implements IThemePreferencesRepository {
  static const _key = 'lota_theme_mode_v1';

  @override
  Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return ThemeMode.system;
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return ThemeMode.system;
  }

  @override
  Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
