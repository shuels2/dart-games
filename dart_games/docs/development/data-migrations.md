# Data Migrations

## Overview

Dart Games uses a server-side SQLite migration system to safely evolve the database schema across releases. When the server starts (or tests create a `Database` instance), the migration runner checks the stored schema version and executes any pending migrations before the server begins handling requests.

**Storage:** All data is stored in a SQLite database on the server. The migration system manages schema changes (adding tables, columns, indexes, etc.) to this database.

## Architecture

```
server/lib/database/
  database.dart              # Database class (calls MigrationRunner.run)
  migration.dart             # Migration base class + MigrationRunner
  migrations/
    migration_v1.dart        # Baseline schema (7 tables + defaults)
    migration_v2.dart        # Failed stats table for logging player stats update failures
```

### How It Works

1. `MigrationRunner.run(db)` is called in the `Database` constructor after configuring PRAGMAs
2. It creates the `schema_version` table if it does not exist
3. Reads the stored version (0 for fresh databases)
4. Runs each pending migration in its own transaction
5. Updates the version after each successful migration
6. If a migration throws, the transaction rolls back and the exception is rethrown

### Transaction Safety

Each migration runs inside its own `BEGIN`/`COMMIT` transaction. If the migration throws:
- All schema changes in that migration are rolled back
- The version remains at the last successful migration
- The exception propagates — the server will not start with a partially-migrated schema

SQLite supports transactional DDL (unlike many other databases), so `CREATE TABLE`, `ALTER TABLE`, etc. are all safely rolled back on failure.

## Current Migrations

### V1 — Baseline Schema (`MigrationV1Baseline`)
Creates the 7 core application tables: `settings`, `dartboard`, `dartboard_profiles`, `players`, `game_history`, `saved_games`, `victory_music`. Seeds a default dartboard row with `id=1`.

### V2 — Failed Stats Table (`MigrationV2FailedStats`)
Creates the `failed_stats` table for persistently logging player stats update failures. When `PlayerProvider.updatePlayerStats()` fails (e.g. player deleted mid-game, server 404, network error), the failure payload is POSTed to `/api/v1/stats/failed` and stored in this table for later investigation or replay.

**Columns:** `id` (PK), `player_id`, `player_name`, `game_name`, `won`, `duration_ms`, `dart_throws`, `turns`, `player_count`, `error_message`, `created_at`

**API endpoints** (mounted at `/api/v1/stats`):
- `GET /failed` — List all failed stats entries
- `POST /failed` — Log a new failure (requires `playerId` and `errorMessage`)
- `DELETE /failed` — Clear all entries
- `DELETE /failed/<id>` — Delete a single entry

## Adding a New Migration

Follow these steps when you need to change the database schema.

### Step 1: Create the Migration File

Create `server/lib/database/migrations/migration_vN.dart` (next version is V3):

```dart
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import '../migration.dart';

class MigrationV3AddPlayerEmail extends Migration {
  @override
  int get version => 3;

  @override
  String get description => 'Add email column to players';

  @override
  void migrate(sqlite3.Database db) {
    db.execute('ALTER TABLE players ADD COLUMN email TEXT;');
  }
}
```

### Step 2: Register the Migration

Add it to the `migrations` list in `migration.dart`:

```dart
import 'migrations/migration_v1.dart';
import 'migrations/migration_v2.dart';
import 'migrations/migration_v3.dart';

class MigrationRunner {
  static final List<Migration> migrations = [
    MigrationV1Baseline(),
    MigrationV2FailedStats(),
    MigrationV3AddPlayerEmail(),  // <-- add at the end
  ];
```

### Step 3: Write Tests

Add tests in `server/test/migration_test.dart`:

```dart
group('MigrationV3AddPlayerEmail', () {
  test('has version 3', () {
    expect(MigrationV3AddPlayerEmail().version, 3);
  });

  test('adds email column to players', () {
    // Run V1 + V2 first so the baseline schema exists.
    MigrationV1Baseline().migrate(db);
    MigrationV2FailedStats().migrate(db);

    // Run V3.
    MigrationV3AddPlayerEmail().migrate(db);

    // Verify the column exists.
    db.execute(
      "INSERT INTO players (id, name, created_at, email) "
      "VALUES ('p1', 'Alice', '2026-01-01', 'alice@example.com');",
    );
    final result = db.select('SELECT email FROM players WHERE id = ?;', ['p1']);
    expect(result.first['email'], 'alice@example.com');
  });
});
```

### Step 4: Run Tests

```bash
cd server && dart test
```

All existing tests plus the new migration tests must pass.

### Step 5: Update Test Counts

Update the test counts in `CLAUDE.md` and `docs/testing/test-overview.md`.

## Rules

1. **Versions must be sequential.** Version N runs after version N-1. Never skip numbers.
2. **Migrations must be idempotent where possible.** Use `IF NOT EXISTS`, `IF EXISTS`, etc.
3. **There is no rollback mechanism.** Write migrations carefully. Test them. If a migration fails at runtime, the transaction rolls back automatically, but the migration will block server startup until fixed.
4. **Don't modify existing migrations.** Once a migration has been deployed, it should never change. If it was wrong, fix it in a new migration.
5. **Keep migrations focused.** One migration per logical change. Don't bundle unrelated changes.
6. **Adding optional columns doesn't always need a migration.** If the column has a DEFAULT and existing code handles its absence, you may still want a migration to make the column queryable.

## When You DO Need a Migration

- Adding a new table
- Adding a column to an existing table
- Renaming a column or table
- Adding or removing an index
- Changing a column's type or constraints
- Restructuring data between tables

## When You DON'T Need a Migration

- Adding new API routes that use existing tables
- Changing application logic without changing the schema
- UI-only changes
- Adding new settings (the `settings` table is a key-value store)

## Error Handling

If a migration throws:
- The transaction is rolled back (schema changes are undone)
- The exception is rethrown
- The server will not start — this is intentional (a partially-migrated schema is worse than a failed startup)
- Fix the migration, rebuild, and restart

## Key Files

| File | Purpose |
|------|---------|
| `server/lib/database/migration.dart` | `Migration` base class + `MigrationRunner` |
| `server/lib/database/migrations/` | Individual migration files |
| `server/lib/database/database.dart` | Calls `MigrationRunner.run()` in constructor |
| `server/test/migration_test.dart` | Migration runner + individual migration tests |
