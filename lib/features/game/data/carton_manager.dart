import 'dart:math';

import '../domain/models/lota_card_model.dart';

/// Genera cartones completos de Lota Argentina (Bingo 90).
///
/// Un cartón completo tiene 9 filas × 9 columnas = 3 sub-cartones de 3×9.
/// Algoritmo portado fielmente desde el controlador original del proyecto,
/// manteniendo todas las reglas:
///
///   • Columna k → rango numérico [k*10+1 … (k+1)*10], col 8 → [80–90]
///   • 45 números por cartón (15 por sub-cartón)
///   • Cada fila tiene exactamente 5 números y 4 celdas vacías
///   • Cada columna aporta 4, 5 o 6 números al cartón completo, con reglas
///     específicas de distribución entre los 3 sub-cartones
///   • Dentro de un sub-cartón: 6 columnas con 2 números y 3 con 1 número
class CartonManager {
  CartonManager({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _idCounter = 0;

  /// Genera un cartón completo con id autoincrementado.
  LotaCardModel generateCard({String? id}) {
    _idCounter++;
    final cardId = id ?? 'carton-$_idCounter';
    final grid = _buildGrid(list: _generateNumbers());
    return LotaCardModel.fromGrid(id: cardId, grid: grid);
  }

  /// Genera [count] cartones únicos.
  List<LotaCardModel> generateCards(int count) =>
      List.generate(count, (_) => generateCard());

  // ── Generación de números ──────────────────────────────────────────

  /// Número aleatorio para la columna [index], respetando el rango de cada
  /// decena. Col 0 → 1-9, col 1 → 10-19, ..., col 8 → 80-90.
  int _randomForColumn(int index) {
    switch (index) {
      case 0:
        return _random.nextInt(9) + 1;
      case 1:
        return _random.nextInt(10) + 10;
      case 2:
        return _random.nextInt(10) + 20;
      case 3:
        return _random.nextInt(10) + 30;
      case 4:
        return _random.nextInt(10) + 40;
      case 5:
        return _random.nextInt(10) + 50;
      case 6:
        return _random.nextInt(10) + 60;
      case 7:
        return _random.nextInt(10) + 70;
      case 8:
        return _random.nextInt(11) + 80;
      default:
        return 0;
    }
  }

  /// Genera la lista plana de 45 números respetando la distribución por
  /// columnas:
  ///   Combinación 1: 1 col con 4 nums + 1 col con 6 nums + 7 cols con 5
  ///   Combinación 2: 2 cols con 4     + 2 cols con 6     + 5 cols con 5
  ///   Combinación 3: 3 cols con 4     + 3 cols con 6     + 3 cols con 5
  List<int> _generateNumbers() {
    int randomNumber;
    final result = <int>[];

    // Paso 1: 4 números únicos por columna (base)
    for (int col = 0; col < 9; col++) {
      final colNums = <int>[];
      for (int j = 0; j < 4; j++) {
        do {
          randomNumber = _randomForColumn(col);
        } while (colNums.contains(randomNumber));
        colNums.add(randomNumber);
        result.add(randomNumber);
      }
    }

    // Paso 2: elegir combinación (cuántas cols tendrán 4 / 6 en lugar de 5)
    final int pares;
    switch (_random.nextInt(3)) {
      case 0:
        pares = 2; // 1 col con 4, 1 col con 6
        break;
      case 1:
        pares = 4; // 2 cols con 4, 2 cols con 6
        break;
      default:
        pares = 6; // 3 cols con 4, 3 cols con 6
        break;
    }
    final halfPares = pares ~/ 2;

    // Índices seleccionados: primera mitad → quedarse con 4 (no agregar)
    //                        segunda mitad → tener 6 (agregar 2)
    final selected = <int>[];
    for (int i = 0; i < pares; i++) {
      do {
        randomNumber = _random.nextInt(9);
      } while (selected.contains(randomNumber));
      selected.add(randomNumber);
    }

    // Paso 3: agregar el 5to número a todas las columnas que no están en la
    // primera mitad de [selected] (estas se quedan con 4)
    for (int col = 0; col < 9; col++) {
      if (!selected.sublist(0, halfPares).contains(col)) {
        do {
          randomNumber = _randomForColumn(col);
        } while (result.contains(randomNumber));
        result.add(randomNumber);
      }
    }

    // Paso 4: agregar el 6to número a las columnas de la segunda mitad de
    // [selected]
    for (int i = 0; i < halfPares; i++) {
      do {
        randomNumber = _randomForColumn(selected[halfPares + i]);
      } while (result.contains(randomNumber));
      result.add(randomNumber);
    }

    return result;
  }

  // ── Construcción de la grilla 9×9 ─────────────────────────────────

  List<List<int>> _buildGrid({required List<int> list}) {
    // Grilla vacía (0 = vacío)
    final card = List.generate(9, (_) => List.filled(9, 0));

    // Agrupa números por columna según su rango
    final groups = List.generate(9, (_) => <int>[]);
    for (final n in list) {
      if (n >= 1 && n <= 9) groups[0].add(n);
      if (n >= 10 && n <= 19) groups[1].add(n);
      if (n >= 20 && n <= 29) groups[2].add(n);
      if (n >= 30 && n <= 39) groups[3].add(n);
      if (n >= 40 && n <= 49) groups[4].add(n);
      if (n >= 50 && n <= 59) groups[5].add(n);
      if (n >= 60 && n <= 69) groups[6].add(n);
      if (n >= 70 && n <= 79) groups[7].add(n);
      if (n >= 80 && n <= 90) groups[8].add(n);
    }

    // divisionByCardsGrid[subCarton][col] = cuántos números de esa columna van
    // a ese sub-cartón (1 o 2)
    late List<List<int>> division;
    bool valid;

    do {
      valid = true;
      division = List.generate(3, (_) => List.filled(9, 0));

      // Columnas con 6 números: 2 por cada sub-cartón
      int base6 = 0;
      for (int col = 0; col < 9; col++) {
        if (groups[col].length == 6) {
          division[0][col] = division[1][col] = division[2][col] = 2;
          base6++;
        }
      }

      // Columnas con 4 números: distribuir 2,1,1 al azar
      for (int col = 0; col < 9; col++) {
        if (groups[col].length == 4) {
          division[0][col] = division[1][col] = division[2][col] = 1;
          final filaExtra = _random.nextInt(3);
          division[filaExtra][col] = 2;
        }
      }

      // Columnas con 5 números: distribuir respetando 6 cols con 2 y 3 con 1
      // por cada sub-cartón
      for (int sub = 0; sub < 3; sub++) {
        int count2 = base6;
        int count1 = 0;

        for (int col = 0; col < 9; col++) {
          if (groups[col].length == 4) {
            if (division[sub][col] == 2) {
              count2++;
            } else {
              count1++;
            }
          }
        }

        for (int col = 0; col < 9; col++) {
          if (groups[col].length != 6 && groups[col].length != 4) {
            switch (sub) {
              case 0:
                int val = _random.nextBool() ? 2 : 1;
                if (val == 1) {
                  if (count1 < 3) {
                    count1++;
                  } else {
                    val = 2;
                    count2++;
                  }
                } else {
                  if (count2 < 6) {
                    count2++;
                  } else {
                    val = 1;
                    count1++;
                  }
                }
                division[sub][col] = val;
                break;

              case 1:
                int val2;
                if (division[0][col] == 1) {
                  val2 = 2;
                  if (count2 >= 6) {
                    valid = false;
                  }
                  count2++;
                } else {
                  val2 = _random.nextBool() ? 2 : 1;
                  if (val2 == 1) {
                    if (count1 < 3) {
                      count1++;
                    } else {
                      val2 = 2;
                      count2++;
                    }
                  } else {
                    if (count2 < 6) {
                      count2++;
                    } else {
                      val2 = 1;
                      count1++;
                    }
                  }
                }
                division[sub][col] = val2;
                break;

              case 2:
                division[sub][col] = groups[col].length -
                    (division[0][col] + division[1][col]);
                break;
            }
          }
        }
      }
    } while (!valid);

    // ── Asignar números pares (2 por col) en los sub-cartones ─────────
    for (int sub = 0; sub < 3; sub++) {
      final startRow = sub * 3;
      int paresAbajoCentro = 0, paresArribaCentro = 0, paresArribaAbajo = 0;

      for (int col = 0; col < 9; col++) {
        if (division[sub][col] == 2) {
          int variante = _random.nextInt(3);

          // Patrones: 0=AbajoCentro, 1=ArribaCentro, 2=ArribaAbajo
          // Restricción: en 6 cols, los 3 patrones aparecen como 2+2+2 o 3+2+1
          switch (variante) {
            case 0:
              variante = _resolveVariante(
                  variante, paresAbajoCentro, paresArribaCentro, paresArribaAbajo);
              break;
            case 1:
              variante = _resolveVariante(
                  variante, paresArribaCentro, paresAbajoCentro, paresArribaAbajo,
                  alt1: 0, alt2: 2);
              break;
            case 2:
              variante = _resolveVariante(
                  variante, paresArribaAbajo, paresAbajoCentro, paresArribaCentro,
                  alt1: 0, alt2: 1);
              break;
          }

          if (variante == 0) paresAbajoCentro++;
          if (variante == 1) paresArribaCentro++;
          if (variante == 2) paresArribaAbajo++;

          switch (variante) {
            case 0: // Centro + Abajo
              card[startRow + 1][col] = groups[col].removeAt(0);
              card[startRow + 2][col] = groups[col].removeAt(0);
              break;
            case 1: // Arriba + Centro
              card[startRow][col] = groups[col].removeAt(0);
              card[startRow + 1][col] = groups[col].removeAt(0);
              break;
            case 2: // Arriba + Abajo
              card[startRow][col] = groups[col].removeAt(0);
              card[startRow + 2][col] = groups[col].removeAt(0);
              break;
          }
        } else {
          // Rotar el número al final de la lista para asignarlo después
          groups[col].add(groups[col].removeAt(0));
        }
      }
    }

    // ── Asignar números solos (1 por col) ─────────────────────────────
    for (int sub = 0; sub < 3; sub++) {
      final startRow = sub * 3;
      final singleCols = <int>[];
      for (int col = 0; col < 9; col++) {
        if (division[sub][col] == 1) singleCols.add(col);
      }

      for (int row = startRow; row < startRow + 3; row++) {
        final nonZero = card[row].where((n) => n != 0).length;
        switch (nonZero) {
          case 5:
            break;
          case 4:
            final col = singleCols.removeAt(0);
            card[row][col] = groups[col].removeAt(0);
            break;
          case 3:
            final col1 = singleCols.removeAt(0);
            final col2 = singleCols.removeAt(0);
            card[row][col1] = groups[col1].removeAt(0);
            card[row][col2] = groups[col2].removeAt(0);
            break;
        }
      }
    }

    return card;
  }

  // ── Helper para resolver variante con restricciones de patrón ─────

  /// Selecciona la variante final respetando la restricción de que cada patrón
  /// aparece como máximo 3 veces entre las 6 columnas dobles de un sub-cartón.
  int _resolveVariante(
    int variante,
    int self,
    int other1,
    int other2, {
    int alt1 = 1,
    int alt2 = 2,
  }) {
    if (self < 2) return variante;

    if (other1 == 3 || other2 == 3) {
      return other1 == 3 ? alt2 : alt1;
    }

    if (self == 3) {
      if (other1 == 2) return alt2;
      if (other2 == 2) return alt1;
      return _random.nextBool() ? alt1 : alt2;
    }

    return variante;
  }
}
