import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dependency_injection.dart';
import 'shared/constants/app_colors.dart';
import 'shared/constants/breakpoints.dart';
import 'shared/extensions/build_context_extensions.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/game/presentation/cubit/carton_display_scale_cubit.dart';
import 'features/game/presentation/cubit/favorites_cubit.dart';
import 'features/game/presentation/cubit/session_cubit.dart';
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

    // En web con pantalla ancha, centra la app en un frame de ancho fijo
    // para preservar la experiencia móvil (≈ 1/3 del ancho de escritorio).
    final frameWidth = context.isWeb ? Breakpoints.mobileFrame : null;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<GameBloc>()),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<FavoritesCubit>()),
        BlocProvider(create: (_) => sl<SessionCubit>()),
        BlocProvider(create: (_) => sl<CartonDisplayScaleCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final app = MaterialApp.router(
            title: 'Lota',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: themeMode,
            routerConfig: appRouter,
            scrollBehavior: _WebScrollBehavior(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('es')],
            locale: const Locale('es'),
          );

          if (frameWidth == null) return app;

          // Web: fondo con el color de la app, frame centrado
          return Container(
            color: _buildTheme(themeMode == ThemeMode.dark
                    ? Brightness.dark
                    : Brightness.light)
                .colorScheme
                .surface,
            alignment: Alignment.center,
            child: SizedBox(
              width: frameWidth,
              child: app,
            ),
          );
        },
      ),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
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

/// Habilita scroll con mouse (drag) en web además del scroll con rueda.
///
/// Por defecto Flutter web solo responde al scroll con rueda; esto agrega
/// soporte para arrastrar con el mouse igual que en un dispositivo táctil.
class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
