import 'package:test/test.dart';
import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/database/database_helpers.dart';

void main() {
  group('Database', () {
    late Database db;

    setUp(() {
      db = Database(':memory:');
    });

    tearDown(() {
      db.close();
    });

    group('table creation', () {
      test('creates settings table', () {
        db.rawDb.execute(
          "INSERT INTO settings (key, value) VALUES ('theme', 'dark');",
        );
        final result = db.rawDb.select('SELECT * FROM settings;');
        expect(result.length, 1);
        expect(result.first['key'], 'theme');
        expect(result.first['value'], 'dark');
      });

      test('creates dartboard table', () {
        final result = db.rawDb.select('SELECT * FROM dartboard;');
        expect(result.length, 1);
        expect(result.first['id'], 1);
      });

      test('creates dartboard_profiles table', () {
        db.rawDb.execute(
          "INSERT INTO dartboard_profiles (serial_number, name, api_key, last_used) "
          "VALUES ('SN-001', 'My Board', 'key-123', '2026-01-01');",
        );
        final result = db.rawDb.select('SELECT * FROM dartboard_profiles;');
        expect(result.length, 1);
        expect(result.first['serial_number'], 'SN-001');
      });

      test('creates players table', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) "
          "VALUES ('p1', 'Alice', '2026-01-01');",
        );
        final result = db.rawDb.select('SELECT * FROM players;');
        expect(result.length, 1);
        expect(result.first['name'], 'Alice');
        expect(result.first['games_played'], 0);
        expect(result.first['games_won'], 0);
      });

      test('creates game_history table', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) "
          "VALUES ('p1', 'Alice', '2026-01-01');",
        );
        db.rawDb.execute(
          "INSERT INTO game_history (id, player_id, game_name, timestamp, duration_ms) "
          "VALUES ('gh1', 'p1', 'Target Tag', '2026-01-01', 5000);",
        );
        final result = db.rawDb.select('SELECT * FROM game_history;');
        expect(result.length, 1);
        expect(result.first['game_name'], 'Target Tag');
      });

      test('creates saved_games table', () {
        db.rawDb.execute(
          "INSERT INTO saved_games (id, game_type, saved_at, player_names, "
          "progress_info, game_mode_name, leading_player_name, "
          "leading_player_score, game_state) "
          "VALUES ('sg1', 'target_tag', '2026-01-01', '[\"Alice\"]', "
          "'Round 2/5', 'Classic', 'Alice', '100', '{\"round\":2}');",
        );
        final result = db.rawDb.select('SELECT * FROM saved_games;');
        expect(result.length, 1);
        expect(result.first['game_type'], 'target_tag');
        expect(result.first['waiting_for_takeout'], 0);
      });

      test('creates victory_music table', () {
        db.rawDb.execute(
          "INSERT INTO victory_music (id, file_name, file_path, created_at) "
          "VALUES ('vm1', 'song.mp3', '/music/song.mp3', '2026-01-01');",
        );
        final result = db.rawDb.select('SELECT * FROM victory_music;');
        expect(result.length, 1);
        expect(result.first['file_name'], 'song.mp3');
        expect(result.first['is_current'], 0);
      });
    });

    group('default seeding', () {
      test('seeds default dartboard row with id=1', () {
        final result =
            db.rawDb.select('SELECT * FROM dartboard WHERE id = 1;');
        expect(result.length, 1);
        expect(result.first['id'], 1);
        expect(result.first['use_emulator'], 0);
        expect(result.first['name'], isNull);
        expect(result.first['serial_number'], isNull);
        expect(result.first['api_key'], isNull);
      });
    });

    group('configuration', () {
      test('enables WAL mode (in-memory reports memory)', () {
        // WAL pragma is executed but in-memory databases always report
        // 'memory' as their journal mode since WAL requires a file.
        // This test verifies the pragma doesn't error and runs successfully.
        final result = db.rawDb.select('PRAGMA journal_mode;');
        expect(result.first['journal_mode'], 'memory');
      });

      test('enables foreign keys', () {
        final result = db.rawDb.select('PRAGMA foreign_keys;');
        expect(result.first['foreign_keys'], 1);
      });

      test('sets synchronous to NORMAL (1)', () {
        // PRAGMA synchronous returns 0=OFF, 1=NORMAL, 2=FULL, 3=EXTRA.
        // Pairing NORMAL with WAL is the recommended high-throughput setting.
        final result = db.rawDb.select('PRAGMA synchronous;');
        expect(result.first['synchronous'], 1);
      });
    });

    group('foreign key cascade', () {
      test('deleting a player cascades to game_history', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) "
          "VALUES ('p1', 'Alice', '2026-01-01');",
        );
        db.rawDb.execute(
          "INSERT INTO game_history (id, player_id, game_name, timestamp, duration_ms) "
          "VALUES ('gh1', 'p1', 'Target Tag', '2026-01-01', 5000);",
        );
        db.rawDb.execute(
          "INSERT INTO game_history (id, player_id, game_name, timestamp, duration_ms) "
          "VALUES ('gh2', 'p1', 'Carnival Derby', '2026-01-02', 3000);",
        );

        // Verify history exists before delete
        var history = db.rawDb.select('SELECT * FROM game_history;');
        expect(history.length, 2);

        // Delete the player
        db.rawDb.execute("DELETE FROM players WHERE id = 'p1';");

        // Verify history is cascaded
        history = db.rawDb.select('SELECT * FROM game_history;');
        expect(history.length, 0);
      });
    });

    group('close', () {
      test('close executes without error', () {
        final tempDb = Database(':memory:');
        expect(() => tempDb.close(), returnsNormally);
      });
    });

    group('multiple instances', () {
      test('can create multiple independent in-memory databases', () {
        final db2 = Database(':memory:');

        // Insert into db1
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) "
          "VALUES ('p1', 'Alice', '2026-01-01');",
        );

        // db2 should be empty
        final result = db2.rawDb.select('SELECT * FROM players;');
        expect(result.length, 0);

        // db1 should have the player
        final result1 = db.rawDb.select('SELECT * FROM players;');
        expect(result1.length, 1);

        db2.close();
      });
    });
  });

  group('Database helpers', () {
    late Database db;

    setUp(() {
      db = Database(':memory:');
    });

    tearDown(() {
      db.close();
    });

    group('rowToMap', () {
      test('converts a row to a map with correct keys and values', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, photo_path, created_at, games_played, games_won) "
          "VALUES ('p1', 'Alice', '/photos/alice.png', '2026-01-01', 10, 3);",
        );
        final result = db.rawDb.select('SELECT * FROM players WHERE id = ?;', ['p1']);
        final map = rowToMap(result.first);

        expect(map, isA<Map<String, dynamic>>());
        expect(map['id'], 'p1');
        expect(map['name'], 'Alice');
        expect(map['photo_path'], '/photos/alice.png');
        expect(map['created_at'], '2026-01-01');
        expect(map['games_played'], 10);
        expect(map['games_won'], 3);
      });

      test('handles null values', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) "
          "VALUES ('p1', 'Bob', '2026-01-01');",
        );
        final result = db.rawDb.select('SELECT * FROM players WHERE id = ?;', ['p1']);
        final map = rowToMap(result.first);

        expect(map['photo_path'], isNull);
      });
    });

    group('resultSetToList', () {
      test('converts result set to list of maps', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) VALUES ('p1', 'Alice', '2026-01-01');",
        );
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) VALUES ('p2', 'Bob', '2026-01-02');",
        );

        final result = db.rawDb.select('SELECT * FROM players ORDER BY id;');
        final list = resultSetToList(result);

        expect(list, isA<List<Map<String, dynamic>>>());
        expect(list.length, 2);
        expect(list[0]['id'], 'p1');
        expect(list[0]['name'], 'Alice');
        expect(list[1]['id'], 'p2');
        expect(list[1]['name'], 'Bob');
      });

      test('returns empty list for no results', () {
        final result = db.rawDb.select('SELECT * FROM players;');
        final list = resultSetToList(result);

        expect(list, isEmpty);
      });
    });

    group('rowExists', () {
      test('returns true when row exists', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) VALUES ('p1', 'Alice', '2026-01-01');",
        );

        final exists = rowExists(db.rawDb, 'players', 'id = ?', ['p1']);
        expect(exists, isTrue);
      });

      test('returns false when row does not exist', () {
        final exists = rowExists(db.rawDb, 'players', 'id = ?', ['nonexistent']);
        expect(exists, isFalse);
      });

      test('returns false after row is deleted', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) VALUES ('p1', 'Alice', '2026-01-01');",
        );
        db.rawDb.execute("DELETE FROM players WHERE id = 'p1';");

        final exists = rowExists(db.rawDb, 'players', 'id = ?', ['p1']);
        expect(exists, isFalse);
      });
    });

    group('insertRow', () {
      test('inserts a row and returns lastInsertRowId', () {
        // Using settings table which has an implicit ROWID
        final rowId = insertRow(
          db.rawDb,
          'INSERT INTO settings (key, value) VALUES (?, ?);',
          ['theme', 'dark'],
        );

        expect(rowId, greaterThan(0));

        final result = db.rawDb.select("SELECT * FROM settings WHERE key = 'theme';");
        expect(result.length, 1);
        expect(result.first['value'], 'dark');
      });

      test('returns incrementing ids for successive inserts', () {
        final id1 = insertRow(
          db.rawDb,
          'INSERT INTO settings (key, value) VALUES (?, ?);',
          ['key1', 'value1'],
        );
        final id2 = insertRow(
          db.rawDb,
          'INSERT INTO settings (key, value) VALUES (?, ?);',
          ['key2', 'value2'],
        );

        expect(id2, greaterThan(id1));
      });
    });

    group('executeUpdate', () {
      test('returns number of updated rows', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) VALUES ('p1', 'Alice', '2026-01-01');",
        );
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) VALUES ('p2', 'Bob', '2026-01-01');",
        );

        final updated = executeUpdate(
          db.rawDb,
          'UPDATE players SET games_played = ? WHERE id = ?;',
          [5, 'p1'],
        );

        expect(updated, 1);
      });

      test('returns 0 when no rows match', () {
        final updated = executeUpdate(
          db.rawDb,
          'UPDATE players SET games_played = ? WHERE id = ?;',
          [5, 'nonexistent'],
        );

        expect(updated, 0);
      });

      test('returns count of deleted rows', () {
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) VALUES ('p1', 'Alice', '2026-01-01');",
        );
        db.rawDb.execute(
          "INSERT INTO players (id, name, created_at) VALUES ('p2', 'Bob', '2026-01-01');",
        );

        final deleted = executeUpdate(
          db.rawDb,
          'DELETE FROM players WHERE created_at = ?;',
          ['2026-01-01'],
        );

        expect(deleted, 2);
      });
    });
  });
}
