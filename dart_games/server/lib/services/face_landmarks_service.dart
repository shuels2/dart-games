import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Thrown when no Python interpreter can be found.
class FaceLandmarksUnavailableException implements Exception {
  final String message;
  const FaceLandmarksUnavailableException(this.message);

  @override
  String toString() => 'FaceLandmarksUnavailableException: $message';
}

/// Detects MediaPipe face landmarks by spawning a Python sidecar process.
///
/// The sidecar script (`server/python/mediapipe_sidecar.py`) receives a
/// single JSON line on stdin and writes a single JSON line to stdout.
///
/// Usage:
/// ```dart
/// final landmarks = await FaceLandmarksService.instance
///     .detectForImagePath('/data/photos/player-123.jpg');
/// ```
///
/// All failures (Python unavailable, no face detected, timeout) return
/// null — they do NOT throw. Warnings are logged to stderr.
class FaceLandmarksService {
  FaceLandmarksService._();

  /// Singleton instance.
  static final FaceLandmarksService instance = FaceLandmarksService._();

  /// Cached Python command (resolved once on first call).
  String? _pythonCmd;

  /// Cached sidecar script path.
  String? _sidecarPath;

  /// Whether availability was already checked and failed (cached negative).
  bool? _availabilityResult;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Detects face landmarks in the image at [absoluteImagePath].
  ///
  /// Returns a [Map] matching the spec's `faceLandmarks` JSON shape on
  /// success, or `null` on any failure (Python unavailable, no face
  /// detected, sidecar error, timeout, parse error).
  ///
  /// Detection results in a fire-and-forget context are safe: the
  /// caller should use `unawaited()` and the endpoint will return before
  /// detection completes.
  Future<Map<String, dynamic>?> detectForImagePath(
    String absoluteImagePath, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final python = await _resolvePython();
    if (python == null) return null;

    final sidecar = _resolveSidecarPath();
    if (sidecar == null) {
      stderr.writeln(
        '[FaceLandmarksService] sidecar not found; skipping detection',
      );
      return null;
    }

    Process? process;
    try {
      process = await Process.start(
        python,
        [sidecar],
        runInShell: false,
      ).timeout(const Duration(seconds: 5));

      // Write the request and close stdin so the sidecar reads EOF.
      process.stdin.write(jsonEncode({'image_path': absoluteImagePath}));
      await process.stdin.close();

      // Read stdout / wait for exit within timeout.
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      final results = await Future.wait([
        stdoutFuture,
        stderrFuture,
        process.exitCode,
      ]).timeout(timeout);

      final output = results[0] as String;
      final errOut = results[1] as String;
      final exitCode = results[2] as int;

      if (errOut.isNotEmpty) {
        // MediaPipe logs non-fatal warnings to stderr — only print in debug.
        // Suppress routine TFLite/mediapipe startup noise.
        final lines = errOut.split('\n').where((l) =>
            l.isNotEmpty &&
            !l.contains('WARNING') &&
            !l.contains('I tensorflow') &&
            !l.contains('W tensorflow'));
        if (lines.isNotEmpty) {
          stderr.writeln('[FaceLandmarksService] sidecar stderr: $errOut');
        }
      }

      if (exitCode != 0) {
        stderr.writeln(
          '[FaceLandmarksService] sidecar exited $exitCode; '
          'output: ${output.trim()}',
        );
        return null;
      }

      final trimmed = output.trim();
      if (trimmed.isEmpty) {
        stderr.writeln('[FaceLandmarksService] sidecar produced no output');
        return null;
      }

      final decoded = jsonDecode(trimmed) as Map<String, dynamic>;

      if (decoded['error'] != null) {
        stderr.writeln(
          '[FaceLandmarksService] sidecar error: ${decoded['error']}',
        );
        return null;
      }

      if (decoded['detected'] == false) {
        // No face in image — not an error, just null landmarks.
        return null;
      }

      // Strip the 'detected' control field before returning.
      final landmarks = Map<String, dynamic>.from(decoded)..remove('detected');
      return landmarks;
    } on TimeoutException {
      stderr.writeln(
        '[FaceLandmarksService] sidecar timed out after ${timeout.inSeconds}s '
        'for $absoluteImagePath',
      );
      process?.kill();
      return null;
    } catch (e) {
      stderr.writeln('[FaceLandmarksService] unexpected error: $e');
      return null;
    }
  }

