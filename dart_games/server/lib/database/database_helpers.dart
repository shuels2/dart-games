import 'package:sqlite3/sqlite3.dart';

/// Converts a sqlite3 [Row] into a plain [Map<String, dynamic>].
///
/// Iterates over the result set's column names and pulls each value
/// from the row by name, producing a map suitable for JSON encoding.
Map<String, dynamic> rowToMap(Row row) {
  final map = <String, dynamic>{};
  for (final column in row.keys) {
    map[column] = row[column];
  }
  return map;
}

/// Converts every [Row] in a [ResultSet] into a list of maps.
List<Map<String, dynamic>> resultSetToList(ResultSet resultSet) {
  return resultSet.map(rowToMap).toList();
}

/// Returns `true` if [table] contains at least one row matching the
/// given [where] clause and positional [args].
///
/// Example:
/// ```dart
/// final exists = rowExists(db, 'players', 'id = ?', ['player-123']);
/// ```
bool rowExists(
  Database db,
  String table,
  String where,
  List<Object?> args,
) {
  final result = db.select(
    'SELECT COUNT(*) AS cnt FROM $table WHERE $where;',
    args,
  );
  return (result.first['cnt'] as int) > 0;
}

/// Inserts a row and returns the last inserted row id.
int insertRow(
  Database db,
  String sql,
  List<Object?> args,
) {
  final stmt = db.prepare(sql);
  try {
    stmt.execute(args);
    return db.lastInsertRowId;
  } finally {
    stmt.dispose();
  }
}

/// Executes an update or delete statement and returns the number of
/// rows changed.
int executeUpdate(
  Database db,
  String sql,
  List<Object?> args,
) {
  final stmt = db.prepare(sql);
  try {
    stmt.execute(args);
    return db.updatedRows;
  } finally {
    stmt.dispose();
  }
}
