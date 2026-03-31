import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'base_config.dart';
import 'dev_config.dart';
import 'prod_config.dart';

class Environment {
  Environment._();

  static final Environment instance = Environment._();

  late BaseConfig config;

  Future<void> init() async {
    const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

    // En web los .env se piden por HTTP → 404 en consola si el asset falla.
    // El entorno en release viene de --dart-define; DevConfig/ProdConfig tienen los datos.
    if (!kIsWeb) {
      try {
        switch (env) {
          case 'prod':
            await dotenv.load(fileName: '.env.prod');
          default:
            await dotenv.load(fileName: '.env.dev');
        }
      } catch (_) {
        // Asset .env ausente — la app sigue en modo offline.
      }
    }

    var envValue = env;
    if (!kIsWeb) {
      try {
        envValue = dotenv.env['ENVIRONMENT'] ?? env;
      } catch (_) {
        // Dotenv no inicializado: conserva el valor por dart-define.
      }
    }
    config = _buildConfig(envValue);
  }

  BaseConfig _buildConfig(String envValue) {
    return switch (envValue) {
      'prod' => ProdConfig(),
      _ => DevConfig(),
    };
  }
}
