import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/database/migrations/migration_v1.dart';
import 'package:dart_games_server/database/migrations/migration_v2.dart';
import 'package:dart_games_server/database/migrations/migration_v3.dart';
import 'package:dart_games_server/database/migrations/migration_v4.dart';
import 'package:dart_games_server/database/migrations/migration_v5.dart';

void main() {
  group('MigrationV5PlayerFaceLandmarks', () {
    late sqlite3.Database db;

    /// Runs V1-V4 baseline so V5 has the correct starting schema.
    void runBaseline() {
      MigrationV1Baseline().migrate(db);
      MigrationV2FailedStats().migrate(db);
      MigrationV3HotIndexes().migrate(db);
      MigrationV4AutoSaveFlag().migrate(db);
    }

    setUp(() {
      db = sqlite3.sqlite3.openInMemory();
      db.execute('PRAGMA foreign_keys = ON;');
      runBaseline();
    });

    tearDown(() {
      db.dispose();
    });

    test('has version 5', () {
      expect(MigrationV5PlayerFaceLandmarks().version, 5);
    });

    test('has a description', () {
      expect(MigrationV5PlayerFaceLandmarks().description, isNotEmpty);
    });

    test('adds face_landmarks column to players table', () {
      MigrationV5PlayerFaceLandmarks().migrate(db);

      final info = db.select("PRAGMA table_info('players');");
      final columnNames = info.map((row) => row['name'] as String).toList();
      expect(columnNames, contains('face_landmarks'));
    });

    test('face_landmarks column is nullable (no default value)', () {
      MigrationV5PlayerFaceLandmarks().migrate(db);

      // Insert a row without supplying face_landmarks — should default to NULL.
      db.execute(
        "INSERT INTO players (id, name, created_at) "
        "VALUES ('p1', 'Alice', '2026-01-01');",
      );

      final rows = db.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        ['p1'],
      );
      expect(rows.length, 1);
      expect(rows.first['face_landmarks'], isNull);
    });

    test('pre-existing rows read back with face_landmarks = null after migration', () {
      // Insert a player BEFORE running V5.
      db.execute(
        "INSERT INTO players (id, name, created_at) "
        "VALUES ('pre-exist', 'Bob', '2026-01-01');",
      );

      // Now apply V5.
      MigrationV5PlayerFaceLandmarks().migrate(db);

      final rows = db.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        ['pre-exist'],
      );
      expect(rows.length, 1);
      expect(rows.first['face_landmarks'], isNull);
    });

    test('face_landmarks column can store JSON text', () {
      MigrationV5PlayerFaceLandmarks().migrate(db);

      const json =
          '{"boundingBox":{"x":0.18,"y":0.12,"width":0.64,"height":0.72},'
          '"leftEye":{"x":0.34,"y":0.40},"rightEye":{"x":0.66,"y":0.40},'
          '"noseTip":{"x":0.50,"y":0.55},"mouthCenter":{"x":0.50,"y":0.72},'
          '"confidence":0.97}';

      db.execute(
        "INSERT INTO players (id, name, created_at, face_landmarks) "
        "VALUES ('p2', 'Carol', '2026-01-01', ?);",
        [json],
      );

      final rows = db.select(
        'SELECT face_landmarks FROM players WHERE id = ?;',
        ['p2'],
      );
      expect(rows.first['face_landmarks'], json);
    });

    test('running V5 a second time throws (already applied) — runner handles idempotency', () {
      // Apply V5 once.
      MigrationV5PlayerFaceLandmarks().migrate(db);

      // SQLite: ALTER TABLE ADD COLUMN on an existing column throws.
      expect(
        () => MigrationV5PlayerFaceLandmarks().migrate(db),
        throwsA(anything),
      );
    });
  });

  group('MigrationV5 via Database (integration)', () {
    test('schema version is 5 after full Database initialization', () {
      final database = Database(':memory:');
      final result =
          database.rawDb.select('SELECT version FROM schema_version;');
      expect(result.first['version'], 5);
      database.close();
    });

    test('players table has face_landmarks column after full initialization', () {
      final database = Database(':memory:');
      final info =
          database.rawDb.select("PRAGMA table_info('players');");
      final columnNames = info.map((row) => row['name'] as String).toList();
      expect(columnNames, contains('face_landmarks'));
      database.close();
    });
  });
}
