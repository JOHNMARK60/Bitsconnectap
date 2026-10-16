class ApiConfig {
  /// Mobile endpoints are served from `/api/mobile`; `/api/v1` is unsupported.
  static const baseUrl = 'https://bitsconnect.slsubc.tech/api/mobile/';

  static const appVersion = '2.0.0';
  static const buildNumber = '5';

  static const versionLabel = 'v$appVersion+$buildNumber';
}
