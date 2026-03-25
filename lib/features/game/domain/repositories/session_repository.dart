import '../models/session_data.dart';

/// Contrato de persistencia para la sesión de juego activa.
///
/// Permite guardar, cargar y borrar el estado de la partida en curso
/// para que el usuario pueda retomar si la app se cierra inesperadamente.
abstract interface class ISessionRepository {
  /// Carga la sesión guardada, o null si no hay ninguna.
  Future<SessionData?> load();

  /// Guarda (o sobreescribe) la sesión actual.
  Future<void> save(SessionData session);

  /// Elimina la sesión guardada.
  Future<void> clear();
}
