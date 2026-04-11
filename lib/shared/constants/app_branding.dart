/// Nombre comercial y textos de marca unificados.
abstract final class AppBranding {
  AppBranding._();

  /// Título visible en UI (home, splash, about) y en [MaterialApp.title].
  static const displayTitle = 'Lota Pue - Bingo 90';

  /// Nombre corto (launcher, PWA `short_name`, espacios con poco ancho).
  static const shortName = 'Lota Pue';

  /// Descripción breve para manifest / meta (opcional).
  static const tagline =
      'Lota, loteria, bingo 90 estilo argentino.\nJuego offline (no requiere conexión a internet).';
}
