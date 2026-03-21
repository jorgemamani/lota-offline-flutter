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

    try {
      switch (env) {
        case 'prod':
          await dotenv.load(fileName: '.env.prod');
        default:
          await dotenv.load(fileName: '.env.dev');
      }
    } catch (_) {
      // Archivo .env no encontrado — la app funciona igual en modo offline.
    }

    final envValue = dotenv.env['ENVIRONMENT'] ?? env;
    config = _buildConfig(envValue);
  }

  BaseConfig _buildConfig(String envValue) {
    return switch (envValue) {
      'prod' => ProdConfig(),
      _ => DevConfig(),
    };
  }
}
