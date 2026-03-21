import 'route_names.dart';

/// Lista de rutas accesibles sin autenticación.
///
/// **Preparado para v2**: usar en el `redirect` del `GoRouter` para
/// determinar si un usuario no autenticado puede acceder a una ruta.
/// En v1, toda la app es pública porque no hay autenticación.
const publicRoutes = [
  RouteNames.splash,
  RouteNames.home,
  RouteNames.bolillero,
  RouteNames.cartonSelect,
  RouteNames.gamePlay,
];
