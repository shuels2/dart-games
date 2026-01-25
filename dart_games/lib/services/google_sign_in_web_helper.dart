import 'dart:js' as js;
import 'dart:js_util' as js_util;

/// Helper class to get Google ID Token on web using Google Identity Services
class GoogleSignInWebHelper {
  /// Signs in with Google and returns the ID token (credential)
  /// This uses Google One Tap / Sign In with Google button which provides ID tokens
  static Future<String?> signInWithGoogle(String clientId) async {
    try {
      // Create a promise that resolves when user signs in
      final completer = js_util.promiseToFuture<String>(
        js_util.callMethod(
          js.context['googleSignInHelper']!,
          'getIdToken',
          [clientId],
        ),
      );

      return await completer;
    } catch (e) {
      print('Error in GoogleSignInWebHelper: $e');
      return null;
    }
  }
}
