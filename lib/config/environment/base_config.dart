enum AppEnvironment { dev, prod }

abstract class BaseConfig {
  String get apiBaseUrl;
  AppEnvironment get environment;
}
