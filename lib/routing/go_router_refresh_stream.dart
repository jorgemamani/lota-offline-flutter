import 'dart:async';

import 'package:flutter/foundation.dart';

/// Convierte un [Stream] en un [ChangeNotifier] para que [GoRouter]
/// re-evalúe el redirect cada vez que el stream emita un nuevo valor.
///
/// **Preparado para v2**: cuando se agregue autenticación, usar con
/// `GoRouter(refreshListenable: GoRouterRefreshStream(authBloc.stream))`.
/// Por ahora no se instancia porque la app v1 es 100% offline y pública.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
