import '../models/favorite_carton.dart';

/// Contrato de persistencia para los cartones favoritos del usuario.
///
/// La capa de dominio sólo conoce esta interfaz; no sabe nada de
/// SharedPreferences, SQLite ni ninguna otra tecnología de storage.
abstract interface class IFavoriteCartonsRepository {
  /// Devuelve todos los cartones guardados como favoritos.
  Future<List<FavoriteCarton>> getAll();

  /// Agrega [favorite] a la lista. Si ya existe un favorito con el mismo
  /// [FavoriteCarton.id], la operación no tiene efecto.
  Future<void> add(FavoriteCarton favorite);

  /// Elimina el favorito cuyo [FavoriteCarton.id] sea [id].
  /// Si no existe, la operación no tiene efecto.
  Future<void> remove(String id);
}
