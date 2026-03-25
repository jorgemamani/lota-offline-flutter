import '../models/game_result.dart';
import '../models/lota_card_model.dart';

/// Detector de premios para un cartón de Lota Argentina.
///
/// Clase de utilidad pura: sin estado, sin dependencias externas.
/// Puede usarse en [GameBloc] durante la partida Y en el verificador
/// de QR para validar premios desde otro dispositivo, sin duplicar lógica.
///
/// ── Premios ───────────────────────────────────────────────────────────────
///
/// [PrizeType.cuaterno] — alguna fila tiene ≥ 4 números marcados.
/// [PrizeType.linea]    — alguna fila tiene sus 5 números marcados.
/// [PrizeType.lota]     — algún sub-cartón tiene sus 15 números marcados.
///
/// La detección es ACUMULATIVA: si hay línea (5 marcados), también hay
/// cuaterno (4 marcados). El [GameBloc] filtra los ya notificados para
/// evitar SnackBars duplicados.
abstract final class CartonPrizeDetector {
  /// Retorna todos los premios presentes en el estado actual del cartón.
  ///
  /// El orden importa: cuaterno → linea → lota.
  /// Al iterar y mostrar SnackBars (cada uno limpia el anterior),
  /// el de mayor jerarquía (lota) queda visible al final.
  static Set<PrizeType> detectAll(LotaCardModel carton) => {
        if (hasCuaterno(carton)) PrizeType.cuaterno,
        if (hasLinea(carton)) PrizeType.linea,
        if (hasLota(carton)) PrizeType.lota,
      };

  /// true si alguna fila tiene al menos 4 números marcados.
  static bool hasCuaterno(LotaCardModel carton) {
    for (int r = 0; r < 9; r++) {
      if (_markedInRow(carton, r) >= 4) return true;
    }
    return false;
  }

  /// true si alguna fila tiene sus 5 números marcados (fila completa).
  static bool hasLinea(LotaCardModel carton) => carton.hasAnyLinea;

  /// true si algún sub-cartón (filas 0-2, 3-5 o 6-8) tiene sus 15 marcados.
  static bool hasLota(LotaCardModel carton) =>
      carton.hasCartonLleno(0) ||
      carton.hasCartonLleno(1) ||
      carton.hasCartonLleno(2);

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _markedInRow(LotaCardModel carton, int row) {
    int count = 0;
    for (int c = 0; c < 9; c++) {
      if (carton.card[row][c] != 0 && carton.cardState[row][c]) count++;
    }
    return count;
  }
}
