/// Google OAuth Configuration
///
/// To enable Google Sign-In:
/// 1. Go to https://console.cloud.google.com
/// 2. Create a new project or select an existing one
/// 3. Enable the "Google Sign-In API"
/// 4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
/// 5. Choose "Web application"
/// 6. Add authorized JavaScript origins:
///    - http://localhost:8081 (for local development)
///    - Your production domain
/// 7. Copy the Client ID and paste it below
/// 8. Rebuild the app

class GoogleOAuthConfig {
  // IMPORTANT: Replace this with your actual Google Cloud Client ID
  // Leave as null if you haven't set up Google Cloud OAuth yet
  static const String? webClientId = '1088754986287-a263o8kbiko3te7cikeff2f9fgsd7qej.apps.googleusercontent.com';
  // Example: static const String? webClientId = '123456789-abcdefg.apps.googleusercontent.com';

  // Scopes requested from Google
  static const List<String> scopes = [
    'openid',
    'email',
    'profile',
  ];

  // Check if Google Sign-In is properly configured
  static bool get isConfigured => webClientId != null && webClientId!.isNotEmpty;

  // Get configuration error message
  static String get configurationMessage => isConfigured
      ? 'Google Sign-In is configured'
      : 'Google Sign-In requires setup. See lib/config/google_oauth_config.dart for instructions.';
}
