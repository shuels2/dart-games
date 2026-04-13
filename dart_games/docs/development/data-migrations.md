# Data Migrations

## Overview

Dart Games uses a schema versioning and migration system to safely evolve persisted data across app updates. When the app launches, the migration runner checks the stored schema version and executes any pending migrations before providers load data.

**Storage:** Player data, saved games, and settings are stored in SharedPreferences (localStorage on web). The migration system manages changes to this data.

**IndexedDB** (victory music) has its own native versioning via `onUpgradeNeeded` in `victory_music_web.dart` and is NOT managed by this migration system.

## Architecture

```
lib/services/migration/
  migration.dart              # Migration base class
  migration_runner.dart       # Orchestrator (runs at startup)
  migrations/
    migration_v1.dart         # Bootstrap: establishes versioning baseline
    migration_v2.dart         # (future)
```

### How It Works

1. `MigrationRunner.runMigrations()` is called in `main()` before `runApp()`
2. It reads the `schema_version` integer from SharedPreferences (absent = version 0)
3. **Fresh install** (no existing data keys): stamps the current version and skips all migrations
4. **Existing data**: runs pending migrations sequentially (v1 -> v2 -> v3...)
5. The version is written after **each** successful migration, not batched
6. If a migration fails, the chain stops and retries on next app launch

### Fresh Install Detection

The runner checks for known data keys (`players_roster`, `setup_complete`, `voice_enabled`, `serial_number`, `dartboard_name`, `google_tts_api_key`, and any `saved_games_*` keys). If none exist, it's a fresh install — no data to migrate.

## Adding a New Migration

Follow these steps when you need to make a breaking change to stored data (renaming keys, changing field types, restructuring JSON, etc.).

### Step 1: Create the Migration File

Create `lib/services/migration/migrations/migration_vN.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../migration.dart';

class MigrationV2RenamePlayersKey extends Migration {
  @override
  int get version => 2;

  @override
  String get description => 'Rename players_roster to players';

  @override
  Future<void> migrate(SharedPreferences prefs) async {
    final data = prefs.getString('players_roster');
    if (data != null) {
      await prefs.setString('players', data);
      await prefs.remove('players_roster');
    }
  }
}
```

### Step 2: Register the Migration

Add it to the `migrations` list in `migration_runner.dart`:

```dart
static final List<Migration> migrations = [
  MigrationV1InitializeVersioning(),
  MigrationV2RenamePlayersKey(),       // <-- add at the end
];
```

### Step 3: Write Tests

Create `test/services/migration_v2_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/services/migration/migrations/migration_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MigrationV2RenamePlayersKey', () {
    test('renames players_roster to players', () async {
      SharedPreferences.setMockInitialValues({
        'players_roster': '[{"id":"p1","name":"Alice"}]',
      });

      final prefs = await SharedPreferences.getInstance();
      final migration = MigrationV2RenamePlayersKey();
      await migration.migrate(prefs);

      expect(prefs.getString('players_roster'), isNull);
      expect(prefs.getString('players'), '[{"id":"p1","name":"Alice"}]');
    });

    test('handles missing key gracefully', () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final migration = MigrationV2RenamePlayersKey();
      await migration.migrate(prefs); // should not throw
    });
  });
}
```

### Step 4: Run Tests

```bash
flutter test
```

All existing tests plus the new migration tests must pass.

### Step 5: Update Test Counts

Update the test counts in `CLAUDE.md` and `docs/testing/test-overview.md`.

## Rules

1. **Versions must be sequential.** Version N runs after version N-1. Never skip numbers.
2. **Migrations must handle missing data.** A key might not exist for all users — always check before operating on it.
3. **There is no rollback.** Write migrations carefully. Test them. If a migration fails at runtime, it will retry on the next app launch.
4. **Don't modify existing migrations.** Once a migration has been deployed, it should never change. If it was wrong, fix it in a new migration.
5. **Keep migrations focused.** One migration per logical change. Don't bundle unrelated changes.
6. **Adding optional fields doesn't need a migration.** If your `fromJson()` uses `??` for the new field, you don't need a migration — the defensive coding handles it. Migrations are for breaking changes only.

## When You DO Need a Migration

- Renaming a SharedPreferences key
- Renaming a field inside stored JSON
- Changing a field's type (e.g., `int` to `String`)
- Removing a field that other code depends on being absent
- Restructuring nested JSON (e.g., flattening or nesting)
- Splitting one storage key into multiple keys

## When You DON'T Need a Migration

- Adding a new optional field with a default (use `??` in `fromJson()`)
- Adding a new SharedPreferences key (nothing to migrate)
- Changing app logic without changing stored data shapes
- UI-only changes

## Error Handling

If a migration throws an exception:
- The version is NOT updated (stays at the last successful version)
- The error is logged via `debugPrint`
- The app continues to start normally
- The failed migration will retry on next app launch

## Key Files

| File | Purpose |
|------|---------|
| `lib/services/migration/migration.dart` | `Migration` base class |
| `lib/services/migration/migration_runner.dart` | `MigrationRunner` — startup orchestrator |
| `lib/services/migration/migrations/` | Individual migration files |
| `lib/main.dart` | Calls `MigrationRunner.runMigrations()` |
| `test/services/migration_runner_test.dart` | Runner tests |
| `test/services/migration_v1_test.dart` | V1 bootstrap tests |
