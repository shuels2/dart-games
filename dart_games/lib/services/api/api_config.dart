/// Configuration for the Dart Games backend API.
///
/// The server URL defaults to the same host as the web app on port 8080
/// during local development. For production same-origin deployments,
/// build with `--dart-define=API_BASE_URL=` (empty value) and the
/// client will issue relative URLs (`/api/v1/...`) that the browser
/// resolves against `window.location.origin`. For split-origin
/// deployments, pass an absolute URL via
/// `--dart-define=API_BASE_URL=https://api.example.com`.
///
/// Runtime overrides are still supported via [ApiConfig.configure].
class ApiConfig {
  static const _defaultPort =
      String.fromEnvironment('SERVER_PORT', defaultValue: '8080');

  // bool.hasEnvironment distinguishes "dart-define passed (even with
  // empty value)" from "dart-define not passed at all", which
  // String.fromEnvironment alone cannot. Empty value is the
  // same-origin / relative-URL build mode.
  static const _hasBaseUrlOverride = bool.hasEnvironment('API_BASE_URL');
  static const _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String _baseUrl = _hasBaseUrlOverride
      ? _baseUrlOverride
      : 'http://localhost:$_defaultPort';

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
