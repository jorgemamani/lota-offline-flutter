import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/session_data.dart';
import '../../domain/repositories/session_repository.dart';

/// Implementación de [ISessionRepository] usando SharedPreferences.
///
/// La sesión se serializa como JSON bajo la clave [_key].
/// Al cargar, cualquier error de parseo devuelve null en lugar de lanzar.
class SessionRepositoryImpl implements ISessionRepository {
  static const _key = 'lota_session_v1';

  @override
  Future<SessionData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return SessionData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(SessionData session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
