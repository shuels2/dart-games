/// Configuration for the Dart Games backend API.
///
/// The server URL defaults to the same host as the web app on port 8080.
/// For production, configure via [ApiConfig.configure].
class ApiConfig {
  static const _defaultPort =
      String.fromEnvironment('SERVER_PORT', defaultValue: '8080');
  static String _baseUrl = 'http://localhost:$_defaultPort';

  /// The base URL for all API requests.
  static String get baseUrl => _baseUrl;

  /// Configure the API base URL.
  ///
  /// Call this once at app startup before any API calls.
  /// Example: `ApiConfig.configure('http://192.168.1.100:8080')`
  static void configure(String baseUrl) {
    // Remove trailing slash if present.
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  // ---------------------------------------------------------------------------
  // Test epoch (integration tests only)
  // ---------------------------------------------------------------------------

  /// Current test epoch, set by [SettingsHelpers.initializeSettings] after
  /// each POST /test/reset.  The server increments its own epoch counter on
  /// every reset and returns the new value.  All subsequent POST/PUT requests
  /// include this epoch via `X-Test-Epoch` so the server can reject stale
  /// writes from a prior test whose HTTP requests were still in-flight when
  /// the reset occurred.
  ///
  /// `null` in production (no header is sent, server accepts all writes).
  static int? _testEpoch;
  static int? get testEpoch => _testEpoch;
  static void setTestEpoch(int? epoch) => _testEpoch = epoch;

  /// Full URL for the given API path.
  ///
  /// Example: `ApiConfig.url('/api/v1/players')` → `http://localhost:8080/api/v1/players`
  static String url(String path) => '$_baseUrl$path';
}
