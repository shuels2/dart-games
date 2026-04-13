import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'migration.dart';
import 'migrations/migration_v1.dart';

/// Runs pending data migrations at app startup.
///
/// Call [runMigrations] once in main() before runApp(). The runner:
/// 1. Reads the stored schema version (absent = version 0)
/// 2. Detects fresh installs (no existing data) and skips migrations
/// 3. Runs pending migrations sequentially
/// 4. Writes the version after each successful migration
class MigrationRunner {
  static const String versionKey = 'schema_version';

  /// All registered migrations, in order. Add new migrations at the end.
  static final List<Migration> migrations = [
    MigrationV1InitializeVersioning(),
  ];

  /// The current schema version (highest migration version).
  static int get currentVersion =>
      migrations.isEmpty ? 0 : migrations.last.version;

  /// Run any pending migrations. Call once at app startup before
  /// providers load data.
  static Future<void> runMigrations() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(versionKey) ?? 0;

    if (storedVersion == currentVersion) {
      debugPrint('[Migration] Schema version $storedVersion is current.');
      return;
    }

    // Fresh install: no existing data, so stamp the current version
    // and skip all migrations — there's nothing to migrate.
    if (storedVersion == 0 && _isFreshInstall(prefs)) {
      debugPrint('[Migration] Fresh install detected. '
          'Setting schema version to $currentVersion.');
      await prefs.setInt(versionKey, currentVersion);
      return;
    }

    debugPrint('[Migration] Schema version $storedVersion -> $currentVersion. '
        'Running ${currentVersion - storedVersion} migration(s)...');

    for (final migration in migrations) {
      if (migration.version <= storedVersion) continue;

      try {
        debugPrint('[Migration] Running v${migration.version}: '
            '${migration.description}');
        await migration.migrate(prefs);
        await prefs.setInt(versionKey, migration.version);
        debugPrint('[Migration] v${migration.version} complete.');
      } catch (e) {
        debugPrint('[Migration] v${migration.version} FAILED: $e');
        debugPrint('[Migration] Stopping migration chain. '
            'Will retry on next app launch.');
        return;
      }
    }

    debugPrint('[Migration] All migrations complete. '
        'Schema version is now $currentVersion.');
  }

  /// Returns true if no known data keys exist in SharedPreferences,
  /// indicating a brand new install with no pre-existing data.
  static bool _isFreshInstall(SharedPreferences prefs) {
    final knownKeys = [
      'players_roster',
      'setup_complete',
      'voice_enabled',
      'serial_number',
      'dartboard_name',
      'google_tts_api_key',
    ];

    for (final key in knownKeys) {
      if (prefs.containsKey(key)) return false;
    }

    // Also check for any saved game keys
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('saved_games_')) return false;
    }

    return true;
  }
}
