/// Build-time settings, overridable with `--dart-define`, e.g.
/// `flutter run --dart-define=PCJ_API_BASE_URL=https://staging.example.com`.
abstract final class AppConfig {
  /// Base address of the PCJ REST API.
  static const String apiBaseUrl = String.fromEnvironment(
    'PCJ_API_BASE_URL',
    defaultValue: 'https://porscheclubjo.com',
  );

  /// Where Contact Support emails go.
  static const String supportEmail = String.fromEnvironment(
    'PCJ_SUPPORT_EMAIL',
    defaultValue: 'info@porscheclubjo.com',
  );
}
