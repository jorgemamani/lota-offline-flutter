/// Los tres modos de juego disponibles desde el Home.
enum GameMode {
  /// Solo marcar cartones manualmente (sin bolillero automático).
  markOnly,

  /// Solo bolillero: muestra números al azar sin cartones.
  bolilleroOnly,

  /// Combinado: selección de cartones + bolillero + marcado de cartones automaticos.
  combined;

  String get label {
    return switch (this) {
      GameMode.markOnly => 'Marcar Cartones',
      GameMode.bolilleroOnly => 'Bolillero',
      GameMode.combined => 'Cartones + Bolillero',
    };
  }

  String get description {
    return switch (this) {
      GameMode.markOnly => 'Seleccioná tus cartones y marcalos a mano.',
      GameMode.bolilleroOnly =>
        'Sorteo de números. Ideal para ser el cantador.',
      GameMode.combined => 'Jugás con cartones y bolillero al mismo tiempo: '
          'cantás y los cartones se marcan solos.',
    };
  }
}
