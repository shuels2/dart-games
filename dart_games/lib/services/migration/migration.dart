import 'package:shared_preferences/shared_preferences.dart';

/// Base class for all data migrations.
///
/// Each migration transforms stored data from version N-1 to version N.
/// Migrations run sequentially at app startup before any providers load data.
abstract class Migration {
  /// The schema version this migration produces. Must be sequential (1, 2, 3...).
  int get version;

  /// Human-readable description for logging.
  String get description;

  /// Execute the migration.
  ///
  /// Throw an exception to abort — the version will not be updated and
  /// the migration will be retried on next app launch.
  Future<void> migrate(SharedPreferences prefs);
}
