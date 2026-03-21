import 'package:flutter/material.dart';

import 'app.dart';
import 'config/environment/environment.dart';
import 'dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Selecciona el entorno: flutter run --dart-define=ENVIRONMENT=dev
  await Environment.instance.init();

  // Registra dependencias con GetIt
  await configureDependencies();

  runApp(const LotaApp());
}
