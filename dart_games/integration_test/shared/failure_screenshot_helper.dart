import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Captures a PNG of the current screen when a UI test fails, so reviewers
/// can see what the app actually rendered at the moment of the assertion.
///
/// The driver (`test_driver/integration_test.dart`) routes the bytes to
/// `temp_screenshots/failures/<name>.png`. Filenames embed the test name and
/// a millisecond timestamp so parallel workers don't collide.
///
/// Usage — wrap the body of every UI test:
/// ```dart
/// testWidgets('foo', (tester) async {
///   await FailureScreenshotHelper.runWithFailureScreenshot(
///     tester,
///     'pirates_grid_save_resume_save_modal_save_button',
///     () async {
///       // existing test body
///     },
///   );
/// });
/// ```
///
/// The helper is no-op on success; the screenshot is taken only when the
/// inner closure throws. The original exception is always rethrown so the
/// test still fails normally.
class FailureScreenshotHelper {
  /// Runs `body` and, if it throws, captures a screenshot before rethrowing.
  ///
  /// `testName` is used as the screenshot filename prefix. Convention:
  /// `<game>_<subdir>_<test_file_basename>` (no `_test` suffix). For example
  /// `pirates_grid_save_resume_save_modal_save_button`.
  static Future<void> runWithFailureScreenshot(
    WidgetTester tester,
    String testName,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (e) {
      // Best-effort capture. Never let a screenshot failure mask the real test
      // failure — wrap in its own try/catch and swallow internal errors.
      try {
        final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeName = _sanitize(testName);
        final fullName = 'failures/${safeName}_$timestamp';
        await binding.takeScreenshot(fullName);
        // ignore: avoid_print
        print('[FAILURE_SCREENSHOT] saved as temp_screenshots/$fullName.png');
      } catch (sse) {
        // ignore: avoid_print
        print('[FAILURE_SCREENSHOT] capture failed: $sse');
      }
      rethrow;
    }
  }

  /// Strips characters that are invalid in filenames on Windows / macOS / Linux.
  /// Replaces them with underscores. Test names should already be safe but
  /// defensive sanitization keeps the helper robust.
  static String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
