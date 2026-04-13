import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/services/migration/migration.dart';
import 'package:dart_games/services/migration/migration_runner.dart';

/// Test migration that records whether it was executed.
class TestMigration extends Migration {
  @override
  final int version;
  @override
  final String description;
  final Future<void> Function(SharedPreferences)? action;
  bool executed = false;

  TestMigration({
    required this.version,
    this.description = 'Test migration',
    this.action,
  });

  @override
  Future<void> migrate(SharedPreferences prefs) async {
    executed = true;
    if (action != null) await action!(prefs);
  }
}

/// Test migration that always throws.
class FailingMigration extends Migration {
  @override
  final int version;
  @override
  String get description => 'Failing migration';
  bool executed = false;

  FailingMigration({required this.version});

  @override
  Future<void> migrate(SharedPreferences prefs) async {
    executed = true;
    throw Exception('Migration failed intentionally');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset the migrations list before each test
    MigrationRunner.migrations.clear();
  });

  group('MigrationRunner', () {
    test('fresh install stamps current version without running migrations',
        () async {
      SharedPreferences.setMockInitialValues({});

      final v1 = TestMigration(version: 1, description: 'V1');
      final v2 = TestMigration(version: 2, description: 'V2');
      MigrationRunner.migrations.addAll([v1, v2]);

      await MigrationRunner.runMigrations();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(MigrationRunner.versionKey), 2);
      expect(v1.executed, false);
      expect(v2.executed, false);
    });

    test('pre-migration data (no schema_version) runs all migrations',
        () async {
      SharedPreferences.setMockInitialValues({
        'players_roster': '[]',
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      final v2 = TestMigration(version: 2, description: 'V2');
      MigrationRunner.migrations.addAll([v1, v2]);

      await MigrationRunner.runMigrations();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(MigrationRunner.versionKey), 2);
      expect(v1.executed, true);
      expect(v2.executed, true);
    });

    test('already at current version runs no migrations', () async {
      SharedPreferences.setMockInitialValues({
        'schema_version': 2,
        'players_roster': '[]',
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      final v2 = TestMigration(version: 2, description: 'V2');
      MigrationRunner.migrations.addAll([v1, v2]);

      await MigrationRunner.runMigrations();

      expect(v1.executed, false);
      expect(v2.executed, false);
    });

    test('partial upgrade runs only pending migrations', () async {
      SharedPreferences.setMockInitialValues({
        'schema_version': 1,
        'players_roster': '[]',
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      final v2 = TestMigration(version: 2, description: 'V2');
      final v3 = TestMigration(version: 3, description: 'V3');
      MigrationRunner.migrations.addAll([v1, v2, v3]);

      await MigrationRunner.runMigrations();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(MigrationRunner.versionKey), 3);
      expect(v1.executed, false);
      expect(v2.executed, true);
      expect(v3.executed, true);
    });

    test('version is written after each migration, not batched', () async {
      final versions = <int>[];

      SharedPreferences.setMockInitialValues({
        'players_roster': '[]',
      });

      final v1 = TestMigration(
        version: 1,
        description: 'V1',
        action: (prefs) async {
          versions.add(prefs.getInt(MigrationRunner.versionKey) ?? 0);
        },
      );
      final v2 = TestMigration(
        version: 2,
        description: 'V2',
        action: (prefs) async {
          // V1 should have been written by now
          versions.add(prefs.getInt(MigrationRunner.versionKey) ?? 0);
        },
      );
      MigrationRunner.migrations.addAll([v1, v2]);

      await MigrationRunner.runMigrations();

      // During v1, version was still 0 (not yet written)
      // During v2, version should be 1 (v1 was written after v1.migrate)
      expect(versions[0], 0);
      expect(versions[1], 1);
    });

    test('migration failure stops chain and preserves last good version',
        () async {
      SharedPreferences.setMockInitialValues({
        'players_roster': '[]',
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      final v2 = FailingMigration(version: 2);
      final v3 = TestMigration(version: 3, description: 'V3');
      MigrationRunner.migrations.addAll([v1, v2, v3]);

      await MigrationRunner.runMigrations();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(MigrationRunner.versionKey), 1);
      expect(v1.executed, true);
      expect(v2.executed, true);
      expect(v3.executed, false);
    });

    test('empty migrations list handles gracefully', () async {
      SharedPreferences.setMockInitialValues({});

      // migrations list is already cleared in setUp
      await MigrationRunner.runMigrations();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(MigrationRunner.versionKey), isNull);
    });

    test('currentVersion reflects highest migration version', () {
      MigrationRunner.migrations.addAll([
        TestMigration(version: 1),
        TestMigration(version: 2),
        TestMigration(version: 3),
      ]);
      expect(MigrationRunner.currentVersion, 3);
    });

    test('currentVersion is 0 with no migrations', () {
      expect(MigrationRunner.currentVersion, 0);
    });

    test('fresh install detected with completely empty prefs', () async {
      SharedPreferences.setMockInitialValues({});

      final v1 = TestMigration(version: 1, description: 'V1');
      MigrationRunner.migrations.add(v1);

      await MigrationRunner.runMigrations();

      expect(v1.executed, false);
    });

    test('existing setup_complete key triggers migration path', () async {
      SharedPreferences.setMockInitialValues({
        'setup_complete': true,
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      MigrationRunner.migrations.add(v1);

      await MigrationRunner.runMigrations();

      expect(v1.executed, true);
    });

    test('existing voice_enabled key triggers migration path', () async {
      SharedPreferences.setMockInitialValues({
        'voice_enabled': true,
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      MigrationRunner.migrations.add(v1);

      await MigrationRunner.runMigrations();

      expect(v1.executed, true);
    });

    test('existing saved_games_ key triggers migration path', () async {
      SharedPreferences.setMockInitialValues({
        'saved_games_carnival_derby': <String>['{}'],
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      MigrationRunner.migrations.add(v1);

      await MigrationRunner.runMigrations();

      expect(v1.executed, true);
    });

    test('migration can modify SharedPreferences data', () async {
      SharedPreferences.setMockInitialValues({
        'players_roster': '[]',
        'old_key': 'old_value',
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      final v2 = TestMigration(
        version: 2,
        description: 'Rename key',
        action: (prefs) async {
          final value = prefs.getString('old_key');
          if (value != null) {
            await prefs.setString('new_key', value);
            await prefs.remove('old_key');
          }
        },
      );
      MigrationRunner.migrations.addAll([v1, v2]);

      await MigrationRunner.runMigrations();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('old_key'), isNull);
      expect(prefs.getString('new_key'), 'old_value');
      expect(prefs.getInt(MigrationRunner.versionKey), 2);
    });

    test('failed migration retries on next run', () async {
      SharedPreferences.setMockInitialValues({
        'players_roster': '[]',
      });

      final v1 = TestMigration(version: 1, description: 'V1');
      final v2Fail = FailingMigration(version: 2);
      MigrationRunner.migrations.addAll([v1, v2Fail]);

      // First run: v1 succeeds, v2 fails
      await MigrationRunner.runMigrations();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(MigrationRunner.versionKey), 1);

      // Second run: simulate retry with a working v2
      MigrationRunner.migrations.clear();
      final v1b = TestMigration(version: 1, description: 'V1');
      final v2Success = TestMigration(version: 2, description: 'V2 fixed');
      MigrationRunner.migrations.addAll([v1b, v2Success]);

      await MigrationRunner.runMigrations();

      expect(prefs.getInt(MigrationRunner.versionKey), 2);
      expect(v1b.executed, false); // Already done
      expect(v2Success.executed, true);
    });
  });
}
