import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/bolillero/presentation/pages/bolillero_page.dart';
import '../features/game/presentation/pages/carton_select_page.dart';
import '../features/game/presentation/pages/game_play_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'route_names.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RouteNames.splash,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      name: 'splash',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: RouteNames.home,
      name: 'home',
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      path: RouteNames.bolillero,
      name: 'bolillero',
      builder: (_, __) => const BolilleroPage(),
    ),
    GoRoute(
      path: RouteNames.cartonSelect,
      name: 'cartonSelect',
      builder: (context, state) {
        final args = state.extra as CartonSelectArgs;
        return CartonSelectPage(args: args);
      },
    ),
    GoRoute(
      path: RouteNames.gamePlay,
      name: 'gamePlay',
      builder: (context, state) {
        final args = state.extra as GamePlayArgs;
        return GamePlayPage(args: args);
      },
    ),
  ],
);
