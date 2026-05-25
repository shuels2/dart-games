/// Build-time identifiers injected via `--dart-define`.
///
/// Populated by the `build.bat` / `build.sh` wrapper scripts at the
/// repo root, which compute the build number from `git rev-list --count
/// HEAD` and pass it through to Flutter. Each commit on `main` (i.e.
/// each merged PR) increments the number automatically — no manual
/// bumping required.
///
/// When the app is launched without the wrapper (e.g. raw `flutter run`),
/// the constant falls back to `'dev'` so the missing flag isn't fatal.
class BuildInfo {
  /// Monotonic build number from `git rev-list --count HEAD`.
  /// Falls back to `'dev'` when the `--dart-define` flag isn't set.
  static const String number = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: 'dev',
  );
}
