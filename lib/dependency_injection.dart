import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'core/http_client/data/api_http_client_impl.dart';
import 'core/http_client/domain/http_client.dart';
import 'core/local_storage/data/local_storage_impl.dart';
import 'core/local_storage/domain/local_storage.dart';
import 'features/game/data/carton_manager.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/home/presentation/cubit/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Infraestructura HTTP (listo para v2 con backend) ──────────────
  sl.registerLazySingleton<Dio>(() => Dio());

  sl.registerLazySingleton<IHttpClient>(
    () => ApiHttpClient(httpClient: sl()),
  );

  // ── Storage (en memoria — v1 offline) ─────────────────────────────
  // Reemplazar InMemoryLocalStorage por una implementación con
  // flutter_secure_storage cuando se agregue autenticación en v2.
  sl.registerLazySingleton<ILocalStorage>(() => InMemoryLocalStorage());

  // ── Dominio del juego ──────────────────────────────────────────────
  sl.registerLazySingleton<CartonManager>(CartonManager.new);

  // ── BLoCs / Cubits ────────────────────────────────────────────────
  // Factory: cada llamada crea una instancia nueva.
  // LotaApp obtiene la instancia a través de BlocProvider(create: (_) => sl<GameBloc>()).
  sl.registerFactory<GameBloc>(GameBloc.new);

  // Singleton: el tema debe ser el mismo en toda la app.
  sl.registerLazySingleton<ThemeCubit>(ThemeCubit.new);
}
