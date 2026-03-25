import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/session_data.dart';
import '../../domain/repositories/session_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────

class SessionState extends Equatable {
  const SessionState({
    this.session,
    this.isLoading = true,
  });

  /// Sesión guardada, o null si no hay ninguna.
  final SessionData? session;

  /// true mientras se carga la sesión inicial desde storage.
  final bool isLoading;

  bool get hasSession => session != null;

  SessionState copyWith({
    SessionData? session,
    bool clearSession = false,
    bool? isLoading,
  }) =>
      SessionState(
        session: clearSession ? null : (session ?? this.session),
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [session, isLoading];
}

// ── Cubit ─────────────────────────────────────────────────────────────────

/// Gestiona la sesión de juego persistida.
///
/// - [save]: sobrescribe la sesión actual (llamado desde los pages al progresar).
/// - [clear]: elimina la sesión (llamado al salir de pantallas de juego).
///
/// El [SessionState.hasSession] controla si el Home muestra la tarjeta de
/// recuperación.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository) : super(const SessionState()) {
    _load();
  }

  final ISessionRepository _repository;

  Future<void> _load() async {
    final session = await _repository.load();
    emit(SessionState(session: session, isLoading: false));
  }

  Future<void> save(SessionData session) async {
    await _repository.save(session);
    emit(state.copyWith(session: session));
  }

  Future<void> clear() async {
    await _repository.clear();
    emit(state.copyWith(clearSession: true, isLoading: false));
  }
}
