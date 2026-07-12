/// CLI migrator: detect face landmarks for player avatars.
///
/// Usage:
///   dart run bin/migrate_face_landmarks.dart [--data-dir <path>] [--all]
///
/// Default data-dir is `data` (relative to CWD), matching server.dart.
///
/// Behaviour:
///   1. Opens the SQLite database and runs migrations to ensure V5 is applied.
///   2. Checks that Python + mediapipe are available; exits 1 if not.
///   3. Queries players that need processing:
///      - Default (incremental): WHERE face_landmarks IS NULL AND
///        photo_path IS NOT NULL — only processes avatars that don't
///        already have landmarks. Idempotent and cheap to re-run.
///      - With `--all` (or `-a`, or `--force`): WHERE photo_path IS NOT NULL
///        — reprocesses EVERY player with a custom avatar, overwriting
///        existing landmarks. Use when a better landmarker model has been
///        dropped in and you want to regenerate the whole dataset.
///   4. For each, runs the MediaPipe sidecar and updates face_landmarks.
///   5. Exits 0 even if individual detections failed (those rows stay
///      unchanged in `--all` mode, or stay null in default mode).
///
/// Sample output:
///   [1/3] player=abc-123  photo=alice.jpg  ... OK
///   [2/3] player=def-456  photo=bob.jpg    ... no face detected
///   [3/3] player=ghi-789  photo=carol.jpg  ... error: file not found
///   Done. 1 updated, 1 no-face, 1 error.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/database/database_helpers.dart';
import 'package:dart_games_server/services/face_landmarks_service.dart';

import 'dart:convert';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('data-dir', abbr: 'd', defaultsTo: 'data')
    ..addFlag(
      'all',
      abbr: 'a',
      negatable: false,
      help:
          'Reprocess EVERY player with a custom avatar, overwriting existing '
          'landmarks. Use when a better landmarker model has been dropped in.',
    )
    // Alias so `--force` works the same as `--all` (matches common CLI
    // conventions; users may reach for either name).
    ..addFlag('force', negatable: false, hide: true);

  final results = parser.parse(args);
  final dataDir = results['data-dir'] as String;
  final reprocessAll = (results['all'] as bool) || (results['force'] as bool);
  final dbPath = p.join(dataDir, 'dart_games.db');

  // Ensure data dir exists.
  Directory(dataDir).createSync(recursive: true);

  // Open DB — this runs all pending migrations (including V5).
  print('Opening database at $dbPath ...');
  final database = Database(dbPath);
  final db = database.rawDb;

  // Check Python + mediapipe are available.
  print('Checking Python / mediapipe availability ...');
  final available = await FaceLandmarksService.instance.isAvailable();
  if (!available) {
    stderr.writeln(
      '\nERROR: Python with mediapipe is not available.\n'
      'Install with: pip install mediapipe opencv-python Pillow\n'
      'Or set the DART_GAMES_PYTHON env var to the Python executable path.\n'
      'See: https://pypi.org/project/mediapipe/',
    );
    database.close();
    exit(1);
  }
  print('Python + mediapipe: OK\n');

  // Query players that need processing.
  // photo_path IS NOT NULL means a custom avatar was uploaded
  // (the V1 baseline leaves photo_path NULL for players with no avatar).
  // With --all/--force, also reprocesses rows that already have landmarks
  // (e.g. when a better landmarker model has been dropped in).
  final whereClause = reprocessAll
      ? 'WHERE photo_path IS NOT NULL'
      : 'WHERE face_landmarks IS NULL AND photo_path IS NOT NULL';
  final rows = db.select(
    'SELECT id, photo_path FROM players $whereClause;',
  );

  final total = rows.length;
  if (total == 0) {
    if (reprocessAll) {
      print('No players have an uploaded avatar. Nothing to do.');
    } else {
      print('No players need face-landmark detection. Nothing to do.');
    }
    database.close();
    exit(0);
  }

  if (reprocessAll) {
    print('Reprocess mode (--all): re-running detection on $total player(s) '
        'with custom avatars, overwriting existing landmarks.\n');
  } else {
    print('Found $total player(s) to process.\n');
  }

  var updated = 0;
  var noFace = 0;
  var errors = 0;

  for (var i = 0; i < total; i++) {
    final row = rowToMap(rows[i]);
    final playerId = row['id'] as String;
    final photoPath = row['photo_path'] as String;
    final photoFile = p.basename(photoPath);

    stdout.write('[${i + 1}/$total] player=$playerId  photo=$photoFile  ... ');

    if (!File(photoPath).existsSync()) {
      stdout.writeln('error: file not found at $photoPath');
      errors++;
      continue;
    }

    final landmarks = await FaceLandmarksService.instance
        .detectForImagePath(photoPath, timeout: const Duration(seconds: 30));

    if (landmarks == null) {
      // Could be no face detected or sidecar error — service already logged.
      stdout.writeln('no face detected');
      noFace++;
      continue;
    }

    // Persist the landmarks as JSON string.
    executeUpdate(
      db,
      'UPDATE players SET face_landmarks = ? WHERE id = ?;',
      [jsonEncode(landmarks), playerId],
    );
    stdout.writeln('OK');
    updated++;
  }

  print('\nDone. $updated updated, $noFace no-face, $errors error(s).');
  database.close();
  exit(0);
}
