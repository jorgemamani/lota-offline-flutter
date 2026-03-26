/// Pasos de escala para el tamaño de números en los cartones (accesibilidad).
///
/// Se persiste el índice de paso (0…[stepCount]-1), no el multiplicador en bruto.
abstract final class CartonDisplayScale {
  CartonDisplayScale._();

  static const int stepCount = 4;

  /// Multiplicadores sobre las medidas base del cartón (celda y tipografía).
  static const List<double> multipliers = [1.0, 1.22, 1.44, 1.68];

  static double multiplierForStep(int step) {
    final i = step.clamp(0, stepCount - 1);
    return multipliers[i];
  }

  static String label(int step) {
    return switch (step.clamp(0, stepCount - 1)) {
      0 => 'Normal',
      1 => 'Mediano',
      2 => 'Grande',
      3 => 'Muy grande',
      _ => 'Normal',
    };
  }
}
