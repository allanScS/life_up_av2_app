/// Configure a URL do Render após o deploy.
/// Em emulador Android, localhost do host = 10.0.2.2
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const Duration timeout = Duration(seconds: 8);
}
