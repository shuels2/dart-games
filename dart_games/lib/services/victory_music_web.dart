// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:indexed_db' as idb;

const String _dbName = 'DartGamesDB';
const String _storeName = 'victoryMusic';
const int _dbVersion = 1;

Future<idb.Database> _openDatabase() async {
  return await html.window.indexedDB!.open(
    _dbName,
    version: _dbVersion,
    onUpgradeNeeded: (idb.VersionChangeEvent event) {
      final db = event.target.result as idb.Database;
      if (!db.objectStoreNames!.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    },
  );
}

/// Store music data URL in IndexedDB.
Future<void> storeMusic(String fileName, String dataUrl) async {
  final db = await _openDatabase();
  try {
    final transaction = db.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);
    await store.put({'name': fileName, 'dataUrl': dataUrl}, 'current');
    await transaction.completed;
  } finally {
    db.close();
  }
}

/// Load stored music from IndexedDB.
Future<Map<String, String>?> loadStoredMusic() async {
  try {
    final db = await _openDatabase();
    try {
      final transaction = db.transaction(_storeName, 'readonly');
      final store = transaction.objectStore(_storeName);
      final result = await store.getObject('current');
      if (result != null) {
        final map = result as Map;
        return {
          'name': map['name'] as String,
          'dataUrl': map['dataUrl'] as String,
        };
      }
      return null;
    } finally {
      db.close();
    }
  } catch (e) {
    print('Error loading stored music: $e');
    return null;
  }
}

/// Clear stored music from IndexedDB.
Future<void> clearStoredMusic() async {
  try {
    final db = await _openDatabase();
    try {
      final transaction = db.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);
      await store.delete('current');
      await transaction.completed;
    } finally {
      db.close();
    }
  } catch (e) {
    print('Error clearing stored music: $e');
  }
}
