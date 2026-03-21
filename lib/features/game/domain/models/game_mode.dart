/// Los tres modos de juego disponibles desde el Home.
enum GameMode {
  /// Solo marcar cartones manualmente (sin bolillero automático).
  markOnly,

  /// Solo bolillero: muestra números al azar sin cartones.
  bolilleroOnly,

  /// Completo: selección de cartones + bolillero + marcado combinado.
  combined;

  String get label {
    return switch (this) {
      GameMode.markOnly => 'Marcar Cartón',
      GameMode.bolilleroOnly => 'Bolillero',
      GameMode.combined => 'Juego Completo',
    };
  }

  String get description {
    return switch (this) {
      GameMode.markOnly => 'Seleccioná tus cartones y marcalos a mano.',
      GameMode.bolilleroOnly => 'Sorteo de números. Ideal para ser el cantador.',
      GameMode.combined => 'Sorteo automático + marcado de cartones en un solo lugar.',
    };
  }
}
