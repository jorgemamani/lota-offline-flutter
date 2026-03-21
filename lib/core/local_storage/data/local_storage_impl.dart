import '../domain/local_storage.dart';

/// Implementación en memoria del storage.
///
/// Versión 1 — app completamente offline, no hay sesión que persistir.
/// Cuando se necesite persistencia real (v2 con backend), reemplazar por
/// una implementación con flutter_secure_storage o shared_preferences.
class InMemoryLocalStorage implements ILocalStorage {
  final Map<String, String> _store = {};

  static const _keyUserToken = 'user_token';
  static const _keyRefreshToken = 'refresh_token';

  @override
  Future<void> setUserToken(String token) async => _store[_keyUserToken] = token;

  @override
  Future<String?> getUserToken() async => _store[_keyUserToken];

  @override
  Future<void> deleteUserToken() async => _store.remove(_keyUserToken);

  @override
  Future<void> setRefreshToken(String token) async => _store[_keyRefreshToken] = token;

  @override
  Future<String?> getRefreshToken() async => _store[_keyRefreshToken];

  @override
  Future<void> deleteRefreshToken() async => _store.remove(_keyRefreshToken);

  @override
  Future<void> clear() async => _store.clear();
}
