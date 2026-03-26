import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/theme_preferences_repository.dart';

/// Estado global del tema de la app.
///
/// El estado inicial se resuelve en [configureDependencies] leyendo disco antes
/// de [runApp] para evitar un frame con tema incorrecto. Cada cambio se persiste
/// (SharedPreferences en móvil / localStorage en web).
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._repository, ThemeMode initial) : super(initial);

  final IThemePreferencesRepository _repository;

  void setSystem() {
    emit(ThemeMode.system);
    _repository.save(ThemeMode.system);
  }

  void setLight() {
    emit(ThemeMode.light);
    _repository.save(ThemeMode.light);
  }

  void setDark() {
    emit(ThemeMode.dark);
    _repository.save(ThemeMode.dark);
  }

  void cycle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    emit(next);
    _repository.save(next);
  }
}
