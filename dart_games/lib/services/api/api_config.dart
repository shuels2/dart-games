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
  // Database session (UI automation tests only)
  // ---------------------------------------------------------------------------

  /// Unique session ID set by each browser instance during UI tests.
  /// Sent via `X-DB-Session` header so the server routes requests to
  /// an isolated per-session database.  `null` in production (no header
  /// is sent, server uses the default database).
  static String? _dbSession;
  static String? get dbSession => _dbSession;
  static void setDbSession(String id) => _dbSession = id;

  /// Full URL for the given API path.
  ///
  /// Example: `ApiConfig.url('/api/v1/players')` → `http://localhost:8080/api/v1/players`
  static String url(String path) => '$_baseUrl$path';
}
