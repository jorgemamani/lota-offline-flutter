import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/favorite_carton.dart';
import '../../domain/repositories/favorite_cartons_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────

class FavoritesState extends Equatable {
  const FavoritesState({
    this.items = const [],
    this.ids = const {},
    this.isLoading = false,
  });

  /// Lista completa de cartones favoritos.
  final List<FavoriteCarton> items;

  /// Conjunto de IDs para lookup O(1). Sincronizado con [items].
  final Set<String> ids;

  /// true mientras se carga la lista inicial desde storage.
  final bool isLoading;

  bool isFavorite(String contentId) => ids.contains(contentId);

  FavoritesState copyWith({
    List<FavoriteCarton>? items,
    Set<String>? ids,
    bool? isLoading,
  }) =>
      FavoritesState(
        items: items ?? this.items,
        ids: ids ?? this.ids,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [items, ids, isLoading];
}

// ── Cubit ─────────────────────────────────────────────────────────────────

/// Gestiona el estado de favoritos y actúa como único punto de entrada
/// para leer o modificar la lista persistida.
///
/// Responsabilidades:
///   • Cargar los favoritos desde el repositorio al inicializarse.
///   • Exponer [isFavorite] para que la UI decida qué ícono mostrar.
///   • Agregar/eliminar favoritos a través de [toggle].
///
/// NO conoce nada de SharedPreferences ni de serialización; eso es
/// responsabilidad de [IFavoriteCartonsRepository].
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._repository) : super(const FavoritesState()) {
    _load();
  }

  final IFavoriteCartonsRepository _repository;

  Future<void> _load() async {
    emit(state.copyWith(isLoading: true));
    final items = await _repository.getAll();
    emit(state.copyWith(
      items: items,
      ids: items.map((f) => f.id).toSet(),
      isLoading: false,
    ));
  }

  /// Alterna el estado de favorito de un cartón identificado por su grilla.
  ///
  /// Si ya es favorito lo elimina; si no lo es lo agrega.
  /// El [colorIndex] se usa sólo al agregar (para recordar el color visual).
  Future<void> toggle({
    required List<List<int>> grid,
    required int colorIndex,
  }) async {
    final contentId = FavoriteCarton.idFromGrid(grid);

    if (state.ids.contains(contentId)) {
      await _repository.remove(contentId);
      emit(state.copyWith(
        items: state.items.where((f) => f.id != contentId).toList(),
        ids: Set<String>.from(state.ids)..remove(contentId),
      ));
    } else {
      final fav = FavoriteCarton(
        id: contentId,
        grid: grid,
        colorIndex: colorIndex,
      );
      await _repository.add(fav);
      emit(state.copyWith(
        items: [fav, ...state.items],
        ids: Set<String>.from(state.ids)..add(contentId),
      ));
    }
  }
}
