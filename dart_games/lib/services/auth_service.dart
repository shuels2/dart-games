import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'scolia_api_service.dart';
import 'storage_service.dart';
import '../config/google_oauth_config.dart';

class AuthService {
  final ScoliaApiService _apiService = ScoliaApiService();
  final StorageService _storageService = StorageService();

  // Lazy initialization of GoogleSignIn to avoid errors when Client ID is not configured
  GoogleSignIn? _googleSignIn;
  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn == null) {
      if (GoogleOAuthConfig.webClientId != null) {
        _googleSignIn = GoogleSignIn(
          scopes: GoogleOAuthConfig.scopes,
          clientId: GoogleOAuthConfig.webClientId,
        );
      } else {
        _googleSignIn = GoogleSignIn(
          scopes: GoogleOAuthConfig.scopes,
        );
      }
    }
    return _googleSignIn!;
  }

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

  // Login with Google account
  // This opens Google OAuth flow and exchanges the token with Scolia
  Future<String?> loginWithGoogle() async {
    try {
      // Check if Google Sign-In is properly configured
      if (!GoogleOAuthConfig.isConfigured) {
        throw Exception(GoogleOAuthConfig.configurationMessage);
      }

      String? idToken;

      if (kIsWeb) {
        // On web, use Google Identity Services to get ID token
        print('Using Google Identity Services for web...');

        try {
          // Call the JavaScript helper to get ID token
          final promise = js_util.callMethod(
            js.context['googleSignInHelper'],
            'getIdToken',
            [GoogleOAuthConfig.webClientId],
          );

          idToken = await js_util.promiseToFuture<String>(promise);

          print('Got ID Token from Google Identity Services');
        } catch (e) {
          print('Error getting ID token from Google Identity Services: $e');
          throw Exception('Failed to sign in with Google: $e');
        }
      } else {
        // On mobile, use the google_sign_in package
        final googleSignIn = _getGoogleSignIn();

        // Try silent sign-in first (uses existing session if available)
        GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

        // If silent sign-in fails, show the account picker
        if (googleUser == null) {
          googleUser = await googleSignIn.signIn();
        }

        if (googleUser == null) {
          // User canceled the sign-in
          return null;
        }

        // Get Google authentication
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        idToken = googleAuth.idToken;

        print('Got ID Token from google_sign_in package');
      }

      if (idToken == null || idToken.isEmpty) {
        print('ERROR: ID Token is null or empty - cannot authenticate with Scolia');
        throw Exception('Failed to get Google ID token. This is required to authenticate with Scolia.');
      }

      print('ID Token received: ${idToken.substring(0, 50)}...');
      print('Exchanging Google ID token with Scolia API...');

      // Exchange the Google ID token with Scolia backend
      final loginData = await _apiService.loginWithGoogle(idToken);
      final token = loginData['bearerToken'] as String;

      print('Successfully received Scolia bearer token');

      // Save token to secure storage
      await _storageService.saveBearerToken(token);

      return token;
    } catch (e) {
      print('ERROR in loginWithGoogle: $e');
      // Sign out on error to allow retry
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      rethrow;
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
