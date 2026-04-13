import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/services/migration/migrations/migration_v1.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MigrationV1InitializeVersioning', () {
    late MigrationV1InitializeVersioning migration;

    setUp(() {
      migration = MigrationV1InitializeVersioning();
    });

    test('has version 1', () {
      expect(migration.version, 1);
    });

    test('has a description', () {
      expect(migration.description, isNotEmpty);
    });

    test('is a no-op — existing data is untouched', () async {
      SharedPreferences.setMockInitialValues({
        'players_roster': '[{"id":"p1","name":"Alice"}]',
        'setup_complete': true,
        'voice_enabled': true,
        'saved_games_carnival_derby': <String>['{"id":"save-1"}'],
      });

      final prefs = await SharedPreferences.getInstance();
      await migration.migrate(prefs);

      // All existing data should be exactly as it was
      expect(
        prefs.getString('players_roster'),
        '[{"id":"p1","name":"Alice"}]',
      );
      expect(prefs.getBool('setup_complete'), true);
      expect(prefs.getBool('voice_enabled'), true);
      expect(
        prefs.getStringList('saved_games_carnival_derby'),
        ['{"id":"save-1"}'],
      );
    });

    test('completes without error on empty prefs', () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      // Should not throw
      await migration.migrate(prefs);
    });
  });
}
