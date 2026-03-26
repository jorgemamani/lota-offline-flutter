import 'package:flutter/material.dart';

/// Persistencia del modo de tema elegido por el usuario.
///
/// En web usa `localStorage` vía [shared_preferences]; en móvil, almacenamiento local del SO.
abstract interface class IThemePreferencesRepository {
  /// Lee el último modo guardado, o [ThemeMode.system] si no hay valor válido.
  Future<ThemeMode> load();

  Future<void> save(ThemeMode mode);
}