  /// Returns `true` if a Python interpreter with mediapipe is available.
  ///
  /// Caches the result — both positive and negative. Safe to call
  /// multiple times.
  Future<bool> isAvailable() async {
    if (_availabilityResult != null) return _availabilityResult!;

    final python = await _resolvePython();
    if (python == null) {
      _availabilityResult = false;
      return false;
    }

    try {
      final result = await Process.run(python, ['-c', 'import mediapipe'])
          .timeout(const Duration(seconds: 10));
      _availabilityResult = result.exitCode == 0;
      if (!_availabilityResult!) {
        stderr.writeln(
          '[FaceLandmarksService] mediapipe not importable: '
          '${result.stderr}',
        );
      }
    } on TimeoutException {
      stderr.writeln('[FaceLandmarksService] mediapipe import check timed out');
      _availabilityResult = false;
    } catch (e) {
      stderr.writeln(
        '[FaceLandmarksService] mediapipe import check failed: $e',
      );
      _availabilityResult = false;
    }

    return _availabilityResult!;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Resolves the Python command to use, trying candidates in order:
  ///
  /// 1. `DART_GAMES_PYTHON` env-var override
  /// 2. `py` launcher (Windows standard)
  /// 3. `python`
  /// 4. `python3`
  ///
  /// Caches the result. Returns null if none found (logs warning to stderr).
  Future<String?> _resolvePython() async {
    if (_pythonCmd != null) return _pythonCmd;

    // 1. Env-var override.
    final envOverride = Platform.environment['DART_GAMES_PYTHON'];
    if (envOverride != null && envOverride.isNotEmpty) {
      _pythonCmd = envOverride;
      return _pythonCmd;
    }

    // 2-4. Probe candidates.
    final candidates = ['py', 'python', 'python3'];
    for (final cmd in candidates) {
      if (await _canRun(cmd)) {
        _pythonCmd = cmd;
        return _pythonCmd;
      }
    }

    stderr.writeln(
      '[FaceLandmarksService] No Python interpreter found. '
      'Install Python 3.9+ and mediapipe, or set the '
      'DART_GAMES_PYTHON env var. '
      'See: https://pypi.org/project/mediapipe/',
    );
    return null;
  }

  /// Returns true if [cmd] is runnable (exits without ProcessException).
  Future<bool> _canRun(String cmd) async {
    try {
      final result = await Process.run(cmd, ['--version'])
          .timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Resolves the sidecar script path relative to the server's script URI.
  ///
  /// The server ships `python/mediapipe_sidecar.py` alongside the Dart
  /// source. At runtime `Platform.script` points to `bin/server.dart`
  /// (or compiled AOT), so we walk up one level to the server package
  /// root and then into `python/`.
  String? _resolveSidecarPath() {
    if (_sidecarPath != null) return _sidecarPath;

    // Platform.script is the URI of the currently-executing script.
    // For `dart run bin/server.dart` it ends with `.../bin/server.dart`.
    // Walk up to the package root (parent of `bin/`).
    final scriptDir = path.dirname(Platform.script.toFilePath());
    final packageRoot = path.dirname(scriptDir); // one level up from bin/
    final candidate = path.join(packageRoot, 'python', 'mediapipe_sidecar.py');

    if (File(candidate).existsSync()) {
      _sidecarPath = candidate;
      return _sidecarPath;
    }

    // Fallback: try relative to current working directory (dev usage).
    final cwdCandidate = path.join(
      Directory.current.path,
      'python',
      'mediapipe_sidecar.py',
    );
    if (File(cwdCandidate).existsSync()) {
      _sidecarPath = cwdCandidate;
      return _sidecarPath;
    }

    return null;
  }

  /// Resets all cached state (for testing only).
  // ignore: unused_element
  void resetForTesting() {
    _pythonCmd = null;
    _sidecarPath = null;
    _availabilityResult = null;
  }

  /// Injects a specific sidecar path (for testing only).
  // ignore: unused_element
  void overrideSidecarForTesting(String sidecarPath) {
    _sidecarPath = sidecarPath;
  }

  /// Injects a specific Python command (for testing only).
  // ignore: unused_element
  void overridePythonForTesting(String pythonCmd) {
    _pythonCmd = pythonCmd;
    // Also reset the availability cache so isAvailable() is re-checked.
    _availabilityResult = null;
  }
}
