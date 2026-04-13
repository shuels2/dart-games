import 'package:shared_preferences/shared_preferences.dart';
import '../migration.dart';

/// Bootstrap migration that establishes the versioning system.
///
/// For existing users (pre-migration data with no schema_version key),
/// this runs as a no-op — it simply stamps version 1 without modifying
/// any data, acknowledging the current data shape as the v1 baseline.
class MigrationV1InitializeVersioning extends Migration {
  @override
  int get version => 1;

  @override
  String get description => 'Initialize migration versioning system';

  @override
  Future<void> migrate(SharedPreferences prefs) async {
    // No data changes needed — this migration establishes the
    // versioning baseline for existing data.
  }
}
