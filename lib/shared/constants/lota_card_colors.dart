import 'package:flutter/material.dart';

/// Par de colores para un cartón: fondo del marco + color del texto encima.
@immutable
class LotaCardColor {
  const LotaCardColor({required this.primary, required this.onPrimary});

  final Color primary;
  final Color onPrimary;
}

/// Paleta de colores disponibles para los cartones de Lota.
///
/// Todos los tonos están calibrados para contrastar bien entre sí y
/// armonizar con el azul semilla de la app (`#2563EB`).
class LotaCardColors {
  LotaCardColors._();

  static const blue = LotaCardColor(
    primary: Color(0xFF2563EB),
    onPrimary: Colors.white,
  );

  static const indigo = LotaCardColor(
    primary: Color(0xFF4338CA),
    onPrimary: Colors.white,
  );

  static const violet = LotaCardColor(
    primary: Color(0xFF7C3AED),
    onPrimary: Colors.white,
  );

  static const teal = LotaCardColor(
    primary: Color(0xFF0891B2),
    onPrimary: Colors.white,
  );

  static const emerald = LotaCardColor(
    primary: Color(0xFF059669),
    onPrimary: Colors.white,
  );

  static const rose = LotaCardColor(
    primary: Color(0xFFE11D48),
    onPrimary: Colors.white,
  );

  static const amber = LotaCardColor(
    primary: Color(0xFFD97706),
    onPrimary: Colors.white,
  );

  static const slate = LotaCardColor(
    primary: Color(0xFF475569),
    onPrimary: Colors.white,
  );

  /// Lista completa — se usa para asignar colores al azar a los cartones.
  static const all = [blue, indigo, violet, teal, emerald, rose, amber, slate];
}
