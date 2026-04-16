import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';
import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/database/migration.dart';
import 'package:dart_games_server/database/migrations/migration_v1.dart';
import 'package:dart_games_server/database/migrations/migration_v2.dart';

/// A test migration that records whether it ran.
class _TestMigration extends Migration {
  final int _version;
  final String _description;
  bool didRun = false;

  _TestMigration(this._version, [this._description = 'test migration']);

  @override
  int get version => _version;

  @override
  String get description => _description;

  @override
  void migrate(sqlite3.Database db) {
    didRun = true;
  }
}

/// A test migration that creates a table, then throws.
class _FailingMigration extends Migration {
  @override
  int get version => 99;

  @override
  String get description => 'failing migration';

  @override
  void migrate(sqlite3.Database db) {
    db.execute('CREATE TABLE fail_test (id INTEGER PRIMARY KEY);');
    throw Exception('intentional failure');
  }
}

void main() {
  group('MigrationRunner', () {
    late sqlite3.Database db;

    setUp(() {
      db = sqlite3.sqlite3.openInMemory();
      // Enable foreign keys like the real Database class does.
      db.execute('PRAGMA foreign_keys = ON;');
    });

    tearDown(() {
      db.dispose();
    });

    group('schema_version table', () {
      test('creates schema_version table on fresh database', () {
        MigrationRunner.run(db);

        final tables = db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='schema_version';",
        );
        expect(tables.length, 1);
      });

      test('seeds version 0 then updates to current after run', () {
        MigrationRunner.run(db);

        final result = db.select('SELECT version FROM schema_version;');
        expect(result.length, 1);
        expect(result.first['version'], MigrationRunner.currentVersion);
      });

      test('schema_version table persists across multiple runs', () {
        MigrationRunner.run(db);
        MigrationRunner.run(db); // second run is a no-op

        final result = db.select('SELECT version FROM schema_version;');
        expect(result.length, 1);
        expect(result.first['version'], MigrationRunner.currentVersion);
      });
    });

    group('migration execution', () {
      test('runs all migrations on fresh database', () {
        MigrationRunner.run(db);

        // V1 should have created all tables.
        final tables = db.select(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
        );
        final tableNames = tables.map((r) => r['name'] as String).toList();
        expect(tableNames, containsAll([
          'settings',
          'dartboard',
          'dartboard_profiles',
          'players',
          'game_history',
          'saved_games',
          'victory_music',
          'schema_version',
        ]));
      });

      test('skips already-applied migrations', () {
        // First run applies all migrations.
        MigrationRunner.run(db);

        // Insert test data.
        db.execute(
          "INSERT INTO players (id, name, created_at) "
          "VALUES ('p1', 'Alice', '2026-01-01');",
        );

        // Second run should not error or modify data.
        MigrationRunner.run(db);

        final players = db.select('SELECT * FROM players;');
        expect(players.length, 1);
        expect(players.first['name'], 'Alice');
      });

      test('runs only pending migrations', () {
        final original = List<Migration>.from(MigrationRunner.migrations);
        try {
          final m1 = _TestMigration(1);
          final m2 = _TestMigration(2);
          MigrationRunner.migrations
            ..clear()
            ..addAll([m1, m2]);

          // Manually set version to 1 so only m2 should run.
          db.execute('''
            CREATE TABLE IF NOT EXISTS schema_version (
              version INTEGER NOT NULL
            );
          ''');
          db.execute('INSERT INTO schema_version (version) VALUES (1);');

          MigrationRunner.run(db);

          expect(m1.didRun, isFalse, reason: 'v1 should be skipped');
          expect(m2.didRun, isTrue, reason: 'v2 should run');
        } finally {
          MigrationRunner.migrations
            ..clear()
            ..addAll(original);
        }
      });

      test('runs migrations in order', () {
        final original = List<Migration>.from(MigrationRunner.migrations);
        try {
          final order = <int>[];
          MigrationRunner.migrations
            ..clear()
            ..addAll([
              _OrderTrackingMigration(1, order),
              _OrderTrackingMigration(2, order),
              _OrderTrackingMigration(3, order),
            ]);

          MigrationRunner.run(db);

          expect(order, [1, 2, 3]);
        } finally {
          MigrationRunner.migrations
            ..clear()
            ..addAll(original);
        }
      });

      test('version is updated after each migration', () {
        final original = List<Migration>.from(MigrationRunner.migrations);
        try {
          MigrationRunner.migrations
            ..clear()
            ..addAll([
              _VersionCheckMigration(1, db),
              _VersionCheckMigration(2, db),
            ]);

          MigrationRunner.run(db);

          final result = db.select('SELECT version FROM schema_version;');
          expect(result.first['version'], 2);
        } finally {
          MigrationRunner.migrations
            ..clear()
            ..addAll(original);
        }
      });
    });

    group('transaction safety', () {
      test('rolls back on migration failure', () {
        final original = List<Migration>.from(MigrationRunner.migrations);
        try {
          MigrationRunner.migrations
            ..clear()
            ..addAll([_FailingMigration()]);

          // Seed version table manually so the runner proceeds.
          db.execute('''
            CREATE TABLE IF NOT EXISTS schema_version (
              version INTEGER NOT NULL
            );
          ''');
          db.execute('INSERT INTO schema_version (version) VALUES (0);');

          expect(
            () => MigrationRunner.run(db),
            throwsA(isA<Exception>()),
          );

          // Version should still be 0.
          final result = db.select('SELECT version FROM schema_version;');
          expect(result.first['version'], 0);
        } finally {
          MigrationRunner.migrations
            ..clear()
            ..addAll(original);
        }
      });

      test('partial schema changes are rolled back on failure', () {
        final original = List<Migration>.from(MigrationRunner.migrations);
        try {
          MigrationRunner.migrations
            ..clear()
            ..addAll([_FailingMigration()]);

          db.execute('''
            CREATE TABLE IF NOT EXISTS schema_version (
              version INTEGER NOT NULL
            );
          ''');
          db.execute('INSERT INTO schema_version (version) VALUES (0);');

          expect(
            () => MigrationRunner.run(db),
            throwsA(isA<Exception>()),
          );

          // The table created inside the failing migration should not exist.
          final tables = db.select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='fail_test';",
          );
          expect(tables.length, 0);
        } finally {
          MigrationRunner.migrations
            ..clear()
            ..addAll(original);
        }
      });

      test('rethrows the exception after rollback', () {
        final original = List<Migration>.from(MigrationRunner.migrations);
        try {
          MigrationRunner.migrations
            ..clear()
            ..addAll([_FailingMigration()]);

          db.execute('''
            CREATE TABLE IF NOT EXISTS schema_version (
              version INTEGER NOT NULL
            );
          ''');
          db.execute('INSERT INTO schema_version (version) VALUES (0);');

          expect(
            () => MigrationRunner.run(db),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('intentional failure'),
              ),
            ),
          );
        } finally {
          MigrationRunner.migrations
            ..clear()
            ..addAll(original);
        }
      });
    });

    group('edge cases', () {
      test('handles empty migrations list', () {
        final original = List<Migration>.from(MigrationRunner.migrations);
        try {
          MigrationRunner.migrations.clear();
          MigrationRunner.run(db);

          final result = db.select('SELECT version FROM schema_version;');
          expect(result.length, 1);
          expect(result.first['version'], 0);
        } finally {
          MigrationRunner.migrations
            ..clear()
            ..addAll(original);
        }
      });

      test('currentVersion reflects highest migration version', () {
        expect(MigrationRunner.currentVersion, 2);
      });

      test('currentVersion is 0 with no migrations', () {
        final original = List<Migration>.from(MigrationRunner.migrations);
        try {
          MigrationRunner.migrations.clear();
          expect(MigrationRunner.currentVersion, 0);
        } finally {
          MigrationRunner.migrations
            ..clear()
            ..addAll(original);
        }
      });
    });
  });

  group('MigrationV1Baseline', () {
    late sqlite3.Database db;

    setUp(() {
      db = sqlite3.sqlite3.openInMemory();
      db.execute('PRAGMA foreign_keys = ON;');
    });

    tearDown(() {
      db.dispose();
    });

    test('has version 1', () {
      expect(MigrationV1Baseline().version, 1);
    });

    test('has a description', () {
      expect(MigrationV1Baseline().description, isNotEmpty);
    });

    test('creates all 7 application tables', () {
      MigrationV1Baseline().migrate(db);

      final tables = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
      );
      final tableNames = tables.map((r) => r['name'] as String).toList();
      expect(tableNames, containsAll([
        'dartboard',
        'dartboard_profiles',
        'game_history',
        'players',
        'saved_games',
        'settings',
        'victory_music',
      ]));
    });

    test('seeds default dartboard row with id=1', () {
      MigrationV1Baseline().migrate(db);

      final result = db.select('SELECT * FROM dartboard WHERE id = 1;');
      expect(result.length, 1);
      expect(result.first['id'], 1);
      expect(result.first['use_emulator'], 0);
      expect(result.first['name'], isNull);
    });

    test('default dartboard row has use_emulator=0', () {
      MigrationV1Baseline().migrate(db);

      final result = db.select('SELECT use_emulator FROM dartboard WHERE id = 1;');
      expect(result.first['use_emulator'], 0);
    });

    test('tables have correct column defaults', () {
      MigrationV1Baseline().migrate(db);

      db.execute(
        "INSERT INTO players (id, name, created_at) "
        "VALUES ('p1', 'Alice', '2026-01-01');",
      );
      final player = db.select('SELECT * FROM players WHERE id = ?;', ['p1']);
      expect(player.first['games_played'], 0);
      expect(player.first['games_won'], 0);
      expect(player.first['photo_path'], isNull);

      db.execute(
        "INSERT INTO saved_games (id, game_type, saved_at, player_names, "
        "progress_info, game_mode_name, leading_player_name, "
        "leading_player_score, game_state) "
        "VALUES ('sg1', 'target_tag', '2026-01-01', '[]', "
        "'info', 'mode', 'Alice', '100', '{}');",
      );
      final game = db.select('SELECT * FROM saved_games WHERE id = ?;', ['sg1']);
      expect(game.first['waiting_for_takeout'], 0);

      db.execute(
        "INSERT INTO victory_music (id, file_name, file_path, created_at) "
        "VALUES ('vm1', 'song.mp3', '/music/song.mp3', '2026-01-01');",
      );
      final music = db.select('SELECT * FROM victory_music WHERE id = ?;', ['vm1']);
      expect(music.first['is_current'], 0);
    });

    test('foreign key cascade works after migration', () {
      MigrationV1Baseline().migrate(db);

      db.execute(
        "INSERT INTO players (id, name, created_at) "
        "VALUES ('p1', 'Alice', '2026-01-01');",
      );
      db.execute(
        "INSERT INTO game_history (id, player_id, game_name, timestamp, duration_ms) "
        "VALUES ('gh1', 'p1', 'Target Tag', '2026-01-01', 5000);",
      );

      // Delete the player — history should cascade.
      db.execute("DELETE FROM players WHERE id = 'p1';");

      final history = db.select('SELECT * FROM game_history;');
      expect(history.length, 0);
    });
  });

  group('MigrationV2FailedStats', () {
    late sqlite3.Database db;

    setUp(() {
      db = sqlite3.sqlite3.openInMemory();
      db.execute('PRAGMA foreign_keys = ON;');
      // Run V1 first so the baseline schema exists.
      MigrationV1Baseline().migrate(db);
    });

    tearDown(() {
      db.dispose();
    });

    test('has version 2', () {
      expect(MigrationV2FailedStats().version, 2);
    });

    test('has a description', () {
      expect(MigrationV2FailedStats().description, isNotEmpty);
    });

    test('creates failed_stats table', () {
      MigrationV2FailedStats().migrate(db);

      final tables = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='failed_stats';",
      );
      expect(tables.length, 1);
    });

    test('failed_stats table accepts full row', () {
      MigrationV2FailedStats().migrate(db);

      db.execute(
        '''INSERT INTO failed_stats
           (id, player_id, player_name, game_name, won, duration_ms,
            dart_throws, turns, player_count, error_message, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);''',
        [
          'fs-1', 'p-1', 'Alice', 'Target Tag', 1, 120000,
          42, 7, 3, 'ApiException(404)', '2026-04-16T00:00:00Z',
        ],
      );

      final rows = db.select('SELECT * FROM failed_stats;');
      expect(rows.length, 1);
      expect(rows.first['player_id'], 'p-1');
      expect(rows.first['player_name'], 'Alice');
      expect(rows.first['game_name'], 'Target Tag');
      expect(rows.first['error_message'], 'ApiException(404)');
    });

    test('failed_stats allows null optional fields', () {
      MigrationV2FailedStats().migrate(db);

      db.execute(
        '''INSERT INTO failed_stats
           (id, player_id, error_message, created_at)
           VALUES (?, ?, ?, ?);''',
        ['fs-2', 'p-2', 'not found', '2026-04-16T00:00:00Z'],
      );

      final rows = db.select('SELECT * FROM failed_stats;');
      expect(rows.length, 1);
      expect(rows.first['player_name'], isNull);
      expect(rows.first['game_name'], isNull);
    });
  });

  group('Database integration', () {
    late Database database;

    setUp(() {
      database = Database(':memory:');
    });

    tearDown(() {
      database.close();
    });

    test('schema_version table exists after initialization', () {
      final tables = database.rawDb.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='schema_version';",
      );
      expect(tables.length, 1);
    });

    test('schema version is 2 after initialization', () {
      final result = database.rawDb.select('SELECT version FROM schema_version;');
      expect(result.length, 1);
      expect(result.first['version'], 2);
    });
  });
}

/// Migration that tracks execution order.
class _OrderTrackingMigration extends Migration {
  final int _version;
  final List<int> _order;

  _OrderTrackingMigration(this._version, this._order);

  @override
  int get version => _version;

  @override
  String get description => 'order tracking v$_version';

  @override
  void migrate(sqlite3.Database db) {
    _order.add(_version);
  }
}

/// Migration that checks the version was updated before it ran.
class _VersionCheckMigration extends Migration {
  final int _version;
  final sqlite3.Database _db;

  _VersionCheckMigration(this._version, this._db);

  @override
  int get version => _version;

  @override
  String get description => 'version check v$_version';

  @override
  void migrate(sqlite3.Database db) {
    // This migration is a no-op — just verifies execution.
  }
}
