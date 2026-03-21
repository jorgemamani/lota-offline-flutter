import 'base_config.dart';

class DevConfig implements BaseConfig {
  @override
  String get apiBaseUrl => 'https://api.dev.example.com';

  @override
  AppEnvironment get environment => AppEnvironment.dev;
}
