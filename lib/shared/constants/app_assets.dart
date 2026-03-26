/// Rutas de todos los assets estáticos de la app.
///
/// Usar siempre estas constantes en lugar de strings literales
/// para evitar errores tipográficos y facilitar refactors.
abstract final class AppAssets {
  AppAssets._();

  // ── Logo ────────────────────────────────────────────────────────────────────
  static const lotaLogo = 'assets/images/logo/lota-logo.png';

  // ── Modos de juego (home) ───────────────────────────────────────────────────
  static const gameModeMarkCarton = 'assets/images/game_modes/mark_carton_mode.png';
  static const gameModeBolillero = 'assets/images/game_modes/bolillero_mode.png';
  static const gameModeCombined = 'assets/images/game_modes/combined_mode.png';
}
