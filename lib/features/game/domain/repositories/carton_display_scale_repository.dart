/// Persistencia del paso de escala de visualización de cartones (0…n-1).
abstract interface class ICartonDisplayScaleRepository {
  /// Paso guardado o `0` si no hay valor.
  Future<int> load();

  Future<void> save(int step);
}
