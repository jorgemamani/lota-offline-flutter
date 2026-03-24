import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dependency_injection.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/game/presentation/cubit/favorites_cubit.dart';
import 'features/home/presentation/cubit/theme_cubit.dart';
import 'routing/app_router.dart';
import 'shared/managers/alert_manager.dart';

class LotaApp extends StatelessWidget {
  const LotaApp({super.key});

  /// Clave global para [ScaffoldMessenger].
  ///
  /// Registrada en [AlertManager.setup] para que los métodos `show*` operen
  /// sin necesitar [BuildContext] en los call sites.
  static final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    // Inicializa el AlertManager una sola vez con las claves globales.
    // Es seguro llamarlo en build: las claves son las mismas instancias siempre.
    AlertManager.setup(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      navigatorKey: rootNavigatorKey,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<GameBloc>()),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<FavoritesCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Lota',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: themeMode,
            routerConfig: appRouter,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es'),
            ],
            locale: const Locale('es'),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
    );
  }
}
