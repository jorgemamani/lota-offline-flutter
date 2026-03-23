import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/favorite_carton.dart';
import '../../domain/repositories/favorite_cartons_repository.dart';

/// Implementación de [IFavoriteCartonsRepository] usando SharedPreferences.
///
/// Los favoritos se serializan como un array JSON bajo la clave [_key].
/// Cada elemento es un objeto con id, grid (9×9) y colorIndex.
///
/// SharedPreferences es adecuado aquí porque:
///   • La estructura es plana y no requiere queries relacionales.
///   • El volumen máximo es ~50 cartones × 81 enteros = muy pequeño.
///   • No hay concurrencia de escritura (operaciones atómicas por sesión).
class FavoriteCartonsRepositoryImpl implements IFavoriteCartonsRepository {
  static const _key = 'lota_favorites_v1';

  @override
  Future<List<FavoriteCarton>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FavoriteCarton.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> add(FavoriteCarton favorite) async {
    final all = await getAll();
    if (all.any((f) => f.id == favorite.id)) return;
    all.add(favorite);
    await _persist(all);
  }

  @override
  Future<void> remove(String id) async {
    final all = await getAll();
    all.removeWhere((f) => f.id == id);
    await _persist(all);
  }

  Future<void> _persist(List<FavoriteCarton> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((f) => f.toJson()).toList()),
    );
  }
}
