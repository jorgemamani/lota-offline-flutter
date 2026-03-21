import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lota_offline/features/game/domain/models/game_mode.dart';
import 'package:lota_offline/features/game/domain/models/game_result.dart';
import 'package:lota_offline/features/game/domain/models/lota_card_model.dart';
import 'package:lota_offline/features/game/presentation/bloc/game_bloc.dart';

// ── Helpers de test ────────────────────────────────────────────────────────────

/// Cartón de 9×9 con números conocidos para tests.
///
/// Sub-cartón 0 (filas 0-2): 1, 31, 61, 81, 12, 42, 72, 3, 23, 53, 83
/// Sub-cartón 1 (filas 3-5): 2, 32, 62, 82, 13, 43, 73, 4, 24, 54, 84
/// Sub-cartón 2 (filas 6-8): 5, 33, 63, 85, 14, 44, 74, 6, 25, 55, 86
LotaCardModel _makeTestCard({String id = 'test-1'}) {
  return LotaCardModel.fromGrid(
    id: id,
    grid: [
      // Sub-cartón 0
      [1, 0, 0, 31, 0, 0, 61, 0, 81],
      [0, 12, 0, 0, 42, 0, 0, 72, 0],
      [3, 0, 23, 0, 0, 53, 0, 0, 83],
      // Sub-cartón 1
      [2, 0, 0, 32, 0, 0, 62, 0, 82],
      [0, 13, 0, 0, 43, 0, 0, 73, 0],
      [4, 0, 24, 0, 0, 54, 0, 0, 84],
      // Sub-cartón 2
      [5, 0, 0, 33, 0, 0, 63, 0, 85],
      [0, 14, 0, 0, 44, 0, 0, 74, 0],
      [6, 0, 25, 0, 0, 55, 0, 0, 86],
    ],
  );
}

/// Crea un cartón con los números indicados ya marcados.
LotaCardModel _cardWithMarked(Set<int> numbers, {String id = 'test-1'}) {
  var model = _makeTestCard(id: id);
  for (final n in numbers) {
    final pos = model.positionOf(n);
    if (pos != null) model = model.copyWithToggled(pos.$1, pos.$2);
  }
  return model;
}

/// Todos los números del cartón de test (45).
final _allTestNumbers = _makeTestCard().allNumbers.toSet();

/// Estado GameInProgress con valores por defecto para tests.
GameInProgress _inProgressSeed({
  GameMode mode = GameMode.markOnly,
  List<LotaCardModel>? cartones,
}) {
  return GameInProgress(
    mode: mode,
    cartones: cartones ?? [_makeTestCard()],
    drawnNumbers: const [],
    availableNumbers: List.generate(90, (i) => i + 1),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('GameBloc', () {
    group('GameStarted', () {
      blocTest<GameBloc, GameState>(
        'emite GameInProgress con 90 números disponibles al iniciar',
        build: GameBloc.new,
        act: (bloc) => bloc.add(GameStarted(
          mode: GameMode.combined,
          cartones: [_makeTestCard()],
        )),
        expect: () => [
          isA<GameInProgress>()
              .having((s) => s.availableNumbers.length, 'availableNumbers', 90)
              .having((s) => s.drawnNumbers.isEmpty, 'drawnNumbers empty', true)
              .having((s) => s.round, 'round', 0),
        ],
      );

      blocTest<GameBloc, GameState>(
        'inicializa cartones sin marcados',
        build: GameBloc.new,
        act: (bloc) => bloc.add(GameStarted(
          mode: GameMode.markOnly,
          cartones: [
            _makeTestCard(id: 'c1'),
            _makeTestCard(id: 'c2'),
          ],
        )),
        expect: () => [
          isA<GameInProgress>().having(
            (s) => s.cartones.map((c) => c.id).toSet(),
            'cartón ids',
            {'c1', 'c2'},
          ),
        ],
      );
    });

    group('RandomNumberDrawn', () {
      blocTest<GameBloc, GameState>(
        'reduce availableNumbers en 1 y aumenta drawnNumbers en 1',
        build: GameBloc.new,
        seed: () => GameInProgress(
          mode: GameMode.bolilleroOnly,
          cartones: const [],
          drawnNumbers: const [],
          availableNumbers: List.generate(90, (i) => i + 1),
        ),
        act: (bloc) => bloc.add(const RandomNumberDrawn()),
        expect: () => [
          isA<GameInProgress>()
              .having((s) => s.drawnNumbers.length, 'drawn count', 1)
              .having((s) => s.availableNumbers.length, 'available count', 89)
              .having((s) => s.round, 'round', 1),
        ],
      );
    });

    group('NumberToggled', () {
      blocTest<GameBloc, GameState>(
        'marca un número en el cartón correcto',
        build: GameBloc.new,
        seed: () => _inProgressSeed(),
        act: (bloc) => bloc.add(const NumberToggled(cartonId: 'test-1', number: 1)),
        expect: () => [
          isA<GameInProgress>().having(
            (s) => s.cartones.first.markedNumbersSet,
            'marked contains 1',
            contains(1),
          ),
        ],
      );

      blocTest<GameBloc, GameState>(
        'desmarca un número ya marcado',
        build: GameBloc.new,
        seed: () => _inProgressSeed(
          cartones: [_cardWithMarked({1, 3})],
        ),
        act: (bloc) => bloc.add(const NumberToggled(cartonId: 'test-1', number: 1)),
        expect: () => [
          isA<GameInProgress>().having(
            (s) => s.cartones.first.markedNumbersSet,
            'marked after untoggle',
            isNot(contains(1)),
          ),
        ],
      );
    });

    group('LotaPrizeClaimed', () {
      blocTest<GameBloc, GameState>(
        'emite GameOver cuando se reclama lota con cartón completo',
        build: GameBloc.new,
        seed: () => GameInProgress(
          mode: GameMode.combined,
          cartones: [_cardWithMarked(_allTestNumbers)],
          drawnNumbers: _allTestNumbers.toList(),
          availableNumbers: const [],
        ),
        act: (bloc) => bloc.add(const LotaPrizeClaimed('test-1')),
        expect: () => [
          isA<GameOver>().having(
            (s) => s.results
                .any((r) => r.cartonId == 'test-1' && r.prize == PrizeType.lota),
            'lota result present',
            true,
          ),
        ],
      );
    });

    group('LinePrizeClaimed', () {
      blocTest<GameBloc, GameState>(
        'agrega resultado de línea cuando la primera fila está completa',
        build: GameBloc.new,
        // Fila 0: [1, 0, 0, 31, 0, 0, 61, 0, 81] → 4 números
        seed: () => _inProgressSeed(
          cartones: [_cardWithMarked({1, 31, 61, 81})],
        ),
        act: (bloc) => bloc.add(const LinePrizeClaimed('test-1')),
        expect: () => [
          isA<GameInProgress>().having(
            (s) => s.results.any(
                (r) => r.cartonId == 'test-1' && r.prize == PrizeType.linea),
            'linea result present',
            true,
          ),
        ],
      );
    });

    group('GameReset', () {
      blocTest<GameBloc, GameState>(
        'vuelve a GameIdle',
        build: GameBloc.new,
        seed: () => _inProgressSeed(),
        act: (bloc) => bloc.add(const GameReset()),
        expect: () => [isA<GameIdle>()],
      );
    });
  });
}
