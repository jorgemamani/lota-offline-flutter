import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dependency_injection.dart';
import 'shared/constants/app_branding.dart';
import 'shared/constants/app_colors.dart';
import 'shared/constants/breakpoints.dart';
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
            title: AppBranding.displayTitle,
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

          // En plataformas nativas no se necesita el frame centrado.
          if (!kIsWeb) return app;

          // Web: mantiene SIEMPRE la misma estructura de árbol
          // (Container → LayoutBuilder → SizedBox → app) para que
          // MaterialApp.router nunca se desmonte al cambiar el tamaño
          // del viewport (zoom / rotación), lo que causaba pantalla gris.
          // LayoutBuilder ajusta solo el ancho del SizedBox sin tocar app.
          final platformBrightness =
              MediaQuery.platformBrightnessOf(context);
          final effectiveBrightness = switch (themeMode) {
            ThemeMode.light => Brightness.light,
            ThemeMode.dark => Brightness.dark,
            ThemeMode.system => platformBrightness,
          };
          final surfaceColor =
              _buildTheme(effectiveBrightness).colorScheme.surface;

          return Container(
            color: surfaceColor,
            alignment: Alignment.center,
            child: LayoutBuilder(
              builder: (_, constraints) {
                final width = constraints.maxWidth > Breakpoints.mobileFrame
                    ? Breakpoints.mobileFrame
                    : constraints.maxWidth;
                return SizedBox(width: width, child: app);
              },
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
