import 'scolia_api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ScoliaApiService _apiService = ScoliaApiService();
  final StorageService _storageService = StorageService();

  // Validate a bearer token by calling the API
  Future<bool> validateToken(String token) async {
    try {
      return await _apiService.validateToken(token);
    } catch (e) {
      return false;
    }
  }

  // Set the bearer token after OAuth or manual entry
  Future<bool> setToken(String token) async {
    // Validate the token first
    final isValid = await validateToken(token);

    if (isValid) {
      // Save token to secure storage
      await _storageService.saveBearerToken(token);
      return true;
    }

    return false;
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getBearerToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    // Validate the stored token
    return await validateToken(token);
  }

  // Get current bearer token
  Future<String?> getCurrentToken() async {
    return await _storageService.getBearerToken();
  }

  // Logout - clear all stored credentials
  Future<void> logout() async {
    await _storageService.clearAll();
  }

  // Login with username and password
  Future<String?> loginWithCredentials(String username, String password) async {
    try {
      final loginData = await _apiService.login(username, password);
      final token = loginData['bearerToken'] as String;

      // Save token to secure storage
      await _storageService.saveBearerToken(token);

      return token;
    } catch (e) {
      return null;
    }
  }

  // OAuth login (placeholder for future implementation)
  // This would open a WebView or browser to Scolia's OAuth login page
  // and capture the bearer token from the callback
  Future<String?> loginWithOAuth() async {
    // TODO: Implement OAuth flow when Scolia provides OAuth endpoints
    // For now, this returns null to indicate manual token entry is needed
    throw UnimplementedError(
      'OAuth flow not yet implemented. Please use manual token entry.',
    );
  }
}
