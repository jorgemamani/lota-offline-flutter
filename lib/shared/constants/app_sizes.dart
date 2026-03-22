import 'package:flutter/material.dart';

/// Tamaños fijos reutilizables en toda la app.
///
/// Usar estas constantes en lugar de valores hardcodeados para mantener
/// consistencia visual y facilitar ajustes globales.
abstract final class AppSizes {
  AppSizes._();

  /// Espaciado superior por defecto para el contenido de una pantalla.
  static const defaultTopPadding = SizedBox(height: 50);

  /// Altura reservada para la barra de navegación inferior.
  static const bottomNavBarHeight = SizedBox(height: 140);
}
