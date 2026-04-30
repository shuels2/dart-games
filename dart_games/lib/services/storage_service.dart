import 'api/api_client.dart';

/// Storage service for dartboard credentials and setup state.
///
/// Uses the backend API via [ApiClient] for persistent storage.
/// Can be used via constructor injection or the static [initialize]/[instance] pattern.
class StorageService {
  final ApiClient _api;

  StorageService(this._api);

  // Static singleton for code that creates without constructor injection.
  static StorageService? _instance;

  /// Initialize the static singleton. Call once at app startup.
  static void initialize(ApiClient client) {
    _instance = StorageService(client);
  }

  /// Get the static singleton instance.
  static StorageService get instance {
    if (_instance == null) {
      throw StateError(
          'StorageService not initialized. Call StorageService.initialize() first.');
    }
    return _instance!;
  }

  /// For testing: allow setting the singleton directly.
  static set testInstance(StorageService? service) => _instance = service;

  // Save bearer token (Scolia dartboard API token)
  Future<void> saveBearerToken(String token) async {
    await _api.putSetting('bearer_token', token);
  }

  // Get bearer token
  Future<String?> getBearerToken() async {
    return await _api.getSetting('bearer_token');
  }

  // Save serial number
  Future<void> saveSerialNumber(String serialNumber) async {
    await _api.putSetting('serial_number', serialNumber);
  }

  // Get serial number
  Future<String?> getSerialNumber() async {
    return await _api.getSetting('serial_number');
  }

  // Mark setup as complete
  Future<void> setSetupComplete(bool complete) async {
    await _api.putSetting('setup_complete', complete.toString());
  }

  // Check if setup is complete (defaults to false if not set)
  Future<bool> isSetupComplete() async {
    final value = await _api.getSetting('setup_complete');
    if (value == null) return false;
    return value == 'true';
  }

  // Clear all stored data
  Future<void> clearAll() async {
    final settings = await _api.getSettings();
    for (final key in settings.keys) {
      await _api.deleteSetting(key);
    }
  }

  // Check if user has authentication credentials
  Future<bool> hasAuth() async {
    final token = await getBearerToken();
    return token != null && token.isNotEmpty;
  }

  // Check if user has dartboard registered
  Future<bool> hasDartboard() async {
    final serial = await getSerialNumber();
    return serial != null && serial.isNotEmpty;
  }
}
