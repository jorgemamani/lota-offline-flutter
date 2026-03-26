import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'core/http_client/data/api_http_client_impl.dart';
import 'core/http_client/domain/http_client.dart';
import 'core/local_storage/data/local_storage_impl.dart';
import 'core/local_storage/domain/local_storage.dart';
import 'features/game/data/carton_manager.dart';
import 'features/game/data/repositories/carton_display_scale_repository_impl.dart';
import 'features/game/data/repositories/favorite_cartons_repository_impl.dart';
import 'features/game/data/repositories/session_repository_impl.dart';
import 'features/game/domain/repositories/carton_display_scale_repository.dart';
import 'features/game/domain/repositories/favorite_cartons_repository.dart';
import 'features/game/domain/repositories/session_repository.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/game/presentation/cubit/carton_display_scale_cubit.dart';
import 'features/game/presentation/cubit/favorites_cubit.dart';
import 'features/game/presentation/cubit/session_cubit.dart';
import 'features/home/data/repositories/theme_preferences_repository_impl.dart';
import 'features/home/domain/repositories/theme_preferences_repository.dart';
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

  // ── Favoritos ──────────────────────────────────────────────────────
  // El repositorio es singleton: una sola fuente de verdad para SharedPrefs.
  sl.registerLazySingleton<IFavoriteCartonsRepository>(
    () => FavoriteCartonsRepositoryImpl(),
  );

  // ── Sesión de juego ────────────────────────────────────────────────
  sl.registerLazySingleton<ISessionRepository>(
    () => SessionRepositoryImpl(),
  );

  // ── Preferencias de UI ─────────────────────────────────────────────
  final themePreferencesRepository = ThemePreferencesRepositoryImpl();
  sl.registerLazySingleton<IThemePreferencesRepository>(
    () => themePreferencesRepository,
  );
  final initialThemeMode = await themePreferencesRepository.load();

  // ── Escala de cartones (accesibilidad) ─────────────────────────────
  final cartonDisplayScaleRepository = CartonDisplayScaleRepositoryImpl();
  sl.registerLazySingleton<ICartonDisplayScaleRepository>(
    () => cartonDisplayScaleRepository,
  );
  final initialCartonDisplayStep = await cartonDisplayScaleRepository.load();

  // ── Dominio del juego ──────────────────────────────────────────────
  sl.registerLazySingleton<CartonManager>(CartonManager.new);

  // ── BLoCs / Cubits ────────────────────────────────────────────────
  // Factory: cada llamada crea una instancia nueva.
  sl.registerFactory<GameBloc>(GameBloc.new);

  // Singletons: estado global que vive toda la sesión.
  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(sl<IThemePreferencesRepository>(), initialThemeMode),
  );
  sl.registerLazySingleton<FavoritesCubit>(
    () => FavoritesCubit(sl<IFavoriteCartonsRepository>()),
  );
  sl.registerLazySingleton<SessionCubit>(
    () => SessionCubit(sl<ISessionRepository>()),
  );
  sl.registerLazySingleton<CartonDisplayScaleCubit>(
    () => CartonDisplayScaleCubit(
      sl<ICartonDisplayScaleRepository>(),
      initialCartonDisplayStep,
    ),
  );
}
