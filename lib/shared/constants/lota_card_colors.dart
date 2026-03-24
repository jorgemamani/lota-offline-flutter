import 'package:flutter/material.dart';

import 'app_colors.dart';

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
    primary: AppColors.blue600,
    onPrimary: Colors.white,
  );
  static const indigo = LotaCardColor(
    primary: AppColors.indigo600,
    onPrimary: Colors.white,
  );
  static const violet = LotaCardColor(
    primary: AppColors.violet600,
    onPrimary: Colors.white,
  );
  static const teal = LotaCardColor(
    primary: AppColors.cyan600,
    onPrimary: Colors.white,
  );
  static const emerald = LotaCardColor(
    primary: AppColors.emerald600,
    onPrimary: Colors.white,
  );
  static const rose = LotaCardColor(
    primary: AppColors.rose600,
    onPrimary: Colors.white,
  );
  static const amber = LotaCardColor(
    primary: AppColors.amber600,
    onPrimary: Colors.white,
  );
  static const slate = LotaCardColor(
    primary: AppColors.slate600,
    onPrimary: Colors.white,
  );

  /// Lista completa — se usa para asignar colores al azar a los cartones.
  static const all = [blue, indigo, violet, teal, emerald, rose, amber, slate];
}
