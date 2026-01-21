import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  String? _bearerToken;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  String? get bearerToken => _bearerToken;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check authentication status on app startup
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _isAuthenticated = await _authService.isAuthenticated();
      if (_isAuthenticated) {
        _bearerToken = await _authService.getCurrentToken();
      }
    } catch (e) {
      _error = 'Failed to check authentication status: $e';
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set bearer token (from manual entry or OAuth callback)
  Future<bool> setToken(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.setToken(token);

      if (success) {
        _isAuthenticated = true;
        _bearerToken = token;
        _error = null;
      } else {
        _error = 'Invalid bearer token';
        _isAuthenticated = false;
      }

      return success;
    } catch (e) {
      _error = 'Failed to validate token: $e';
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with OAuth (future implementation)
  Future<bool> loginWithOAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.loginWithOAuth();

      if (token != null) {
        return await setToken(token);
      }

      _error = 'OAuth login failed';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isAuthenticated = false;
      _bearerToken = null;
      _error = null;
    } catch (e) {
      _error = 'Failed to logout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
