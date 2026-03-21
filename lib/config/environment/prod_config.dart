import 'base_config.dart';

class ProdConfig implements BaseConfig {
  @override
  String get apiBaseUrl => 'https://api.example.com';

  @override
  AppEnvironment get environment => AppEnvironment.prod;
}
