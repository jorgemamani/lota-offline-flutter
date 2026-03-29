import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'config/environment/environment.dart';
import 'dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GitHub Pages sirve la app bajo /nombre-repo/; con path URLs el location no
  // coincide con rutas como "/" de go_router y la app falla al iniciar. Hash
  // (#/home) evita eso y además evita 404 al recargar subrutas sin 404.html.
  if (kIsWeb) {
    setUrlStrategy(const HashUrlStrategy());
  }

  // Selecciona el entorno: flutter run --dart-define=ENVIRONMENT=dev
  await Environment.instance.init();

  // Registra dependencias con GetIt
  await configureDependencies();

  runApp(const LotaApp());
}
